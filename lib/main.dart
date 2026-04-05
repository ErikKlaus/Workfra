import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'di/injeksi.dart';
import 'features/auth/presentation/providers/authProvider.dart';
import 'features/home/presentation/providers/berandaProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia untuk format tanggal
  await initializeDateFormatting('id_ID', null);

  final prefs = await SharedPreferences.getInstance();
  await initInjection(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider<HomeProvider>(create: (_) => sl<HomeProvider>()),
      ],
      child: const WorkfraApp(),
    ),
  );
}
