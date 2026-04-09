import 'package:flutter/material.dart';

import '../../../../core/services/notifikasiSistemService.dart';

import '../../domain/entities/notifikasi.dart';
import '../../domain/usecases/addPresensiNotifikasiUsecase.dart';
import '../../domain/usecases/getNotifikasiUsecase.dart';
import '../../domain/usecases/markAllNotifikasiReadUsecase.dart';

class NotifikasiProvider extends ChangeNotifier {
  final GetNotifikasiUseCase _getNotifikasiUseCase;
  final AddPresensiNotifikasiUseCase _addPresensiNotifikasiUseCase;
  final MarkAllNotifikasiReadUseCase _markAllNotifikasiReadUseCase;

  NotifikasiProvider({
    required GetNotifikasiUseCase getNotifikasiUseCase,
    required AddPresensiNotifikasiUseCase addPresensiNotifikasiUseCase,
    required MarkAllNotifikasiReadUseCase markAllNotifikasiReadUseCase,
  }) : _getNotifikasiUseCase = getNotifikasiUseCase,
       _addPresensiNotifikasiUseCase = addPresensiNotifikasiUseCase,
       _markAllNotifikasiReadUseCase = markAllNotifikasiReadUseCase;

  bool _isLoading = false;
  List<Notifikasi> _notifikasi = const [];
  String _localeCode = 'id';

  bool get isLoading => _isLoading;
  List<Notifikasi> get notifikasi => _notifikasi;
  bool get hasUnread => _notifikasi.any((n) => n.isUnread);

  List<Notifikasi> get notifikasiHariIni =>
      _notifikasi.where((n) => n.group == GroupNotifikasi.hariIni).toList();

  List<Notifikasi> get notifikasiMingguIni =>
      _notifikasi.where((n) => n.group == GroupNotifikasi.mingguIni).toList();

  Future<void> loadNotifikasi({required String localeCode}) async {
    _localeCode = _normalizeLocaleCode(localeCode);
    _isLoading = true;
    notifyListeners();
    try {
      _notifikasi = await _getNotifikasiUseCase(localeCode: _localeCode);
    } catch (_) {
      _notifikasi = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPresensiNotification({
    required bool isCheckIn,
    required String? timeLabel,
    required String localeCode,
  }) async {
    try {
      _localeCode = _normalizeLocaleCode(localeCode);
      await _addPresensiNotifikasiUseCase(
        isCheckIn: isCheckIn,
        timeLabel: timeLabel,
      );
      _notifikasi = await _getNotifikasiUseCase(localeCode: _localeCode);
      notifyListeners();

      await NotifikasiSistemService.instance.showPresensiNotification(
        isCheckIn: isCheckIn,
        timeLabel: timeLabel,
        localeCode: _localeCode,
      );
    } catch (_) {
      // Silently ignore notification write errors so attendance flow stays smooth.
    }
  }

  Future<void> markAllAsRead({String? localeCode}) async {
    if (!hasUnread) return;

    try {
      final targetLocale = _normalizeLocaleCode(localeCode ?? _localeCode);
      _localeCode = targetLocale;
      await _markAllNotifikasiReadUseCase();
      _notifikasi = await _getNotifikasiUseCase(localeCode: targetLocale);
      notifyListeners();
    } catch (_) {
      // Silently ignore mark-read errors in local mock source.
    }
  }

  String _normalizeLocaleCode(String localeCode) {
    final normalized = localeCode.toLowerCase();
    if (normalized.startsWith('en')) return 'en';
    if (normalized.startsWith('zh')) return 'zh';
    if (normalized.startsWith('ms')) return 'ms';
    return 'id';
  }
}
