import 'package:flutter/services.dart';

import '../models/ocr_result.dart';
import 'native_bridge_stub.dart';

export 'native_bridge_stub.dart' show NativeBridge;

class MethodChannelNativeBridge implements NativeBridge {
  MethodChannelNativeBridge();

  static const _channel = MethodChannel('frapp/native');

  @override
  Future<OCRResult> recognizeText(Uint8List bytes, {String? language}) async {
    final raw = await _channel.invokeMethod<dynamic>('recognizeText', {
      'bytes': bytes,
      'language': language ?? 'en',
    });
    return _parseOcr(raw, language ?? 'en');
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

  OCRResult _parseOcr(dynamic raw, String language) {
    if (raw is! Map) {
      throw Exception('OCR returned an unexpected result.');
    }
    final map = Map<String, dynamic>.from(raw);
    final wordMaps = (map['words'] as List?) ?? const [];
    final words = wordMaps.map((item) {
      final word = Map<String, dynamic>.from(item as Map);
      return OCRWord(
        text: word['text']?.toString() ?? '',
        boundingBox: Rect.fromLTWH(
          (word['x'] as num?)?.toDouble() ?? 0,
          (word['y'] as num?)?.toDouble() ?? 0,
          (word['width'] as num?)?.toDouble() ?? 0,
          (word['height'] as num?)?.toDouble() ?? 0,
        ),
        confidence: (word['confidence'] as num?)?.toDouble() ?? 0,
        language: language,
      );
    }).toList();

    Size? imageSize;
    final width = (map['imageWidth'] as num?)?.toDouble();
    final height = (map['imageHeight'] as num?)?.toDouble();
    if (width != null && height != null && width > 0 && height > 0) {
      imageSize = Size(width, height);
    }

    final text = map['text']?.toString() ??
        words.map((word) => word.text).join(' ').trim();
    final confidence = words.isEmpty
        ? 0.0
        : words.map((word) => word.confidence).reduce((a, b) => a + b) /
            words.length;

    return OCRResult(
      text: text,
      words: words,
      language: language,
      confidence: confidence,
      imageSize: imageSize,
    );
  }

  Uint8List _asBytes(dynamic raw, String error) {
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    throw Exception(error);
  }
}

NativeBridge createNativeBridge() => MethodChannelNativeBridge();
