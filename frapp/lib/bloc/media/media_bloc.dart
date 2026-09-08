import 'package:flutter_bloc/flutter_bloc.dart';

import 'media_event.dart';
import 'media_state.dart';
import '../../repositories/media_repository.dart';
import '../../services/ocr_service.dart';
import '../../services/service_locator.dart';

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
    Future<dynamic> Function() picker,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    try {
      final media = await picker();
      if (media == null) {
        emit(MediaInitial());
      } else {
        emit(MediaLoaded(currentMedia: media));
      }
    } catch (e) {
      emit(MediaError(e.toString().replaceFirst('Exception: ', '')));
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
      emit(MediaError(e.toString().replaceFirst('Exception: ', '')));
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
    final current = state is MediaLoaded
        ? state as MediaLoaded
        : MediaLoaded(currentMedia: event.videoItem);
    try {
      emit(MediaLoaded(
        currentMedia: current.currentMedia ?? event.videoItem,
        mediaHistory: current.mediaHistory,
        isExtractingFrame: true,
      ));
      final frameBytes = await getIt<OCRService>().extractVideoFrame(
        event.videoItem,
        event.position,
      );
      final frame = await _repository.saveImageBytes(
        frameBytes,
        name: 'frame_${event.position.inMilliseconds}.jpg',
      );
      emit(MediaLoaded(
        currentMedia: current.currentMedia ?? event.videoItem,
        mediaHistory: current.mediaHistory,
        extractedFrame: frame,
      ));
    } catch (e) {
      emit(MediaError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
