import 'package:equatable/equatable.dart';
import '../../models/media_item.dart';

abstract class MediaState extends Equatable {
  const MediaState();
  
  @override
  List<Object?> get props => [];
}

class MediaInitial extends MediaState {}

class MediaLoading extends MediaState {}

class MediaLoaded extends MediaState {
  final MediaItem? currentMedia;
  final List<MediaItem> mediaHistory;
  final String? extractedFramePath;
  
  const MediaLoaded({
    this.currentMedia,
    this.mediaHistory = const [],
    this.extractedFramePath,
  });
  
  @override
  List<Object?> get props => [currentMedia, mediaHistory, extractedFramePath];
}

class MediaProcessed extends MediaState {
  final MediaItem mediaItem;
  final String processedPath;
  
  const MediaProcessed({
    required this.mediaItem,
    required this.processedPath,
  });
  
  @override
  List<Object?> get props => [mediaItem, processedPath];
}

class MediaError extends MediaState {
  final String message;
  
  const MediaError(this.message);
  
  @override
  List<Object?> get props => [message];
}