import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';
  static const List<String> _supportedLanguages = ['en', 'ar'];

  Locale _currentLocale = const Locale(_defaultLanguage);
  Map<String, dynamic> _localizedStrings = {};
  bool _isInitialized = false;

  // <CHANGE> Standardized comments to English
  /// Cache to speed up JSON file loading
  static final Map<String, Map<String, dynamic>> _cache = {};

  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isInitialized => _isInitialized;
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  /// Get system locale language code
  String _getSystemLanguage() {
    try {
      final systemLocale = Platform.localeName; // 'en_US' or 'ar_SA'
      final languageCode = systemLocale.split('_')[0];
      if (_supportedLanguages.contains(languageCode)) {
        return languageCode;
      } else {
        return _defaultLanguage;
      }
    } catch (_) {
      return _defaultLanguage;
    }
  }

  /// Initialize the service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);

      final languageToUse = savedLanguage ?? _getSystemLanguage();
      await setLanguage(languageToUse, saveToPrefs: savedLanguage == null);

      _isInitialized = true;
    } catch (e) {
      final fallbackLanguage = _getSystemLanguage();
      await _loadLanguageStrings(fallbackLanguage);
      _currentLocale = Locale(fallbackLanguage);
      _isInitialized = true;
    }
  }

  /// Set language
  Future<void> setLanguage(
    String languageCode, {
    bool saveToPrefs = true,
  }) async {
    if (languageCode != _currentLocale.languageCode ||
        _localizedStrings.isEmpty) {
      _currentLocale = Locale(languageCode);
      await _loadLanguageStrings(languageCode);

      if (saveToPrefs) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);
      }

      notifyListeners();
    }
  }

  /// Load translations with caching
  Future<void> _loadLanguageStrings(String languageCode) async {
    if (_cache.containsKey(languageCode)) {
      _localizedStrings = _cache[languageCode]!;
      return;
    }

    try {
      final String filePath = 'assets/translations/app_$languageCode.json';
      final String jsonString = await rootBundle.loadString(filePath);
      final Map<String, dynamic> parsedJson = json.decode(jsonString);

      _localizedStrings = parsedJson;
      _cache[languageCode] = parsedJson;
    } catch (e) {
      if (languageCode != _defaultLanguage) {
        await _loadLanguageStrings(_defaultLanguage);
      } else {
        _localizedStrings = {};
      }
    }
  }

  String getString(String key) {
    if (!_isInitialized || _localizedStrings.isEmpty) return key;

    dynamic value = _localizedStrings;
    for (String k in key.split('.')) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key;
      }
    }
    return value?.toString() ?? key;
  }

  String getStringWithParams(String key, Map<String, String> params) {
    String text = getString(key);
    params.forEach((paramKey, paramValue) {
      text = text.replaceAll('{$paramKey}', paramValue);
    });
    return text;
  }

  Future<void> toggleLanguage() async {
    final currentIndex = _supportedLanguages.indexOf(currentLanguageCode);
    final nextIndex = (currentIndex + 1) % _supportedLanguages.length;
    await setLanguage(_supportedLanguages[nextIndex]);
  }

  List<Locale> getSupportedLocales() =>
      _supportedLanguages.map((code) => Locale(code)).toList();

  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return languageCode.toUpperCase();
    }
  }
}

extension LocalizationExtension on BuildContext {
  LocalizationService get localization => LocalizationService._instance;
  String tr(String key) => LocalizationService._instance.getString(key);
  String trParams(String key, Map<String, String> params) =>
      LocalizationService._instance.getStringWithParams(key, params);
}

class AppLocalizationDelegate
    extends LocalizationsDelegate<LocalizationService> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<LocalizationService> load(Locale locale) async {
    final service = LocalizationService._instance;
    await service.setLanguage(locale.languageCode);
    return service;
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}
