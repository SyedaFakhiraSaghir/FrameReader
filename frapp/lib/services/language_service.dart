import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _prefKey = 'selected_language';
  
  final Map<String, String> _supportedLanguages = {
    'en': 'English',
    'ur': 'Urdu',
    'ar': 'Arabic',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'zh': 'Chinese',
    'hi': 'Hindi',
  };
  
  String _currentLanguage = 'en';
  
  LanguageService() {
    _loadLanguage();
  }
  
  Map<String, String> get supportedLanguages => _supportedLanguages;
  
  String get currentLanguage => _currentLanguage;
  
  Future<void> setLanguage(String languageCode) async {
    if (_supportedLanguages.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, languageCode);
    }
  }
  
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && _supportedLanguages.containsKey(saved)) {
      _currentLanguage = saved;
    }
  }
  
  String getLanguageName(String code) {
    return _supportedLanguages[code] ?? code;
  }
  
  bool isLanguageSupported(String code) {
    return _supportedLanguages.containsKey(code);
  }
  
  List<String> getSupportedLanguageCodes() {
    return _supportedLanguages.keys.toList();
  }
}