import 'package:flutter_bloc/flutter_bloc.dart';

import 'ocr_event.dart';
import 'ocr_state.dart';
import '../../repositories/ocr_repository.dart';

class OCRBloc extends Bloc<OCREvent, OCRState> {
  OCRBloc(this._ocrRepository) : super(OCRInitial()) {
    on<PerformOCREvent>(_onPerformOCR);
    on<PerformOCROnImageBytesEvent>(_onPerformImage);
    on<ClearOCRResultEvent>(_onClearResult);
  }

  final OCRRepository _ocrRepository;

  Future<void> _onPerformOCR(
    PerformOCREvent event,
    Emitter<OCRState> emit,
  ) async {
    emit(OCRLoading());
    try {
      final result = await _ocrRepository.performOCR(
        event.media,
        language: event.language,
      );
      emit(OCRCompleted(
        result: result,
        imageBytes: result.previewBytes ?? event.media.bytes,
      ));
    } catch (e) {
      emit(OCRError(_friendlyError(e)));
    }
  }

  Future<void> _onPerformImage(
    PerformOCROnImageBytesEvent event,
    Emitter<OCRState> emit,
  ) async {
    emit(OCRLoading());
    try {
      final result = await _ocrRepository.performOCR(
        event.image,
        language: event.language,
      );
      emit(OCRCompleted(
        result: result,
        imageBytes: result.previewBytes ?? event.image.bytes,
      ));
    } catch (e) {
      emit(OCRError(_friendlyError(e)));
    }
  }

  void _onClearResult(
    ClearOCRResultEvent event,
    Emitter<OCRState> emit,
  ) {
    emit(OCRInitial());
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    return text;
  }
}
