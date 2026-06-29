import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, dynamic>? _strings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<bool> load() async {
    try {
      final code = locale.languageCode;
      final jsonStr = await rootBundle.loadString('assets/lang/$code.json');
      _strings = jsonDecode(jsonStr) as Map<String, dynamic>;
      return true;
    } catch (_) {
      try {
        final jsonStr = await rootBundle.loadString('assets/lang/en.json');
        _strings = jsonDecode(jsonStr) as Map<String, dynamic>;
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  String t(String key, {Map<String, String>? params}) {
    final keys = key.split('.');
    dynamic val = _strings;
    for (final k in keys) {
      if (val is Map) {
        val = val[k];
      } else {
        return key;
      }
    }
    if (val is! String) return key;
    if (params != null) {
      for (final e in params.entries) {
        val = val.replaceAll('{$e.key}', e.value);
      }
    }
    return val;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final l = AppLocalizations(locale);
    await l.load();
    return l;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
