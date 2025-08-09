import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('th');

  Locale get currentLocale => _currentLocale;

  String get currentLanguage => _currentLocale.languageCode;

  bool get isThaiSelected => _currentLocale.languageCode == 'th';
  bool get isEnglishSelected => _currentLocale.languageCode == 'en';

  static const String _languageKey = 'selected_language';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? 'th';
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
    } catch (e) {
      print('Error loading saved language: $e');
      _currentLocale = const Locale('th'); // fallback to Thai
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == _currentLocale.languageCode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  Future<void> toggleLanguage() async {
    final newLanguage = _currentLocale.languageCode == 'th' ? 'en' : 'th';
    await setLanguage(newLanguage);
  }

  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'th':
        return 'ไทย';
      case 'en':
        return 'English';
      default:
        return 'Unknown';
    }
  }

  String getCurrentLanguageDisplayName() {
    return getLanguageDisplayName(_currentLocale.languageCode);
  }
}
