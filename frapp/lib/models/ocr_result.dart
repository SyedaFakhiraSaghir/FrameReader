import 'package:equatable/equatable.dart';

class OCRResult extends Equatable {
  final String text;
  final List<OCRWord> words;
  final String language;
  final double confidence;
  final Map<String, dynamic> metadata;
  
  const OCRResult({
    required this.text,
    this.words = const [],
    required this.language,
    required this.confidence,
    this.metadata = const {},
  });
  
  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      text: json['text'] ?? '',
      words: (json['words'] as List? ?? [])
          .map((w) => OCRWord.fromJson(w))
          .toList(),
      language: json['language'] ?? 'en',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'words': words.map((w) => w.toJson()).toList(),
      'language': language,
      'confidence': confidence,
      'metadata': metadata,
    };
  }
  
  @override
  List<Object?> get props => [text, words, language, confidence];
}

class OCRWord extends Equatable {
  final String text;
  final Rect boundingBox;
  final double confidence;
  final String? language;
  
  const OCRWord({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    this.language,
  });
  
  factory OCRWord.fromJson(Map<String, dynamic> json) {
    return OCRWord(
      text: json['text'] ?? '',
      boundingBox: Rect.fromLTWH(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
        (json['width'] as num?)?.toDouble() ?? 0,
        (json['height'] as num?)?.toDouble() ?? 0,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      language: json['language'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'x': boundingBox.left,
      'y': boundingBox.top,
      'width': boundingBox.width,
      'height': boundingBox.height,
      'confidence': confidence,
      'language': language,
    };
  }
  
  @override
  List<Object?> get props => [text, boundingBox, confidence, language];
}