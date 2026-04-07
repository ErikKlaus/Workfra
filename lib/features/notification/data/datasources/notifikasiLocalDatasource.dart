import 'package:flutter/material.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../domain/entities/notifikasi.dart';

abstract class NotifikasiLocalDataSource {
  Future<List<Notifikasi>> getNotifikasi();
  Future<void> addPresensiNotifikasi({
    required bool isCheckIn,
    required String? timeLabel,
  });
  Future<void> markAllAsRead();
}

class NotifikasiLocalDataSourceImpl implements NotifikasiLocalDataSource {
  final List<Notifikasi> _items = [];
  int _idCounter = 0;

  @override
  Future<List<Notifikasi>> getNotifikasi() async {
    final now = DateTime.now();
    return _items
        .map(
          (item) => item.copyWith(
            time: _formatRelativeTime(item.createdAt, now: now),
            group: _resolveGroup(item.createdAt, now: now),
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

    final title = isCheckIn ? 'Check-in Berhasil' : 'Check-out Berhasil';
    final actionLabel = isCheckIn ? 'masuk' : 'pulang';
    final safeTime = _sanitizeTime(timeLabel);

    final notifikasi = Notifikasi(
      id: _idCounter,
      icon: isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
      iconColor: AppColors.primary,
      iconBgColor: const Color(0xFFE6F7FB),
      title: title,
      description: 'Presensi $actionLabel tercatat pada $safeTime.',
      time: 'Baru saja',
      isUnread: true,
      group: GroupNotifikasi.hariIni,
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

  String _formatRelativeTime(DateTime createdAt, {required DateTime now}) {
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} menit lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    }

    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    return '$day/$month/$year';
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
