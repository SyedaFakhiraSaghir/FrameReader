class AppConstants {
  static const String appName = 'OCR Translator';
  static const String version = '1.0.0';
  
  // API Endpoints
  static const String dictionaryApiUrl = 'https://api.dictionaryapi.dev/api/v2/entries';
  static const String translationApiUrl = 'https://api.mymemory.translated.net/get';
  
  // File types
  static const List<String> supportedImageExtensions = ['jpg', 'jpeg', 'png', 'bmp', 'gif'];
  static const List<String> supportedVideoExtensions = ['mp4', 'avi', 'mov', 'mkv'];
  static const List<String> supportedDocumentExtensions = ['pdf', 'doc', 'docx', 'txt'];
  
  // OCR Settings
  static const double ocrConfidenceThreshold = 0.5;
  static const int maxWordsToTranslate = 10;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
}

enum MediaType {
  image,
  video,
  document,
}

enum Language {
  english('en', 'English'),
  urdu('ur', 'Urdu'),
  arabic('ar', 'Arabic'),
  spanish('es', 'Spanish'),
  french('fr', 'French'),
  german('de', 'German'),
  chinese('zh', 'Chinese'),
  hindi('hi', 'Hindi');
  
  final String code;
  final String name;
  
  const Language(this.code, this.name);
}
