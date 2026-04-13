import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/fallback_delegates.dart';
import 'core/localization/languageProvider.dart';
import 'core/theme/temaAplikasi.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/navigatorKey.dart';
import 'core/widgets/globalShimmerLayer.dart';
import 'core/widgets/globalRequirementObserver.dart';
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
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return MaterialApp(
          navigatorKey: globalNavigatorKey,
          title: 'Workfra',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: languageProvider.locale,
          localeResolutionCallback: (locale, supportedLocales) {
            // Flutter's built-in Material/Cupertino delegates only support
            // standard ISO 639-1 codes. For regional dialects (min, btk,
            // mnd, su, jv) we must return a supported fallback so the
            // framework delegates don't crash – our own AppLocalizations
            // delegate still loads the correct JSON.
            if (locale != null) {
              for (final s in supportedLocales) {
                if (s.languageCode == locale.languageCode) {
                  return locale;
                }
              }
            }
            return const Locale('id');
          },
          localizationsDelegates: [
            AppLocalizations.delegate,
            fallbackMaterialDelegate,
            fallbackWidgetsDelegate,
            fallbackCupertinoDelegate,
          ],
          supportedLocales: const [
            // Locales natively supported by Flutter's Material/Cupertino
            Locale('id'),
            Locale('en'),
            Locale('zh'),
            Locale('ms'),
            Locale('ja'),
            Locale('hi'),
            Locale('es'),
            Locale('fr'),
            // Regional dialects – listed here so our AppLocalizations
            // delegate sees them, but localeResolutionCallback ensures
            // the framework delegates get a valid fallback.
            Locale('jv'),
            Locale('min'),
            Locale('su'),
            Locale('btk'),
            Locale('mnd'),
          ],
          builder: (context, child) {
            if (child == null) {
              return const SizedBox.shrink();
            }
            return GlobalRequirementObserver(
              child: GlobalShimmerLayer(child: child),
            );
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
