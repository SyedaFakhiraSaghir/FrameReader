import 'package:equatable/equatable.dart';

class WordMeaning extends Equatable {
  final String word;
  final String meaning;
  final String? partOfSpeech;
  final String? pronunciation;
  final List<String> synonyms;
  final List<String> antonyms;
  final Map<String, String> translations;
  final String? translationError;
  final String sourceLanguage;
  final String targetLanguage;

  const WordMeaning({
    required this.word,
    required this.meaning,
    this.partOfSpeech,
    this.pronunciation,
    this.synonyms = const [],
    this.antonyms = const [],
    this.translations = const {},
    this.translationError,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  factory WordMeaning.fromJson(Map<String, dynamic> json) {
    return WordMeaning(
      word: json['word'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String?,
      pronunciation: json['pronunciation'] as String?,
      synonyms: _stringList(json['synonyms']),
      antonyms: _stringList(json['antonyms']),
      translations: _stringMap(json['translations']),
      translationError: json['translationError'] as String?,
      sourceLanguage: json['sourceLanguage'] as String? ?? 'en',
      targetLanguage: json['targetLanguage'] as String? ?? 'ur',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'meaning': meaning,
      'partOfSpeech': partOfSpeech,
      'pronunciation': pronunciation,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'translations': translations,
      'translationError': translationError,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, item) => MapEntry(key.toString(), item.toString()),
    );
  }

  @override
  List<Object?> get props => [
        word,
        meaning,
        partOfSpeech,
        pronunciation,
        synonyms,
        antonyms,
        translations,
        translationError,
        sourceLanguage,
        targetLanguage,
      ];
}
