import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/services.dart';

import '../models/ocr_result.dart';

class OCRService {
  final _textDetector = GoogleMlKit.vision.textRecognizer();
  
  Future<OCRResult> extractText(
    String imagePath, {
    String? language,
  }) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textDetector.processImage(inputImage);
      
      final words = <OCRWord>[];
      final textBuffer = StringBuffer();
      
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            words.add(OCRWord(
              text: element.text,
              boundingBox: element.boundingBox,
              confidence: element.confidence ?? 0.0,
              language: language ?? 'en',
            ));
            textBuffer.write('${element.text} ');
          }
        }
      }
      
      return OCRResult(
        text: textBuffer.toString().trim(),
        words: words,
        language: language ?? 'en',
        confidence: words.isNotEmpty 
            ? words.map((w) => w.confidence).reduce((a, b) => a + b) / words.length
            : 0.0,
        metadata: {
          'wordCount': words.length,
          'processedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }
  
  void dispose() {
    _textDetector.close();
  }
}