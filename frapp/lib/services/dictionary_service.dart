import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/word_meaning.dart';
import '../utils/constants.dart';
import '../utils/word_utils.dart';

class DictionaryService {
  DictionaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<WordMeaning> lookupWord(
    String word, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final cleaned = normalizeLookupWord(word);
    if (cleaned.isEmpty) {
      return WordMeaning(
        word: word,
        meaning: 'Select a word to look up its meaning.',
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    }

    final fromDictionary = await _lookupDictionaryApi(cleaned);
    final fromWiktionary =
        fromDictionary ?? await _lookupWiktionary(cleaned);

    final meaning = fromWiktionary ??
        WordMeaning(
          word: cleaned,
          meaning: 'Meaning not found',
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );

    final translationTarget =
        targetLanguage == sourceLanguage ? 'ur' : targetLanguage;
    String? translated;
    if (meaning.meaning != 'Meaning not found') {
      translated = await _translate(
        meaning.meaning,
        source: 'en',
        target: translationTarget,
      );
    }

    return WordMeaning(
      word: meaning.word.isEmpty ? cleaned : meaning.word,
      meaning: meaning.meaning,
      partOfSpeech: meaning.partOfSpeech,
      pronunciation: meaning.pronunciation,
      synonyms: meaning.synonyms,
      antonyms: meaning.antonyms,
      translations: {
        ...meaning.translations,
        if (translated != null) translationTarget: translated,
      },
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }

  Future<WordMeaning?> _lookupDictionaryApi(String word) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.dictionaryApiUrl}/en/$word'),
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! List || data.isEmpty) return null;
      final entry = data.first;
      if (entry is! Map<String, dynamic>) return null;

      final meanings = entry['meanings'] as List? ?? const [];
      if (meanings.isEmpty) return null;
      final firstMeaning = meanings.first as Map<String, dynamic>;
      final definitions = firstMeaning['definitions'] as List? ?? const [];
      if (definitions.isEmpty) return null;
      final definition = definitions.first as Map<String, dynamic>;

      final extraMeanings = meanings.skip(1).take(2).map((item) {
        if (item is! Map) return null;
        final defs = item['definitions'] as List? ?? const [];
        if (defs.isEmpty || defs.first is! Map) return null;
        return (defs.first as Map)['definition']?.toString();
      }).whereType<String>();

      final primary = definition['definition']?.toString() ?? '';
      final combined = [primary, ...extraMeanings]
          .where((item) => item.trim().isNotEmpty)
          .join('\n\n');

      return WordMeaning(
        word: entry['word']?.toString() ?? word,
        meaning: combined.isEmpty ? 'Meaning not found' : combined,
        partOfSpeech: firstMeaning['partOfSpeech']?.toString(),
        pronunciation: entry['phonetic']?.toString(),
        synonyms: _stringList(firstMeaning['synonyms']),
        antonyms: _stringList(firstMeaning['antonyms']),
        sourceLanguage: 'en',
        targetLanguage: 'en',
      );
    } catch (_) {
      return null;
    }
  }

  Future<WordMeaning?> _lookupWiktionary(String word) async {
    try {
      final uri = Uri.parse(
        'https://en.wiktionary.org/api/rest_v1/page/definition/${Uri.encodeComponent(word)}',
      );
      final response = await _client.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'FrameReader/1.0 (OCR dictionary lookup)',
        },
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;
      final english = data['en'];
      if (english is! List || english.isEmpty) return null;

      String? partOfSpeech;
      final buffer = StringBuffer();
      for (final item in english.take(3)) {
        if (item is! Map) continue;
        partOfSpeech ??= item['partOfSpeech']?.toString();
        final definitions = item['definitions'];
        if (definitions is! List) continue;
        for (final definition in definitions.take(2)) {
          if (definition is! Map) continue;
          final text = _stripHtml(definition['definition']?.toString() ?? '');
          if (text.isEmpty) continue;
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(text);
        }
      }
      if (buffer.isEmpty) return null;
      return WordMeaning(
        word: word,
        meaning: buffer.toString(),
        partOfSpeech: partOfSpeech,
        sourceLanguage: 'en',
        targetLanguage: 'en',
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _translate(
    String text, {
    required String source,
    required String target,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.translationApiUrl).replace(
        queryParameters: {
          'q': text.length > 500 ? text.substring(0, 500) : text,
          'langpair': '$source|$target',
        },
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map) return null;
      final translated = data['responseData']?['translatedText']?.toString();
      if (translated == null || translated.trim().isEmpty) return null;
      return translated;
    } catch (_) {
      return null;
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
