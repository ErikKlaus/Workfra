import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/apiKonstanta.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/api_service.dart';
import '../models/izinModel.dart';

abstract class IzinRemoteDataSource {
  Future<List<IzinModel>> getIzinHistory({required String token});
  Future<void> createIzin({
    required String token,
    required String date,
    required String type,
    required String reason,
  });
}

class IzinRemoteDataSourceImpl implements IzinRemoteDataSource {
  final ApiService _apiService;

  IzinRemoteDataSourceImpl(http.Client _, this._apiService);

  @override
  Future<List<IzinModel>> getIzinHistory({required String token}) async {
    try {
      final body = await _apiService.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.izinEndpoint}'),
        headers: ApiConstants.authAcceptHeaders(token),
      );

      final data = _extractList(body);
      return data
          .map((e) => IzinModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ClientException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<void> createIzin({
    required String token,
    required String date,
    required String type,
    required String reason,
  }) async {
    await _apiService.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.izinEndpoint}'),
      headers: ApiConstants.authJsonHeaders(token),
      body: jsonEncode({
        'date': date,
        'type': type,
        'reason': reason,
        'alasan_izin': reason,
      }),
    );
  }

  List<dynamic> _extractList(Map<String, dynamic> body) {
    if (body['data'] is List) return body['data'] as List;
    if (body['leaves'] is List) return body['leaves'] as List;
    if (body['izin'] is List) return body['izin'] as List;
    return [];
  }
}
