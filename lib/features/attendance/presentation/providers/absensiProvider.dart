import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../../home/domain/entities/riwayat.dart';
import '../../domain/entities/absensiHariIni.dart';
import '../../domain/usecases/deleteAbsenUsecase.dart';
import '../../domain/usecases/getTodayStatusUsecase.dart';
import '../../domain/usecases/getAbsensiHistoryUsecase.dart';

class AbsensiProvider extends ChangeNotifier {
  final GetAbsensiHistoryUseCase _getHistoryUseCase;
  final GetTodayStatusUseCase _getTodayStatusUseCase;
  final DeleteAbsenUseCase _deleteAbsenUseCase;
  final AuthRepository _authRepository;

  AbsensiProvider({
    required GetAbsensiHistoryUseCase getHistoryUseCase,
    required GetTodayStatusUseCase getTodayStatusUseCase,
    required DeleteAbsenUseCase deleteAbsenUseCase,
    required AuthRepository authRepository,
  }) : _getHistoryUseCase = getHistoryUseCase,
       _getTodayStatusUseCase = getTodayStatusUseCase,
       _deleteAbsenUseCase = deleteAbsenUseCase,
       _authRepository = authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Riwayat> _riwayatList = [];
  AbsensiHariIni _todayStatus = AbsensiHariIni.empty;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Riwayat> get riwayatList => _riwayatList;
  AbsensiHariIni get todayStatus => _todayStatus;

  Future<void> getToday() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      _todayStatus = await _getTodayStatusUseCase(token: token);
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _todayStatus = AbsensiHariIni.empty;
    } catch (_) {
      _errorMessage = 'Gagal memuat status absensi hari ini.';
      _todayStatus = AbsensiHariIni.empty;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      _riwayatList = await _getHistoryUseCase(token: token);
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _riwayatList = [];
    } catch (_) {
      _errorMessage = 'Gagal memuat riwayat absensi.';
      _riwayatList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() => getHistory();

  Future<void> deleteAbsen(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
        throw const ServerException(
          message: 'Sesi telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
      }

      await _deleteAbsenUseCase(token: token, id: id);
      _riwayatList = _riwayatList
          .where((item) => item.id != id)
          .toList(growable: false);
    } on ServerException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (_) {
      const fallback = 'Gagal menghapus data';
      _errorMessage = fallback;
      throw const ServerException(message: fallback, statusCode: 0);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
