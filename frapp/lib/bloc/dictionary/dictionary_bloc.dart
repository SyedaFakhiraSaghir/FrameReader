import 'package:flutter_bloc/flutter_bloc.dart';

import 'dictionary_event.dart';
import 'dictionary_state.dart';
import '../../repositories/dictionary_repository.dart';

class DictionaryBloc extends Bloc<DictionaryEvent, DictionaryState> {
  final DictionaryRepository _repository;
  
  DictionaryBloc(this._repository) : super(DictionaryInitial()) {
    on<LookupWordEvent>(_onLookupWord);
    on<AddToHistoryEvent>(_onAddToHistory);
    on<ClearHistoryEvent>(_onClearHistory);
  }
  
  Future<void> _onLookupWord(
    LookupWordEvent event,
    Emitter<DictionaryState> emit,
  ) async {
    emit(DictionaryLoading());
    try {
      final meaning = await _repository.getWordMeaning(
        event.word,
        sourceLanguage: event.sourceLanguage,
        targetLanguage: event.targetLanguage,
      );
      
      if (meaning.meaning.isNotEmpty) {
        emit(DictionaryWordFound(meaning));
      } else {
        emit(DictionaryWordNotFound(
          word: event.word,
          message: 'Word not found in dictionary',
        ));
      }
    } catch (e) {
      emit(DictionaryError(e.toString()));
    }
  }
  
  Future<void> _onAddToHistory(
    AddToHistoryEvent event,
    Emitter<DictionaryState> emit,
  ) async {
    try {
      await _repository.addToHistory(event.word, event.meaning);
      final history = await _repository.getHistory();
      emit(DictionaryHistoryLoaded(history));
    } catch (e) {
      emit(DictionaryError(e.toString()));
    }
  }
  
  Future<void> _onClearHistory(
    ClearHistoryEvent event,
    Emitter<DictionaryState> emit,
  ) async {
    try {
      await _repository.clearHistory();
      emit(DictionaryInitial());
    } catch (e) {
      emit(DictionaryError(e.toString()));
    }
  }
}