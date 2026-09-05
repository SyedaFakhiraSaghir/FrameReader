import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/media_capture_screen.dart';
import '../screens/video_editor_screen.dart';
import '../screens/ocr_result_screen.dart';
import '../screens/word_detail_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String capture = '/capture';
  static const String videoEditor = '/video-editor';
  static const String ocrResult = '/ocr-result';
  static const String wordDetail = '/word-detail';
  
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case capture:
        return MaterialPageRoute(builder: (_) => const MediaCaptureScreen());
      case videoEditor:
        return MaterialPageRoute(builder: (_) => const VideoEditorScreen());
      case ocrResult:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OCRResultScreen(
            imagePath: args['imagePath'],
            ocrText: args['ocrText'],
          ),
        );
      case wordDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => WordDetailScreen(
            word: args['word'],
            meaning: args['meaning'],
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}