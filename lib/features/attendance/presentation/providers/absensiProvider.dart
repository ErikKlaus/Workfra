import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/attendance_utils.dart';
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

  bool _isLoadingToday = false;
  bool _isLoadingHistory = false;
  bool _isDeleting = false;
  String? _errorMessage;
  List<Riwayat> _riwayatList = [];
  AbsensiHariIni _todayStatus = AbsensiHariIni.empty;

  bool get isLoading => _isLoadingToday || _isLoadingHistory || _isDeleting;
  bool get isLoadingToday => _isLoadingToday;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  List<Riwayat> get riwayatList => _riwayatList;
  AbsensiHariIni get todayStatus => _todayStatus;

  Future<void> getToday() async {
    _isLoadingToday = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'error_session_expired';
        _isLoadingToday = false;
        notifyListeners();
        return;
      }
      _todayStatus = await _getTodayStatusUseCase(token: token);
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _todayStatus = AbsensiHariIni.empty;
    } catch (_) {
      _errorMessage = 'error_load_attendance_status';
      _todayStatus = AbsensiHariIni.empty;
    } finally {
      _isLoadingToday = false;
      notifyListeners();
    }
  }

  Future<void> getHistory() async {
    _isLoadingHistory = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'error_session_expired';
        _isLoadingHistory = false;
        notifyListeners();
        return;
      }
      _riwayatList = await _getHistoryUseCase(token: token);
    } on ServerException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'error_load_history';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() => getHistory();

  Future<void> deleteAbsen(int id) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    final previousList = List<Riwayat>.from(_riwayatList);
    Riwayat? deletedItem;
    for (final item in _riwayatList) {
      if (item.id == id) {
        deletedItem = item;
        break;
      }
    }

    // Optimistic update: remove item locally first for snappier UI.
    _riwayatList = _riwayatList
        .where((item) => item.id != id)
        .toList(growable: false);
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _riwayatList = previousList;
        _errorMessage = 'error_session_expired';
        throw const ServerException(
          message: 'error_session_expired',
          statusCode: 401,
        );
      }

      await _deleteAbsenUseCase(token: token, id: id);

      // Refresh both history and today state in parallel for faster check-in retry flow.
      final refreshed = await Future.wait<dynamic>([
        _getHistoryUseCase(token: token),
        _getTodayStatusUseCase(
          token: token,
        ).catchError((_) => AbsensiHariIni.empty),
      ]);

      _riwayatList = (refreshed[0] as List<Riwayat>).toList(growable: false);
      _todayStatus = refreshed[1] as AbsensiHariIni;

      final isDeletedItemToday =
          deletedItem != null &&
          AttendanceUtils.isSameDate(deletedItem.tanggal, DateTime.now());

      if (isDeletedItemToday &&
          (_todayStatus.hasCheckedIn || _todayStatus.hasCheckedOut)) {
        // Defensive fallback if backend still returns stale today status.
        _todayStatus = AbsensiHariIni.empty;
      }

      notifyListeners();
    } on ServerException catch (e) {
      _riwayatList = previousList;
      _errorMessage = e.message;
      rethrow;
    } catch (_) {
      _riwayatList = previousList;
      const fallback = 'error_delete_attendance';
      _errorMessage = fallback;
      throw const ServerException(message: fallback, statusCode: 0);
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}
