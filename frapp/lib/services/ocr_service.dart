import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/media_item.dart';
import '../models/ocr_result.dart';
import '../platform/io_support.dart';
import '../platform/native_bridge.dart';
import '../utils/word_utils.dart';

class OCRService {
  OCRService({NativeBridge? nativeBridge})
      : _nativeBridge = nativeBridge ?? createNativeBridge();

  final NativeBridge _nativeBridge;

  Future<OCRResult> extractFromMedia(
    MediaItem media, {
    String? language,
  }) async {
    switch (media.type) {
      case MediaType.image:
        final bytes = await _bytesFor(media);
        final result = await extractFromImageBytes(bytes, language: language);
        return result._withPreview(bytes);
      case MediaType.document:
        return extractFromDocument(media, language: language);
      case MediaType.video:
        throw Exception('Extract a video frame before running OCR.');
    }
  }

  Future<OCRResult> extractFromImageBytes(
    Uint8List bytes, {
    String? language,
  }) {
    return _nativeBridge.recognizeText(bytes, language: language);
  }

  Future<OCRResult> extractFromDocument(
    MediaItem media, {
    String? language,
  }) async {
    final bytes = await _bytesFor(media);
    switch (media.extension) {
      case 'txt':
      case 'rtf':
        return extractFromPlainText(
          utf8.decode(bytes, allowMalformed: true),
          language: language,
        );
      case 'docx':
        return extractFromPlainText(_docxToText(bytes), language: language);
      case 'pdf':
        final pageCount = await _nativeBridge.pdfPageCount(bytes);
        if (pageCount < 1) {
          throw Exception('The PDF does not contain any readable pages.');
        }
        final pageResults = <OCRResult>[];
        Uint8List? previewBytes;
        for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
          final page = await _nativeBridge.renderPdfPage(
            bytes,
            pageIndex: pageIndex,
          );
          previewBytes ??= page;
          pageResults.add(
            await extractFromImageBytes(page, language: language),
          );
        }

        final words = pageResults.expand((result) => result.words).toList();
        final wordCount = words.length;
        final confidence = wordCount == 0
            ? 0.0
            : words.fold<double>(0, (total, word) => total + word.confidence) /
                wordCount;
        return OCRResult(
          text: pageResults
              .map((result) => result.text.trim())
              .where((text) => text.isNotEmpty)
              .join('\n\n'),
          words: words,
          language: language ?? 'en',
          confidence: confidence,
          imageSize: pageResults.first.imageSize,
          previewBytes: previewBytes,
          metadata: {'pageCount': pageCount},
        );
      default:
        throw Exception(
          'OCR supports PDF, DOCX, and TXT documents. Convert .doc files to PDF or DOCX first.',
        );
    }
  }

  OCRResult extractFromPlainText(String text, {String? language}) {
    final words = tokenizeWords(text)
        .map((word) => OCRWord(text: word, language: language ?? 'en'))
        .toList();
    return OCRResult(
      text: text.trim(),
      words: words,
      language: language ?? 'en',
      confidence: words.isEmpty ? 0 : 1,
    );
  }

  Future<Uint8List> extractVideoFrame(MediaItem video, Duration position) {
    final path = video.objectUrl ?? video.path;
    if (path == null || path.isEmpty) {
      throw Exception('The video file is not available for frame extraction.');
    }
    return _nativeBridge.extractVideoFrame(path, position);
  }

  Future<Uint8List> _bytesFor(MediaItem media) async {
    if (media.bytes != null && media.bytes!.isNotEmpty) {
      return media.bytes!;
    }
    if (media.path != null && hasFileSystem) {
      return readFileBytes(media.path!);
    }
    throw Exception('The selected file could not be read.');
  }

  String _docxToText(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final file = archive.findFile('word/document.xml');
    if (file == null) {
      throw Exception('The DOCX file did not contain readable text.');
    }
    final xml = utf8.decode(file.content, allowMalformed: true);
    final text = xml
        .replaceAll(RegExp(r'<w:tab[^>]*/>'), '\t')
        .replaceAll(RegExp(r'<w:br[^>]*/>'), '\n')
        .replaceAll(RegExp(r'</w:p>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (text.isEmpty) {
      throw Exception('The DOCX file did not contain readable text.');
    }
    return text;
  }

  void dispose() {}
}

extension on OCRResult {
  OCRResult _withPreview(Uint8List bytes) {
    return OCRResult(
      text: text,
      words: words,
      language: language,
      confidence: confidence,
      imageSize: imageSize,
      previewBytes: bytes,
      metadata: metadata,
    );
  }
}
