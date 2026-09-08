import '../models/media_item.dart';
import '../models/ocr_result.dart';
import '../services/ocr_service.dart';

class OCRRepository {
  OCRRepository([OCRService? ocrService])
      : _ocrService = ocrService ?? OCRService();

  final OCRService _ocrService;

  Future<OCRResult> performOCR(
    MediaItem media, {
    String? language,
  }) {
    return _ocrService.extractFromMedia(media, language: language);
  }
}
