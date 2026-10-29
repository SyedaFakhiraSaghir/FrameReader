import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_translator_app/models/media_item.dart';
import 'package:ocr_translator_app/models/ocr_result.dart';
import 'package:ocr_translator_app/platform/native_bridge.dart';
import 'package:ocr_translator_app/services/ocr_service.dart';

void main() {
  group('OCRService document parsing', () {
    test('extracts readable DOCX text and paragraph breaks', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'word/document.xml',
            '<w:document><w:p><w:r><w:t>Hello &amp; welcome</w:t></w:r></w:p>'
                '<w:p><w:r><w:t>Second paragraph</w:t></w:r></w:p></w:document>',
          ),
        );
      final bytes = ZipEncoder().encodeBytes(archive);
      final service = OCRService(nativeBridge: _FakeNativeBridge());

      final result = await service.extractFromMedia(
        _document('sample.docx', Uint8List.fromList(bytes)),
      );

      expect(result.text, 'Hello & welcome\nSecond paragraph');
      expect(result.words.map((word) => word.text), contains('welcome'));
    });

    test('runs OCR for every PDF page', () async {
      final bridge = _FakeNativeBridge(pageCount: 2);
      final service = OCRService(nativeBridge: bridge);

      final result = await service.extractFromMedia(
        _document('sample.pdf', Uint8List.fromList([1, 2, 3])),
      );

      expect(result.text, 'page 1\n\npage 2');
      expect(result.metadata['pageCount'], 2);
      expect(bridge.renderedPages, [0, 1]);
      expect(result.previewBytes, [1]);
    });
  });
}

MediaItem _document(String name, Uint8List bytes) {
  return MediaItem(
    id: 'test',
    bytes: bytes,
    fileName: name,
    type: MediaType.document,
    createdAt: DateTime.utc(2025),
  );
}

class _FakeNativeBridge implements NativeBridge {
  _FakeNativeBridge({this.pageCount = 1});

  final int pageCount;
  final List<int> renderedPages = [];

  @override
  Future<OCRResult> recognizeText(Uint8List bytes, {String? language}) async {
    final number = bytes.single;
    return OCRResult(
      text: 'page $number',
      language: language ?? 'en',
    );
  }

  @override
  Future<Uint8List> extractVideoFrame(String path, Duration position) {
    throw UnimplementedError();
  }

  @override
  Future<int> pdfPageCount(Uint8List bytes) async => pageCount;

  @override
  Future<Uint8List> renderPdfPage(Uint8List bytes, {int pageIndex = 0}) async {
    renderedPages.add(pageIndex);
    return Uint8List.fromList([pageIndex + 1]);
  }
}
