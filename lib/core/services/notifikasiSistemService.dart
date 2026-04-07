import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifikasiSistemService {
  NotifikasiSistemService._();

  static final NotifikasiSistemService instance = NotifikasiSistemService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationChannel _attendanceChannel =
      AndroidNotificationChannel(
        'workfra_attendance_channel',
        'Workfra Attendance',
        description: 'Notifikasi aktivitas presensi Workfra',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('push_pop_notification'),
      );

  Future<void> initialize() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initializationSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_attendanceChannel);

    _initialized = true;
  }

  Future<void> showPresensiNotification({
    required bool isCheckIn,
    required String? timeLabel,
  }) async {
    await initialize();

    final actionLabel = isCheckIn ? 'masuk' : 'pulang';
    final safeTime = _sanitizeTime(timeLabel);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      isCheckIn ? 'Check-in Berhasil' : 'Check-out Berhasil',
      'Presensi $actionLabel tercatat pada $safeTime.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'workfra_attendance_channel',
          'Workfra Attendance',
          channelDescription: 'Notifikasi aktivitas presensi Workfra',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('push_pop_notification'),
          category: AndroidNotificationCategory.status,
        ),
      ),
    );
  }

  String _sanitizeTime(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty || cleaned == '-') {
      final now = DateTime.now();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return cleaned;
  }
}
