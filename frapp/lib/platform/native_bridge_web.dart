import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui';

import '../models/ocr_result.dart';
import 'native_bridge_stub.dart';

export 'native_bridge_stub.dart' show NativeBridge;

class WebNativeBridge implements NativeBridge {
  JSObject get _api {
    final api = globalContext.getProperty('frameReaderNative'.toJS);
    if (api.isUndefined || api.isNull) {
      throw Exception(
        'Web OCR helpers failed to load. Refresh the page and try again.',
      );
    }
    return api as JSObject;
  }

  @override
  Future<OCRResult> recognizeText(Uint8List bytes, {String? language}) async {
    final promise = _api.callMethod(
      'recognizeText'.toJS,
      bytes.toJS,
      (language ?? 'en').toJS,
    ) as JSPromise;
    final raw = (await promise.toDart) as JSObject;
    return _parseOcr(raw, language ?? 'en');
  }

  @override
  Future<Uint8List> extractVideoFrame(String path, Duration position) async {
    final promise = _api.callMethod(
      'extractVideoFrame'.toJS,
      path.toJS,
      position.inMilliseconds.toJS,
    ) as JSPromise;
    final raw = await promise.toDart;
    return _jsBytes(raw, 'The video frame could not be extracted.');
  }

  @override
  Future<Uint8List> renderPdfPage(Uint8List bytes, {int pageIndex = 0}) async {
    final promise = _api.callMethod(
      'renderPdfPage'.toJS,
      bytes.toJS,
      pageIndex.toJS,
    ) as JSPromise;
    final raw = await promise.toDart;
    return _jsBytes(raw, 'The PDF page could not be rendered.');
  }

  @override
  Future<int> pdfPageCount(Uint8List bytes) async {
    final promise = _api.callMethod(
      'pdfPageCount'.toJS,
      bytes.toJS,
    ) as JSPromise;
    final count = (await promise.toDart).dartify();
    if (count is! num || count < 1) {
      throw StateError('The PDF does not contain any readable pages.');
    }
    return count.toInt();
  }

  OCRResult _parseOcr(JSObject raw, String language) {
    final text = raw.getProperty('text'.toJS).dartify()?.toString() ?? '';
    final wordsRaw = raw.getProperty('words'.toJS).dartify();
    final imageWidth =
        (raw.getProperty('imageWidth'.toJS).dartify() as num?)?.toDouble();
    final imageHeight =
        (raw.getProperty('imageHeight'.toJS).dartify() as num?)?.toDouble();

    final words = <OCRWord>[];
    if (wordsRaw is List) {
      for (final item in wordsRaw) {
        if (item is! Map) continue;
        words.add(
          OCRWord(
            text: item['text']?.toString() ?? '',
            boundingBox: Rect.fromLTWH(
              (item['x'] as num?)?.toDouble() ?? 0,
              (item['y'] as num?)?.toDouble() ?? 0,
              (item['width'] as num?)?.toDouble() ?? 0,
              (item['height'] as num?)?.toDouble() ?? 0,
            ),
            confidence: (item['confidence'] as num?)?.toDouble() ?? 0,
            language: language,
          ),
        );
      }
    }

    return OCRResult(
      text: text.trim(),
      words: words,
      language: language,
      confidence: words.isEmpty
          ? 0.0
          : words.map((word) => word.confidence).reduce((a, b) => a + b) /
              words.length,
      imageSize: imageWidth != null && imageHeight != null
          ? Size(imageWidth, imageHeight)
          : null,
    );
  }

  Uint8List _jsBytes(JSAny? raw, String error) {
    final dartified = raw.dartify();
    if (dartified is Uint8List) return dartified;
    if (dartified is List) {
      return Uint8List.fromList(dartified.whereType<int>().toList());
    }
    throw Exception(error);
  }
}

NativeBridge createNativeBridge() => WebNativeBridge();
