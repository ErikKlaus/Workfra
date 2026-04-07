import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/notifikasiSistemService.dart';
import 'core/services/notificationPermissionService.dart';
import 'di/injeksi.dart';
import 'features/auth/presentation/providers/authProvider.dart';
import 'features/home/presentation/providers/berandaProvider.dart';
import 'features/profile/presentation/providers/profileProvider.dart';
import 'features/notification/presentation/providers/notifikasiProvider.dart';
import 'features/attendance/presentation/providers/absensiProvider.dart';
import 'features/attendance/presentation/providers/presensiProvider.dart';
import 'features/attendance/presentation/providers/riwayatProvider.dart';
import 'features/leave/presentation/providers/izinProvider.dart';
import 'features/statistics/presentation/providers/statistikProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia untuk format tanggal
  await initializeDateFormatting('id_ID', null);

  final prefs = await SharedPreferences.getInstance();
  await initInjection(prefs);

  await NotifikasiSistemService.instance.initialize();

  // Ask Android notification permission once app starts.
  NotificationPermissionService().requestOnAndroid();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider<HomeProvider>(create: (_) => sl<HomeProvider>()),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => sl<ProfileProvider>(),
        ),
        ChangeNotifierProvider<NotifikasiProvider>(
          create: (_) => sl<NotifikasiProvider>(),
        ),
        ChangeNotifierProvider<AbsensiProvider>(
          create: (_) => sl<AbsensiProvider>(),
        ),
        ChangeNotifierProvider<PresensiProvider>(
          create: (_) => sl<PresensiProvider>(),
        ),
        ChangeNotifierProvider<RiwayatProvider>(
          create: (_) => sl<RiwayatProvider>(),
        ),
        ChangeNotifierProvider<IzinProvider>(create: (_) => sl<IzinProvider>()),
        ChangeNotifierProvider<StatistikProvider>(
          create: (_) => sl<StatistikProvider>(),
        ),
      ],
      child: const WorkfraApp(),
    ),
  );
}
