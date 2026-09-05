import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'media_event.dart';
import 'media_state.dart';
import '../../repositories/media_repository.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final MediaRepository _repository;
  
  MediaBloc(this._repository) : super(MediaInitial()) {
    on<PickImageEvent>(_onPickImage);
    on<PickVideoEvent>(_onPickVideo);
    on<PickDocumentEvent>(_onPickDocument);
    on<ProcessMediaEvent>(_onProcessMedia);
    on<ClearMediaEvent>(_onClearMedia);
    on<ExtractFrameEvent>(_onExtractFrame);
  }
  
  Future<void> _onPickImage(
    PickImageEvent event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    try {
      final media = await _repository.pickImage();
      if (media != null) {
        emit(MediaLoaded(currentMedia: media));
      } else {
        emit(const MediaError('No image selected'));
      }
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }
  
  Future<void> _onPickVideo(
    PickVideoEvent event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    try {
      final media = await _repository.pickVideo();
      if (media != null) {
        emit(MediaLoaded(currentMedia: media));
      } else {
        emit(const MediaError('No video selected'));
      }
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }
  
  Future<void> _onPickDocument(
    PickDocumentEvent event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    try {
      final media = await _repository.pickDocument();
      if (media != null) {
        emit(MediaLoaded(currentMedia: media));
      } else {
        emit(const MediaError('No document selected'));
      }
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }
  
  Future<void> _onProcessMedia(
    ProcessMediaEvent event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    try {
      final processedPath = await _repository.processMedia(event.mediaItem);
      emit(MediaProcessed(
        mediaItem: event.mediaItem,
        processedPath: processedPath,
      ));
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }
  
  Future<void> _onClearMedia(
    ClearMediaEvent event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaInitial());
  }
  
  Future<void> _onExtractFrame(
    ExtractFrameEvent event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    try {
      final framePath = await _repository.extractFrame(
        event.videoItem,
        event.position,
      );
      if (state is MediaLoaded) {
        final currentState = state as MediaLoaded;
        emit(MediaLoaded(
          currentMedia: currentState.currentMedia,
          mediaHistory: currentState.mediaHistory,
          extractedFramePath: framePath,
        ));
      }
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }
}