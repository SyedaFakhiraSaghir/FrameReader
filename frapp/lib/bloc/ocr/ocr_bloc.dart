import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'ocr_event.dart';
import 'ocr_state.dart';
import '../../repositories/ocr_repository.dart';
import '../../repositories/dictionary_repository.dart';
import '../../models/word_meaning.dart';

class OCRBloc extends Bloc<OCREvent, OCRState> {
  final OCRRepository _ocrRepository;
  final DictionaryRepository _dictionaryRepository;
  
  OCRBloc(this._ocrRepository) 
    : _dictionaryRepository = getIt<DictionaryRepository>(),
      super(OCRInitial()) {
    on<PerformOCREvent>(_onPerformOCR);
    on<SelectWordEvent>(_onSelectWord);
    on<ClearOCRResultEvent>(_onClearResult);
  }
  
  Future<void> _onPerformOCR(
    PerformOCREvent event,
    Emitter<OCRState> emit,
  ) async {
    emit(OCRLoading());
    try {
      final ocrResult = await _ocrRepository.performOCR(
        event.imagePath,
        language: event.language,
      );
      
      // Get meanings for all words
      final wordMeanings = await _getWordMeanings(ocrResult);
      
      emit(OCRCompleted(
        result: ocrResult,
        wordMeanings: wordMeanings,
      ));
    } catch (e) {
      emit(OCRError(e.toString()));
    }
  }
  
  Future<void> _onSelectWord(
    SelectWordEvent event,
    Emitter<OCRState> emit,
  ) async {
    if (state is OCRCompleted) {
      try {
        final meaning = await _dictionaryRepository.getWordMeaning(
          event.word,
          sourceLanguage: event.sourceLanguage,
          targetLanguage: event.targetLanguage,
        );
        
        final currentState = state as OCRCompleted;
        emit(OCRCompleted(
          result: currentState.result,
          wordMeanings: currentState.wordMeanings,
          selectedWord: meaning,
        ));
      } catch (e) {
        emit(OCRError(e.toString()));
      }
    }
  }
  
  Future<List<WordMeaning>> _getWordMeanings(OCRResult result) async {
    final meanings = <WordMeaning>[];
    final words = result.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    
    for (final word in words.take(10)) { // Limit to 10 words for performance
      try {
        final meaning = await _dictionaryRepository.getWordMeaning(
          word,
          sourceLanguage: result.language,
          targetLanguage: 'ur',
        );
        meanings.add(meaning);
      } catch (e) {
        // Skip words that can't be translated
        continue;
      }
    }
    
    return meanings;
  }
  
  void _onClearResult(
    ClearOCRResultEvent event,
    Emitter<OCRState> emit,
  ) {
    emit(OCRInitial());
  }
}