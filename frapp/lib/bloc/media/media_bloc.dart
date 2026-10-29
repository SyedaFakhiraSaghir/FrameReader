import 'package:flutter_bloc/flutter_bloc.dart';

import 'media_event.dart';
import 'media_state.dart';
import '../../repositories/media_repository.dart';
import '../../models/media_item.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  MediaBloc(this._repository) : super(MediaInitial()) {
    on<PickImageEvent>(_onPickImage);
    on<CaptureImageEvent>(_onCaptureImage);
    on<PickVideoEvent>(_onPickVideo);
    on<CaptureVideoEvent>(_onCaptureVideo);
    on<PickDocumentEvent>(_onPickDocument);
    on<ProcessMediaEvent>(_onProcessMedia);
    on<ClearMediaEvent>(_onClearMedia);
    on<ExtractFrameEvent>(_onExtractFrame);
  }

  final MediaRepository _repository;
  int _requestId = 0;

  Future<void> _onPickImage(
    PickImageEvent event,
    Emitter<MediaState> emit,
  ) async {
    await _load(_repository.pickImage, emit);
  }

  Future<void> _onPickVideo(
    PickVideoEvent event,
    Emitter<MediaState> emit,
  ) async {
    await _load(_repository.pickVideo, emit);
  }

  Future<void> _onPickDocument(
    PickDocumentEvent event,
    Emitter<MediaState> emit,
  ) async {
    await _load(_repository.pickDocument, emit);
  }

  Future<void> _onCaptureImage(
    CaptureImageEvent event,
    Emitter<MediaState> emit,
  ) async {
    await _load(_repository.captureImage, emit);
  }

  Future<void> _onCaptureVideo(
    CaptureVideoEvent event,
    Emitter<MediaState> emit,
  ) async {
    await _load(_repository.captureVideo, emit);
  }

  Future<void> _load(
    Future<MediaItem?> Function() picker,
    Emitter<MediaState> emit,
  ) async {
    final requestId = ++_requestId;
    emit(MediaLoading());
    try {
      final media = await picker();
      if (requestId != _requestId || emit.isDone) return;
      if (media == null) {
        emit(MediaInitial());
      } else {
        emit(MediaLoaded(currentMedia: media));
      }
    } on Object catch (error) {
      if (requestId != _requestId || emit.isDone) return;
      emit(MediaError(error.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onProcessMedia(
    ProcessMediaEvent event,
    Emitter<MediaState> emit,
  ) async {
    final requestId = ++_requestId;
    emit(MediaLoading());
    try {
      final processedPath = await _repository.processMedia(event.mediaItem);
      if (requestId != _requestId || emit.isDone) return;
      emit(MediaProcessed(
        mediaItem: event.mediaItem,
        processedPath: processedPath,
      ));
    } on Object catch (error) {
      if (requestId != _requestId || emit.isDone) return;
      emit(MediaError(error.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onClearMedia(
    ClearMediaEvent event,
    Emitter<MediaState> emit,
  ) async {
    _requestId++;
    emit(MediaInitial());
  }

  Future<void> _onExtractFrame(
    ExtractFrameEvent event,
    Emitter<MediaState> emit,
  ) async {
    final requestId = ++_requestId;
    final previous = state;
    final current = previous is MediaLoaded
        ? previous
        : MediaLoaded(currentMedia: event.videoItem);
    try {
      emit(MediaLoaded(
        currentMedia: current.currentMedia ?? event.videoItem,
        mediaHistory: current.mediaHistory,
        extractedFrame: current.extractedFrame,
        isExtractingFrame: true,
      ));
      final frame = await _repository.extractFrame(
        event.videoItem,
        event.position,
      );
      if (requestId != _requestId || emit.isDone) return;
      emit(MediaLoaded(
        currentMedia: current.currentMedia ?? event.videoItem,
        mediaHistory: current.mediaHistory,
        extractedFrame: frame,
      ));
    } on Object catch (error) {
      if (requestId != _requestId || emit.isDone) return;
      emit(MediaError(error.toString().replaceFirst('Exception: ', '')));
    }
  }
}
