import 'package:equatable/equatable.dart';

import '../../models/media_item.dart';

abstract class OCREvent extends Equatable {
  const OCREvent();

  @override
  List<Object?> get props => [];
}

class PerformOCREvent extends OCREvent {
  final MediaItem media;
  final String? language;

  const PerformOCREvent({
    required this.media,
    this.language,
  });

  @override
  List<Object?> get props => [media, language];
}

class PerformOCROnImageBytesEvent extends OCREvent {
  final MediaItem image;
  final String? language;

  const PerformOCROnImageBytesEvent({
    required this.image,
    this.language,
  });

  @override
  List<Object?> get props => [image, language];
}

class ClearOCRResultEvent extends OCREvent {}
