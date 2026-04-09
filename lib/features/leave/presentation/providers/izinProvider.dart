import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/layananPenyimpanan.dart';
import '../../../../core/services/networkService.dart';
import '../../../../core/utils/attendance_utils.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../domain/entities/izin.dart';
import '../../domain/usecases/createIzinUsecase.dart';
import '../../domain/usecases/getIzinHistoryUsecase.dart';

class IzinProvider extends ChangeNotifier {
  final GetIzinHistoryUseCase _getHistoryUseCase;
  final CreateIzinUseCase _createIzinUseCase;
  final AuthRepository _authRepository;
  final StorageService _storageService;
  final NetworkService _networkService;

  IzinProvider({
    required GetIzinHistoryUseCase getHistoryUseCase,
    required CreateIzinUseCase createIzinUseCase,
    required AuthRepository authRepository,
    required StorageService storageService,
    required NetworkService networkService,
  }) : _getHistoryUseCase = getHistoryUseCase,
       _createIzinUseCase = createIzinUseCase,
       _authRepository = authRepository,
       _storageService = storageService,
       _networkService = networkService;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _submitError;
  List<Izin> _izinList = [];
  bool _lastSubmitQueued = false;

  static const String _pendingQueueKey = 'pending_izin_queue_v1';

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get submitError => _submitError;
  List<Izin> get izinList => _izinList;
  bool get lastSubmitQueued => _lastSubmitQueued;

  void clearSubmitError() {
    if (_submitError != null) {
      _submitError = null;
      notifyListeners();
    }
  }

  Future<void> getIzinHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _syncPendingQueue();

      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'error_session_expired';
        _isLoading = false;
        notifyListeners();
        return;
      }
      final historyList = await _getHistoryUseCase(token: token);
      _izinList = historyList
          .where((item) => item.type.trim().toLowerCase() == 'izin')
          .toList(growable: false);
      _mergePendingQueueIntoList();
      _sortByLatest();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _mergePendingQueueIntoList();
    } catch (_) {
      _errorMessage = 'error_load_leave_history';
      _mergePendingQueueIntoList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() => getIzinHistory();

  Future<bool> createIzin({
    required String date,
    required String type,
    required String reason,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    _lastSubmitQueued = false;
    notifyListeners();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _submitError = 'error_session_expired';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }
      await _createIzinUseCase(
        token: token,
        date: date,
        type: type,
        reason: reason,
      );
      _isSubmitting = false;
      notifyListeners();
      // Refresh history after successful submission
      final submittedDate = DateTime.tryParse(date) ?? DateTime.now();
      await getIzinHistory();
      _prependOptimisticIfMissing(
        type: type,
        date: submittedDate,
        reason: reason,
      );
      return true;
    } on ServerException catch (e) {
      if (_isRetryableNetworkError(e.message)) {
        await _enqueuePendingIzin(date: date, type: type, reason: reason);
        _lastSubmitQueued = true;
        _isSubmitting = false;
        _prependOptimisticIfMissing(
          type: type,
          date: DateTime.tryParse(date) ?? DateTime.now(),
          reason: reason,
        );
        _sortByLatest();
        notifyListeners();
        return true;
      }

      _submitError = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      final hasInternet = await _networkService.hasInternetConnection();
      if (!hasInternet) {
        await _enqueuePendingIzin(date: date, type: type, reason: reason);
        _lastSubmitQueued = true;
        _isSubmitting = false;
        _prependOptimisticIfMissing(
          type: type,
          date: DateTime.tryParse(date) ?? DateTime.now(),
          reason: reason,
        );
        _sortByLatest();
        notifyListeners();
        return true;
      }

      _submitError = 'error_submit_leave';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _syncPendingQueue() async {
    final hasInternet = await _networkService.hasInternetConnection();
    if (!hasInternet) {
      return;
    }

    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final queue = _readPendingQueue();
    if (queue.isEmpty) {
      return;
    }

    final remaining = <Map<String, dynamic>>[];

    for (final item in queue) {
      try {
        await _createIzinUseCase(
          token: token,
          date: item['date'] as String? ?? '',
          type: item['type'] as String? ?? 'izin',
          reason: item['reason'] as String? ?? '-',
        );
      } catch (_) {
        remaining.add(item);
      }
    }

    await _writePendingQueue(remaining);
  }

  Future<void> _enqueuePendingIzin({
    required String date,
    required String type,
    required String reason,
  }) async {
    final queue = _readPendingQueue();
    final candidate = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'date': date,
      'type': type,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    };

    final exists = queue.any((item) {
      return (item['date'] as String? ?? '') == date &&
          (item['type'] as String? ?? '').trim().toLowerCase() ==
              type.trim().toLowerCase() &&
          (item['reason'] as String? ?? '').trim().toLowerCase() ==
              reason.trim().toLowerCase();
    });

    if (!exists) {
      queue.add(candidate);
      await _writePendingQueue(queue);
    }
  }

  void _mergePendingQueueIntoList() {
    final queue = _readPendingQueue();
    if (queue.isEmpty) {
      return;
    }

    for (final item in queue) {
      final date = DateTime.tryParse(item['date'] as String? ?? '');
      if (date == null) {
        continue;
      }

      _prependOptimisticIfMissing(
        type: item['type'] as String? ?? 'izin',
        date: date,
        reason: item['reason'] as String? ?? '-',
      );
    }
  }

  Future<void> _writePendingQueue(List<Map<String, dynamic>> queue) async {
    final raw = queue.map(jsonEncode).toList(growable: false);
    await _storageService.saveStringList(_pendingQueueKey, raw);
  }

  List<Map<String, dynamic>> _readPendingQueue() {
    final raw = _storageService.getStringList(_pendingQueueKey);
    if (raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final queue = <Map<String, dynamic>>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          queue.add(decoded);
        }
      } catch (_) {
        // Ignore malformed queue item.
      }
    }

    return queue;
  }

  bool _isRetryableNetworkError(String message) {
    const retryable = {
      'error_network_unreachable',
      'error_request_timeout',
      'error_connection_lost',
      'error_server_unavailable',
    };
    return retryable.contains(message);
  }

  void _sortByLatest() {
    _izinList.sort((a, b) {
      final aTime = a.processedAt ?? a.date;
      final bTime = b.processedAt ?? b.date;
      return bTime.compareTo(aTime);
    });
  }

  void _prependOptimisticIfMissing({
    required String type,
    required DateTime date,
    required String reason,
  }) {
    final normalizedType = type.trim().toLowerCase();
    final normalizedReason = reason.trim().toLowerCase();

    final exists = _izinList.any((item) {
      return item.type.trim().toLowerCase() == normalizedType &&
          item.reason.trim().toLowerCase() == normalizedReason &&
          _isSameDate(item.date, date);
    });

    if (exists) {
      return;
    }

    final optimistic = Izin(
      type: _formatTypeLabel(type),
      date: date,
      reason: reason.trim(),
      status: StatusIzin.pending,
    );

    _izinList = [optimistic, ..._izinList];
    _sortByLatest();
    notifyListeners();
  }

  bool _isSameDate(DateTime a, DateTime b) => AttendanceUtils.isSameDate(a, b);

  String _formatTypeLabel(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Izin';
    }

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }
}
