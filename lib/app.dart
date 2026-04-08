import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/temaAplikasi.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/globalShimmerLayer.dart';
import 'features/auth/presentation/pages/halamanLupaPassword.dart';
import 'features/auth/presentation/pages/halamanOTP.dart';
import 'features/auth/presentation/pages/halamanResetPassword.dart';
import 'features/auth/presentation/pages/halamanLogin.dart';
import 'features/auth/presentation/pages/halamanBuatAkun.dart';
import 'features/auth/presentation/pages/halamanSplash.dart';
import 'features/auth/presentation/pages/halamanSukses.dart';
import 'features/auth/presentation/pages/halamanFotoProfil.dart';
import 'features/home/presentation/pages/halamanBeranda.dart';

class WorkfraApp extends StatelessWidget {
  const WorkfraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Workfra',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
          builder: (context, child) {
            if (child == null) {
              return const SizedBox.shrink();
            }
            return GlobalShimmerLayer(child: child);
          },
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashPage(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/upload-photo': (_) => const UploadPhotoPage(),
            '/success': (_) => const SuccessPage(),
            '/lupa-password': (_) => const HalamanLupaPassword(),
            '/otp': (_) => const HalamanOTP(),
            '/reset-password': (_) => const HalamanResetPassword(),
            '/home': (_) => const HalamanBeranda(),
          },
        );
      },
    );
  }
}
