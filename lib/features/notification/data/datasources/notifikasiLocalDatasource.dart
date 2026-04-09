import 'package:flutter/material.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/notifikasiLocalizationHelper.dart';
import '../../domain/entities/notifikasi.dart';

abstract class NotifikasiLocalDataSource {
  Future<List<Notifikasi>> getNotifikasi({required String localeCode});
  Future<void> addPresensiNotifikasi({
    required bool isCheckIn,
    required String? timeLabel,
  });
  Future<void> markAllAsRead();
}

class NotifikasiLocalDataSourceImpl implements NotifikasiLocalDataSource {
  final List<_StoredNotifikasi> _items = [];
  int _idCounter = 0;

  @override
  Future<List<Notifikasi>> getNotifikasi({required String localeCode}) async {
    final resolvedLocale = NotifikasiLocalizationHelper.normalizeLocaleCode(
      localeCode,
    );
    final now = DateTime.now();

    return _items
        .map(
          (item) => Notifikasi(
            id: item.id,
            icon: item.isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
            iconColor: AppColors.primary,
            iconBgColor: const Color(0xFFE6F7FB),
            title: NotifikasiLocalizationHelper.attendanceTitle(
              isCheckIn: item.isCheckIn,
              localeCode: resolvedLocale,
            ),
            description: NotifikasiLocalizationHelper.attendanceDescription(
              isCheckIn: item.isCheckIn,
              timeLabel: item.timeLabel,
              localeCode: resolvedLocale,
            ),
            time: NotifikasiLocalizationHelper.relativeTime(
              createdAt: item.createdAt,
              now: now,
              localeCode: resolvedLocale,
            ),
            isUnread: item.isUnread,
            group: _resolveGroup(item.createdAt, now: now),
            createdAt: item.createdAt,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> addPresensiNotifikasi({
    required bool isCheckIn,
    required String? timeLabel,
  }) async {
    final now = DateTime.now();
    _idCounter += 1;

    final notifikasi = _StoredNotifikasi(
      id: _idCounter,
      isCheckIn: isCheckIn,
      timeLabel: _sanitizeTime(timeLabel),
      isUnread: true,
      createdAt: now,
    );

    _items.insert(0, notifikasi);
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isUnread: false);
    }
  }

  GroupNotifikasi _resolveGroup(DateTime createdAt, {required DateTime now}) {
    final nowDateOnly = DateTime(now.year, now.month, now.day);
    final createdDateOnly = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );
    final diffDays = nowDateOnly.difference(createdDateOnly).inDays;

    if (diffDays <= 0) {
      return GroupNotifikasi.hariIni;
    }

    return GroupNotifikasi.mingguIni;
  }

  String _sanitizeTime(String? timeLabel) {
    final normalized = timeLabel?.trim();
    if (normalized == null || normalized.isEmpty || normalized == '-') {
      final now = DateTime.now();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return normalized;
  }
}

class _StoredNotifikasi {
  final int id;
  final bool isCheckIn;
  final String timeLabel;
  final bool isUnread;
  final DateTime createdAt;

  const _StoredNotifikasi({
    required this.id,
    required this.isCheckIn,
    required this.timeLabel,
    required this.isUnread,
    required this.createdAt,
  });

  _StoredNotifikasi copyWith({bool? isUnread}) {
    return _StoredNotifikasi(
      id: id,
      isCheckIn: isCheckIn,
      timeLabel: timeLabel,
      isUnread: isUnread ?? this.isUnread,
      createdAt: createdAt,
    );
  }
}
