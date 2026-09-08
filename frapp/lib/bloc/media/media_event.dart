import 'package:equatable/equatable.dart';
import '../../models/media_item.dart';

abstract class MediaEvent extends Equatable {
  const MediaEvent();
  
  @override
  List<Object?> get props => [];
}

class PickImageEvent extends MediaEvent {}

class CaptureImageEvent extends MediaEvent {}

class PickVideoEvent extends MediaEvent {}

class CaptureVideoEvent extends MediaEvent {}

class PickDocumentEvent extends MediaEvent {}

class ProcessMediaEvent extends MediaEvent {
  final MediaItem mediaItem;
  
  const ProcessMediaEvent(this.mediaItem);
  
  @override
  List<Object?> get props => [mediaItem];
}

class ClearMediaEvent extends MediaEvent {}

class ExtractFrameEvent extends MediaEvent {
  final MediaItem videoItem;
  final Duration position;
  
  const ExtractFrameEvent({
    required this.videoItem,
    required this.position,
  });
  
  @override
  List<Object?> get props => [videoItem, position];
}