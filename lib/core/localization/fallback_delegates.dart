import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Locale codes that Flutter's built-in Material / Cupertino / Widgets
/// delegates can resolve natively.  Anything NOT in this set must be
/// remapped to a safe fallback before the framework delegates see it.
const _flutterNativeLocales = <String>{
  'af', 'am', 'ar', 'as', 'az', 'be', 'bg', 'bn', 'bs', 'ca', 'cs',
  'cy', 'da', 'de', 'el', 'en', 'es', 'et', 'eu', 'fa', 'fi', 'fil',
  'fr', 'gl', 'gsw', 'gu', 'he', 'hi', 'hr', 'hu', 'hy', 'id', 'is',
  'it', 'ja', 'ka', 'kk', 'km', 'kn', 'ko', 'ky', 'lo', 'lt', 'lv',
  'mk', 'ml', 'mn', 'mr', 'ms', 'my', 'nb', 'ne', 'nl', 'no', 'or',
  'pa', 'pl', 'ps', 'pt', 'ro', 'ru', 'si', 'sk', 'sl', 'sq', 'sr',
  'sv', 'sw', 'ta', 'te', 'th', 'tl', 'tr', 'uk', 'ur', 'uz', 'vi',
  'zh', 'zu',
};

/// Maps a potentially unsupported locale to one the framework delegates
/// can actually load.
Locale _fallback(Locale locale) {
  if (_flutterNativeLocales.contains(locale.languageCode)) {
    return locale;
  }
  // Regional Indonesian dialects → id
  return const Locale('id');
}

/// A [LocalizationsDelegate] wrapper that intercepts [load] calls and
/// remaps the locale to a Flutter-supported fallback when necessary.
class _FallbackDelegate<T> extends LocalizationsDelegate<T> {
  const _FallbackDelegate(this._inner);
  final LocalizationsDelegate<T> _inner;

  @override
  bool isSupported(Locale locale) => _inner.isSupported(_fallback(locale));

  @override
  Future<T> load(Locale locale) => _inner.load(_fallback(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}

/// Pre-built fallback delegates for the three Flutter framework
/// localisation layers.
final fallbackMaterialDelegate =
    _FallbackDelegate<MaterialLocalizations>(GlobalMaterialLocalizations.delegate);

final fallbackWidgetsDelegate =
    _FallbackDelegate<WidgetsLocalizations>(GlobalWidgetsLocalizations.delegate);

final fallbackCupertinoDelegate =
    _FallbackDelegate<CupertinoLocalizations>(GlobalCupertinoLocalizations.delegate);
