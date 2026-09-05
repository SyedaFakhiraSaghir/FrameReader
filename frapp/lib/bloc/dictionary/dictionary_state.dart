import 'package:equatable/equatable.dart';
import '../../models/word_meaning.dart';

abstract class DictionaryState extends Equatable {
  const DictionaryState();
  
  @override
  List<Object?> get props => [];
}

class DictionaryInitial extends DictionaryState {}

class DictionaryLoading extends DictionaryState {}

class DictionaryWordFound extends DictionaryState {
  final WordMeaning wordMeaning;
  
  const DictionaryWordFound(this.wordMeaning);
  
  @override
  List<Object?> get props => [wordMeaning];
}

class DictionaryWordNotFound extends DictionaryState {
  final String word;
  final String message;
  
  const DictionaryWordNotFound({
    required this.word,
    required this.message,
  });
  
  @override
  List<Object?> get props => [word, message];
}

class DictionaryHistoryLoaded extends DictionaryState {
  final List<WordMeaning> history;
  
  const DictionaryHistoryLoaded(this.history);
  
  @override
  List<Object?> get props => [history];
}

class DictionaryError extends DictionaryState {
  final String message;
  
  const DictionaryError(this.message);
  
  @override
  List<Object?> get props => [message];
}c 