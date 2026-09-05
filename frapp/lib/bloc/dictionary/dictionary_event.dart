import 'package:equatable/equatable.dart';

abstract class DictionaryEvent extends Equatable {
  const DictionaryEvent();
  
  @override
  List<Object?> get props => [];
}

class LookupWordEvent extends DictionaryEvent {
  final String word;
  final String sourceLanguage;
  final String targetLanguage;
  
  const LookupWordEvent({
    required this.word,
    required this.sourceLanguage,
    required this.targetLanguage,
  });
  
  @override
  List<Object?> get props => [word, sourceLanguage, targetLanguage];
}

class AddToHistoryEvent extends DictionaryEvent {
  final String word;
  final String meaning;
  
  const AddToHistoryEvent({
    required this.word,
    required this.meaning,
  });
  
  @override
  List<Object?> get props => [word, meaning];
}

class ClearHistoryEvent extends DictionaryEvent {}