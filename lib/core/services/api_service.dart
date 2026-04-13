import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../error/exceptions.dart';
import 'networkService.dart';

class ApiService {
  final NetworkService _networkService;
  late final http.Client _client;

  ApiService({required NetworkService networkService, http.Client? client})
      : _networkService = networkService,
        _client = client ?? http.Client();

  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const Duration _defaultRetryDelay = Duration(seconds: 2);
  static const int _defaultRetries = 3;

  DateTime? _lastConnectivityCheck;
  bool _lastConnectivityResult = false;

  Future<void> ensureInternetConnection() async {
    final now = DateTime.now();
    if (_lastConnectivityCheck != null && 
        now.difference(_lastConnectivityCheck!) < const Duration(seconds: 5)) {
      if (!_lastConnectivityResult) {
        throw const ServerException(
          message: 'error_network_unreachable',
          statusCode: 0,
        );
      }
      return;
    }

    final hasConnection = await _networkService.hasInternetConnection();
    _lastConnectivityCheck = now;
    _lastConnectivityResult = hasConnection;

    if (!hasConnection) {
      throw const ServerException(
        message: 'error_network_unreachable',
        statusCode: 0,
      );
    }
  }

  // ─── Core HTTP Methods ─────────────────────────────────────────────

  Future<Map<String, dynamic>> get(Uri uri, {Map<String, String>? headers}) async {
    final response = await send(
      request: () => _client.get(uri, headers: headers),
    );
    return _handleResponse(response);
  }

  Future<(Map<String, dynamic>, Map<String, String>)> getWithHeaders(Uri uri, {Map<String, String>? headers}) async {
    final response = await send(
      request: () => _client.get(uri, headers: headers),
    );
    return (_handleResponse(response), response.headers);
  }

  Future<Map<String, dynamic>> post(Uri uri, {Map<String, String>? headers, Object? body}) async {
    final response = await send(
      request: () => _client.post(uri, headers: headers, body: body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(Uri uri, {Map<String, String>? headers, Object? body}) async {
    final response = await send(
      request: () => _client.put(uri, headers: headers, body: body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers, Object? body}) async {
    final response = await send(
      request: () {
        if (body != null) {
          final request = http.Request('DELETE', uri);
          if (headers != null) request.headers.addAll(headers);
          request.body = body as String;
          return _client.send(request).then(http.Response.fromStream);
        } else {
          return _client.delete(uri, headers: headers);
        }
      },
      retryableStatusCodes: const {500, 502, 503, 504, 404, 405, 422},
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    
    // Centralized handler for delete errors
    _handleResponse(response);
    return response; 
  }

  // ─── Centralized Response Handling ─────────────────────────────────

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _safeDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw const UnauthorizedException();
    }

    if (response.statusCode == 422) {
      final decoded = _safeDecode(response.body);
      final errors = decoded['errors'] as Map<String, dynamic>?;
      final message = _extractValidationMessage(errors) ?? 
                      decoded['message'] as String? ?? 
                      'error_validation_failed';
      throw ValidationException(message: message, statusCode: 422);
    }

    if (response.statusCode >= 500) {
      throw ServerException(statusCode: response.statusCode);
    }

    if (response.statusCode >= 400) {
      throw ClientException(
        message: _extractErrorMessage(response.body),
        statusCode: response.statusCode,
      );
    }

    return _safeDecode(response.body);
  }

  Map<String, dynamic> _safeDecode(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _extractErrorMessage(String body) {
    final decoded = _safeDecode(body);
    if (decoded.containsKey('message') && decoded['message'] != null) {
      return decoded['message'].toString();
    }
    return 'unknown_error';
  }

  String? _extractValidationMessage(Map<String, dynamic>? errors) {
    if (errors == null) return null;
    final firstError = errors.values.first;
    if (firstError is List && firstError.isNotEmpty) {
      return firstError.first.toString();
    }
    return firstError.toString();
  }

  // ─── Interceptor / Retry Logic ─────────────────────────────────────

  Future<http.Response> send({
    required Future<http.Response> Function() request,
    bool requireInternet = true,
    int retries = _defaultRetries,
    Duration timeout = _defaultTimeout,
    Duration retryDelay = _defaultRetryDelay,
    Set<int> retryableStatusCodes = const {500, 502, 503, 504},
  }) async {
    if (requireInternet) {
      await ensureInternetConnection();
    }

    return retryRequest<http.Response>(
      () async {
        final response = await request().timeout(timeout);

        if (retryableStatusCodes.contains(response.statusCode)) {
          throw ServerException(
            message: 'error_server_unavailable',
            statusCode: response.statusCode,
          );
        }

        return response;
      },
      retries: retries,
      retryDelay: retryDelay,
      shouldRetry: (error) {
        if (error is ServerException) {
          return error.statusCode >= 500 || error.statusCode == 0;
        }

        return error is TimeoutException ||
            error is SocketException ||
            error is http.ClientException;
      },
      mapError: _mapToServerException,
      onRetry: (attempt, error) {
        debugPrint('ApiService retry $attempt/$retries: $error');
      },
    );
  }

  Future<T> retryRequest<T>(
    Future<T> Function() request, {
    int retries = _defaultRetries,
    Duration retryDelay = _defaultRetryDelay,
    bool Function(Object error)? shouldRetry,
    ServerException Function(Object error)? mapError,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= retries; attempt++) {
      try {
        return await request();
      } on Object catch (error) {
        lastError = error;
        final canRetry =
            attempt < retries && (shouldRetry == null || shouldRetry(error));

        if (!canRetry) {
          final mapper = mapError ?? _mapToServerException;
          final mapped = mapper(error);
          debugPrint('ApiService error: $mapped');
          throw mapped;
        }

        onRetry?.call(attempt, error);
        await Future.delayed(retryDelay);
      }
    }

    final mapper = mapError ?? _mapToServerException;
    final mapped = mapper(lastError ?? Exception('Unknown network error'));
    debugPrint('ApiService error: $mapped');
    throw mapped;
  }

  ServerException _mapToServerException(Object error) {
    if (error is ServerException) {
      return error;
    }

    if (error is TimeoutException) {
      return const ServerException(
        message: 'error_request_timeout',
        statusCode: 0,
      );
    }

    if (error is SocketException) {
      return const ServerException(
        message: 'error_network_unreachable',
        statusCode: 0,
      );
    }

    if (error is http.ClientException) {
      final message = error.message.toLowerCase();
      if (message.contains('socketexception') ||
          message.contains('failed host lookup') ||
          message.contains('network is unreachable')) {
        return const ServerException(
          message: 'error_network_unreachable',
          statusCode: 0,
        );
      }

      return const ServerException(
        message: 'error_connection_lost',
        statusCode: 0,
      );
    }

    return const ServerException(
      message: 'error_connection_lost',
      statusCode: 0,
    );
  }
}
