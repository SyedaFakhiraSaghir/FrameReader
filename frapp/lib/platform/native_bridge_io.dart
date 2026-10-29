import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ocr_result.dart';
import 'native_bridge_stub.dart';

export 'native_bridge_stub.dart' show NativeBridge;

class MethodChannelNativeBridge implements NativeBridge {
  MethodChannelNativeBridge();

  static const _channel = MethodChannel('frapp/native');

  @override
  Future<OCRResult> recognizeText(Uint8List bytes, {String? language}) async {
    if (Platform.isMacOS) {
      final raw = await _channel.invokeMethod<dynamic>('recognizeText', {
        'bytes': bytes,
        'language': language ?? 'en',
      });
      return _parseOcr(raw, language ?? 'en');
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
        'Native text recognition is not supported on this platform.',
      );
    }
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'Image data cannot be empty.');
    }

    final script = _scriptFor(language);
    final directory = await getTemporaryDirectory();
    final imageFile = File(
      '${directory.path}/frapp-ocr-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final recognizer = TextRecognizer(script: script);

    try {
      await imageFile.writeAsBytes(bytes, flush: true);
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imageFile.path),
      );
      final words = [
        for (final block in recognized.blocks)
          for (final line in block.lines)
            for (final element in line.elements)
              if (element.text.trim().isNotEmpty)
                OCRWord(
                  text: element.text,
                  boundingBox: element.boundingBox,
                  confidence: element.confidence ?? line.confidence ?? 0,
                  language: language ?? 'en',
                ),
      ];
      final confidences = [
        for (final word in words)
          if (word.confidence > 0) word.confidence,
      ];
      return OCRResult(
        text: recognized.text,
        words: words,
        language: language ?? 'en',
        confidence: confidences.isEmpty
            ? 0
            : confidences.reduce((a, b) => a + b) / confidences.length,
      );
    } finally {
      await recognizer.close();
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    }
  }

  @override
  Future<Uint8List> extractVideoFrame(String path, Duration position) async {
    final raw = await _channel.invokeMethod<dynamic>('extractVideoFrame', {
      'path': path,
      'positionMs': position.inMilliseconds,
    });
    return _asBytes(raw, 'The video frame could not be extracted.');
  }

  @override
  Future<Uint8List> renderPdfPage(Uint8List bytes, {int pageIndex = 0}) async {
    final raw = await _channel.invokeMethod<dynamic>('renderPdfPage', {
      'bytes': bytes,
      'pageIndex': pageIndex,
    });
    return _asBytes(raw, 'The PDF page could not be rendered.');
  }

  @override
  Future<int> pdfPageCount(Uint8List bytes) async {
    final count = await _channel.invokeMethod<int>('pdfPageCount', {
      'bytes': bytes,
    });
    if (count == null || count < 1) {
      throw PlatformException(
        code: 'invalid_pdf',
        message: 'The PDF does not contain any readable pages.',
      );
    }
    return count;
  }

  TextRecognitionScript _scriptFor(String? language) {
    switch (language) {
      case 'zh':
        return TextRecognitionScript.chinese;
      case 'hi':
        return TextRecognitionScript.devanagiri;
      case 'ur':
      case 'ar':
        throw UnsupportedError(
          'Google ML Kit text recognition does not support Urdu or Arabic. '
          'Choose English or another supported script.',
        );
      default:
        return TextRecognitionScript.latin;
    }
  }

  OCRResult _parseOcr(dynamic raw, String language) {
    if (raw is! Map) {
      throw PlatformException(
        code: 'invalid_result',
        message: 'OCR returned an unexpected result.',
      );
    }
    final map = Map<String, dynamic>.from(raw);
    final wordMaps = map['words'] is List ? map['words'] as List : const [];
    final words = wordMaps
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(
          (word) => OCRWord(
            text: word['text']?.toString() ?? '',
            boundingBox: Rect.fromLTWH(
              (word['x'] as num?)?.toDouble() ?? 0,
              (word['y'] as num?)?.toDouble() ?? 0,
              (word['width'] as num?)?.toDouble() ?? 0,
              (word['height'] as num?)?.toDouble() ?? 0,
            ),
            confidence: (word['confidence'] as num?)?.toDouble() ?? 0,
            language: language,
          ),
        )
        .where((word) => word.text.trim().isNotEmpty)
        .toList();
    final confidences = [
      for (final word in words)
        if (word.confidence > 0) word.confidence,
    ];
    final width = (map['imageWidth'] as num?)?.toDouble();
    final height = (map['imageHeight'] as num?)?.toDouble();

    return OCRResult(
      text: map['text']?.toString() ?? '',
      words: words,
      language: language,
      confidence: confidences.isEmpty
          ? 0
          : confidences.reduce((a, b) => a + b) / confidences.length,
      imageSize: width != null && height != null && width > 0 && height > 0
          ? Size(width, height)
          : null,
    );
  }

  Uint8List _asBytes(dynamic raw, String error) {
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    throw PlatformException(code: 'invalid_result', message: error);
  }
}

NativeBridge createNativeBridge() => MethodChannelNativeBridge();
