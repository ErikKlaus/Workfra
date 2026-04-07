import 'package:flutter/material.dart';

enum GroupNotifikasi { hariIni, mingguIni }

class Notifikasi {
  final int id;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;
  final String time;
  final bool isUnread;
  final GroupNotifikasi group;
  final DateTime createdAt;

  const Notifikasi({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.time,
    this.isUnread = false,
    required this.group,
    required this.createdAt,
  });

  Notifikasi copyWith({
    int? id,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
    String? title,
    String? description,
    String? time,
    bool? isUnread,
    GroupNotifikasi? group,
    DateTime? createdAt,
  }) {
    return Notifikasi(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      iconBgColor: iconBgColor ?? this.iconBgColor,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      isUnread: isUnread ?? this.isUnread,
      group: group ?? this.group,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
