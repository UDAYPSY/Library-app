import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import 'local_storage_service.dart';

export '../constants/app_strings.dart' show AppLanguage;

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  AppLanguage _language = AppLanguage.en;
  bool _initialized = false;

  AppLanguage get currentLanguage => _language;
  bool get isHindi => _language == AppLanguage.hi;
  String get currentLanguageCode => _language == AppLanguage.hi ? 'hi' : 'en';
  String get currentLanguageName => _language == AppLanguage.hi ? 'हिंदी (Hindi)' : 'English';

  /// Translation shortcut
  String t(String key, {String? fallback}) => AppStrings.get(key, _language, fallback: fallback);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final saved = await LocalStorageService.getString('app_language');
      if (saved == 'hi') {
        _language = AppLanguage.hi;
      } else {
        _language = AppLanguage.en;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    notifyListeners();
    try {
      await LocalStorageService.saveString('app_language', lang == AppLanguage.hi ? 'hi' : 'en');
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    final next = _language == AppLanguage.hi ? AppLanguage.en : AppLanguage.hi;
    await setLanguage(next);
  }
}
