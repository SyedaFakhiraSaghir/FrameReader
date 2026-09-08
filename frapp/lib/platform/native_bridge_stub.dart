import 'dart:typed_data';

import '../models/ocr_result.dart';

abstract class NativeBridge {
  Future<OCRResult> recognizeText(Uint8List bytes, {String? language});

  Future<Uint8List> extractVideoFrame(String path, Duration position);

  Future<Uint8List> renderPdfPage(Uint8List bytes, {int pageIndex = 0});
}

class UnsupportedNativeBridge implements NativeBridge {
  const UnsupportedNativeBridge();

  @override
  Future<OCRResult> recognizeText(Uint8List bytes, {String? language}) {
    throw UnsupportedError('Native OCR is not available on this platform.');
  }

  @override
  Future<Uint8List> extractVideoFrame(String path, Duration position) {
    throw UnsupportedError('Frame extraction is not available on this platform.');
  }

  @override
  Future<Uint8List> renderPdfPage(Uint8List bytes, {int pageIndex = 0}) {
    throw UnsupportedError('PDF rendering is not available on this platform.');
  }
}

NativeBridge createNativeBridge() => const UnsupportedNativeBridge();
