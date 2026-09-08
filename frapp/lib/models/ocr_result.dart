import 'dart:typed_data';
import 'dart:ui';

import 'package:equatable/equatable.dart';

class OCRResult extends Equatable {
  final String text;
  final List<OCRWord> words;
  final String language;
  final double confidence;
  final Size? imageSize;
  final Uint8List? previewBytes;
  final Map<String, dynamic> metadata;

  const OCRResult({
    required this.text,
    this.words = const [],
    required this.language,
    this.confidence = 0.0,
    this.imageSize,
    this.previewBytes,
    this.metadata = const {},
  });

  bool get hasLayout =>
      imageSize != null &&
      words.any((word) => word.boundingBox.width > 0 && word.boundingBox.height > 0);

  @override
  List<Object?> get props => [text, words, language, confidence, imageSize];
}

class OCRWord extends Equatable {
  final String text;
  final Rect boundingBox;
  final double confidence;
  final String? language;

  const OCRWord({
    required this.text,
    this.boundingBox = Rect.zero,
    this.confidence = 0.0,
    this.language,
  });

  String get lookupKey => text.trim();

  @override
  List<Object?> get props => [text, boundingBox, confidence, language];
}
