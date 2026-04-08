import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late Map<String, String> _localizedStrings;

  static const List<Locale> supportedLocales = [
    Locale('id'),
    Locale('en'),
    Locale('zh'),
    Locale('ms'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final appLocalizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    assert(
      appLocalizations != null,
      'AppLocalizations is missing in widget tree.',
    );

    return appLocalizations!;
  }

  static String intlLocaleFromCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'en_US';
      case 'zh':
        return 'zh_CN';
      case 'ms':
        return 'ms_MY';
      case 'id':
      default:
        return 'id_ID';
    }
  }

  static String intlLocaleOf(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return intlLocaleFromCode(languageCode);
  }

  Future<bool> load() async {
    final languageCode = _normalizeLanguageCode(locale.languageCode);
    final content = await rootBundle.loadString(
      'lib/core/localization/$languageCode.json',
    );

    final decoded = json.decode(content) as Map<String, dynamic>;
    _localizedStrings = decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return true;
  }

  String tr(String key, {Map<String, String>? params}) {
    var translatedValue = _localizedStrings[key] ?? key;

    if (params == null || params.isEmpty) {
      return translatedValue;
    }

    params.forEach((paramKey, paramValue) {
      translatedValue = translatedValue.replaceAll('{$paramKey}', paramValue);
    });

    return translatedValue;
  }

  String _normalizeLanguageCode(String languageCode) {
    for (final locale in supportedLocales) {
      if (locale.languageCode == languageCode) {
        return languageCode;
      }
    }

    return 'id';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localization = AppLocalizations(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

extension LocalizationBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key, {Map<String, String>? params}) {
    return l10n.tr(key, params: params);
  }

  String get intlLocale => AppLocalizations.intlLocaleOf(this);
}

String tr(BuildContext context, String key, {Map<String, String>? params}) {
  return AppLocalizations.of(context).tr(key, params: params);
}
