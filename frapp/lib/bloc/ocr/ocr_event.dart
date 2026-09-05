import 'package:equatable/equatable.dart';
import '../../models/media_item.dart';

abstract class OCREvent extends Equatable {
  const OCREvent();
  
  @override
  List<Object?> get props => [];
}

class PerformOCREvent extends OCREvent {
  final String imagePath;
  final String? language;
  
  const PerformOCREvent({
    required this.imagePath,
    this.language,
  });
  
  @override
  List<Object?> get props => [imagePath, language];
}

class SelectWordEvent extends OCREvent {
  final String word;
  final String sourceLanguage;
  final String targetLanguage;
  
  const SelectWordEvent({
    required this.word,
    required this.sourceLanguage,
    required this.targetLanguage,
  });
  
  @override
  List<Object?> get props => [word, sourceLanguage, targetLanguage];
}

class ClearOCRResultEvent extends OCREvent {}