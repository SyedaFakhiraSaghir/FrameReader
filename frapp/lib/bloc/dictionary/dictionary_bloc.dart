import 'package:flutter_bloc/flutter_bloc.dart';

import 'dictionary_event.dart';
import 'dictionary_state.dart';
import '../../repositories/dictionary_repository.dart';

class DictionaryBloc extends Bloc<DictionaryEvent, DictionaryState> {
  DictionaryBloc(this._repository) : super(DictionaryInitial()) {
    on<LookupWordEvent>(_onLookupWord);
    on<AddToHistoryEvent>(_onAddToHistory);
    on<ClearHistoryEvent>(_onClearHistory);
  }

  final DictionaryRepository _repository;
  int _lookupRequestId = 0;

  Future<void> _onLookupWord(
    LookupWordEvent event,
    Emitter<DictionaryState> emit,
  ) async {
    final requestId = ++_lookupRequestId;
    emit(DictionaryLoading());
    try {
      final meaning = await _repository.getWordMeaning(
        event.word,
        sourceLanguage: event.sourceLanguage,
        targetLanguage: event.targetLanguage,
      );
      if (requestId != _lookupRequestId || emit.isDone) return;
      if (meaning.meaning.isNotEmpty) {
        emit(DictionaryWordFound(meaning));
      } else {
        emit(DictionaryWordNotFound(
          word: event.word,
          message: 'Word not found in dictionary',
        ));
      }
    } on Object catch (error) {
      if (requestId != _lookupRequestId || emit.isDone) return;
      emit(DictionaryError(error.toString().replaceFirst('Exception: ', '')));
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
