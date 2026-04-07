import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  const NotificationPermissionService();

  Future<void> requestOnAndroid() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final status = await Permission.notification.status;
    if (status.isGranted || status.isPermanentlyDenied) {
      return;
    }

    await Permission.notification.request();
  }
}
