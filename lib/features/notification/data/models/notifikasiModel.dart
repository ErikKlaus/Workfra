import 'package:flutter/material.dart';

import '../../domain/entities/notifikasi.dart';

class NotifikasiModel extends Notifikasi {
  const NotifikasiModel({
    required super.id,
    required super.icon,
    required super.iconColor,
    required super.iconBgColor,
    required super.title,
    required super.description,
    required super.time,
    super.isUnread,
    required super.group,
    required super.createdAt,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      id: json['id'] as int,
      icon: Icons.notifications_rounded,
      iconColor: const Color(0xFF0FA9C4),
      iconBgColor: const Color(0xFFE6F7FB),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      time: json['time'] as String? ?? '',
      isUnread: json['is_read'] == false,
      group: GroupNotifikasi.hariIni,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
