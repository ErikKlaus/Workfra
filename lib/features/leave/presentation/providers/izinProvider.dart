import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../domain/entities/izin.dart';
import '../../domain/usecases/createIzinUsecase.dart';
import '../../domain/usecases/getIzinHistoryUsecase.dart';

class IzinProvider extends ChangeNotifier {
  final GetIzinHistoryUseCase _getHistoryUseCase;
  final CreateIzinUseCase _createIzinUseCase;
  final AuthRepository _authRepository;

  IzinProvider({
    required GetIzinHistoryUseCase getHistoryUseCase,
    required CreateIzinUseCase createIzinUseCase,
    required AuthRepository authRepository,
  }) : _getHistoryUseCase = getHistoryUseCase,
       _createIzinUseCase = createIzinUseCase,
       _authRepository = authRepository;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _submitError;
  List<Izin> _izinList = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get submitError => _submitError;
  List<Izin> get izinList => _izinList;

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
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      _izinList = await _getHistoryUseCase(token: token);
      _sortByLatest();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _izinList = [];
    } catch (_) {
      _errorMessage = 'Gagal memuat riwayat izin.';
      _izinList = [];
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
    notifyListeners();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _submitError = 'Sesi telah berakhir. Silakan login kembali.';
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
      _submitError = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _submitError = 'Gagal mengajukan izin. Silakan coba lagi.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
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

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
