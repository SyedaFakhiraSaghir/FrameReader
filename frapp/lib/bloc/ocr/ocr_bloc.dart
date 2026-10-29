import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/media_item.dart';
import '../../repositories/ocr_repository.dart';
import 'ocr_event.dart';
import 'ocr_state.dart';

class OCRBloc extends Bloc<OCREvent, OCRState> {
  OCRBloc(this._ocrRepository) : super(OCRInitial()) {
    on<PerformOCREvent>(_onPerformOCR);
    on<PerformOCROnImageBytesEvent>(_onPerformImage);
    on<ClearOCRResultEvent>(_onClearResult);
  }

  final OCRRepository _ocrRepository;
  int _requestId = 0;

  Future<void> _onPerformOCR(
    PerformOCREvent event,
    Emitter<OCRState> emit,
  ) async {
    await _runOCR(event.media, event.language, emit);
  }

  Future<void> _onPerformImage(
    PerformOCROnImageBytesEvent event,
    Emitter<OCRState> emit,
  ) async {
    await _runOCR(event.image, event.language, emit);
  }

  Future<void> _runOCR(
    MediaItem media,
    String? language,
    Emitter<OCRState> emit,
  ) async {
    final requestId = ++_requestId;
    emit(OCRLoading());
    try {
      final result = await _ocrRepository.performOCR(
        media,
        language: language,
      );
      if (requestId != _requestId || emit.isDone) return;
      emit(OCRCompleted(
        result: result,
        imageBytes: result.previewBytes ?? media.bytes,
      ));
    } on Object catch (error) {
      if (requestId != _requestId || emit.isDone) return;
      emit(OCRError(_friendlyError(error)));
    }
  }

  void _onClearResult(
    ClearOCRResultEvent event,
    Emitter<OCRState> emit,
  ) {
    _requestId++;
    emit(OCRInitial());
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    return text;
  }
}
