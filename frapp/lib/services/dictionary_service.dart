import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/word_meaning.dart';
import '../utils/constants.dart';
import '../utils/word_utils.dart';

class DictionaryServiceException implements Exception {
  const DictionaryServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DictionaryService {
  DictionaryService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration requestTimeout;

  Future<WordMeaning> lookupWord(
    String word, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final cleaned = normalizeLookupWord(word);
    if (cleaned.isEmpty) {
      throw const DictionaryServiceException('Select a word to look up.');
    }

    WordMeaning? definition;
    Object? dictionaryFailure;
    try {
      definition = await _lookupDictionaryApi(cleaned);
    } on Object catch (error) {
      dictionaryFailure = error;
    }

    if (definition == null) {
      try {
        definition = await _lookupWiktionary(cleaned);
      } on Object catch (error) {
        if (dictionaryFailure != null) {
          throw DictionaryServiceException(
            'Dictionary services are unavailable. '
            'Free Dictionary: $dictionaryFailure Wiktionary: $error',
          );
        }
        rethrow;
      }
    }

    if (definition == null) {
      if (dictionaryFailure != null) throw dictionaryFailure;
      return WordMeaning(
        word: cleaned,
        meaning: 'Meaning not found',
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    }

    String? translated;
    String? translationError;
    if (targetLanguage != 'en' && definition.meaning != 'Meaning not found') {
      try {
        translated = await _translate(
          definition.meaning,
          source: 'en',
          target: targetLanguage,
        );
      } on Object catch (error) {
        translationError = error.toString();
      }
    }

    return WordMeaning(
      word: definition.word.isEmpty ? cleaned : definition.word,
      meaning: definition.meaning,
      partOfSpeech: definition.partOfSpeech,
      pronunciation: definition.pronunciation,
      synonyms: definition.synonyms,
      antonyms: definition.antonyms,
      translations: {
        ...definition.translations,
        if (translated != null) targetLanguage: translated,
      },
      translationError: translationError,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }

  Future<WordMeaning?> _lookupDictionaryApi(String word) async {
    final response = await _get(
      Uri.parse(
        '${AppConstants.dictionaryApiUrl}/en/${Uri.encodeComponent(word)}',
      ),
      headers: const {'Accept': 'application/json'},
      serviceName: 'Free Dictionary',
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw DictionaryServiceException(
        'Free Dictionary returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = _decodeJson(response.body, 'Free Dictionary');
    if (decoded is! List || decoded.isEmpty || decoded.first is! Map) {
      return null;
    }
    final entry = Map<String, dynamic>.from(decoded.first as Map);
    final meanings = entry['meanings'];
    if (meanings is! List || meanings.isEmpty || meanings.first is! Map) {
      return null;
    }

    final firstMeaning = Map<String, dynamic>.from(meanings.first as Map);
    final definitions = firstMeaning['definitions'];
    if (definitions is! List ||
        definitions.isEmpty ||
        definitions.first is! Map) {
      return null;
    }

    final firstDefinition = Map<String, dynamic>.from(definitions.first as Map);
    final additionalMeanings = meanings.skip(1).take(2).whereType<Map>().map(
      (item) {
        final nested = item['definitions'];
        if (nested is! List || nested.isEmpty || nested.first is! Map) {
          return null;
        }
        return (nested.first as Map)['definition']?.toString();
      },
    ).whereType<String>();
    final definitionText = firstDefinition['definition']?.toString() ?? '';
    final meaning = [definitionText, ...additionalMeanings]
        .where((text) => text.trim().isNotEmpty)
        .join('\n\n');
    if (meaning.isEmpty) return null;

    return WordMeaning(
      word: entry['word']?.toString() ?? word,
      meaning: meaning,
      partOfSpeech: firstMeaning['partOfSpeech']?.toString(),
      pronunciation: entry['phonetic']?.toString(),
      synonyms: _stringList(firstMeaning['synonyms']),
      antonyms: _stringList(firstMeaning['antonyms']),
      sourceLanguage: 'en',
      targetLanguage: 'en',
    );
  }

  Future<WordMeaning?> _lookupWiktionary(String word) async {
    final response = await _get(
      Uri.https(
        'en.wiktionary.org',
        '/api/rest_v1/page/definition/$word',
      ),
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'FrameReader/1.0 (OCR dictionary lookup)',
      },
      serviceName: 'Wiktionary',
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw DictionaryServiceException(
        'Wiktionary returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = _decodeJson(response.body, 'Wiktionary');
    if (decoded is! Map) return null;
    final english = decoded['en'];
    if (english is! List || english.isEmpty) return null;

    String? partOfSpeech;
    final definitions = <String>[];
    for (final item in english.take(3).whereType<Map>()) {
      partOfSpeech ??= item['partOfSpeech']?.toString();
      final entries = item['definitions'];
      if (entries is! List) continue;
      for (final entry in entries.take(2).whereType<Map>()) {
        final text = _stripHtml(entry['definition']?.toString() ?? '');
        if (text.isNotEmpty) definitions.add(text);
      }
    }
    if (definitions.isEmpty) return null;

    return WordMeaning(
      word: word,
      meaning: definitions.join('\n\n'),
      partOfSpeech: partOfSpeech,
      sourceLanguage: 'en',
      targetLanguage: 'en',
    );
  }

  Future<String> _translate(
    String text, {
    required String source,
    required String target,
  }) async {
    final uri = Uri.parse(AppConstants.translationApiUrl).replace(
      queryParameters: {
        'q': text.length > 500 ? text.substring(0, 500) : text,
        'langpair': '$source|$target',
      },
    );
    final response = await _get(uri, serviceName: 'MyMemory');
    if (response.statusCode != 200) {
      throw DictionaryServiceException(
        'MyMemory returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = _decodeJson(response.body, 'MyMemory');
    if (decoded is! Map || decoded['responseStatus']?.toString() != '200') {
      final details =
          decoded is Map ? decoded['responseDetails']?.toString() : null;
      throw DictionaryServiceException(
        details == null || details.isEmpty
            ? 'MyMemory could not translate this definition.'
            : 'MyMemory: $details',
      );
    }
    final responseData = decoded['responseData'];
    final translated = responseData is Map
        ? responseData['translatedText']?.toString().trim()
        : null;
    if (translated == null || translated.isEmpty) {
      throw const DictionaryServiceException(
        'MyMemory returned an empty translation.',
      );
    }
    return translated;
  }

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
    required String serviceName,
  }) async {
    try {
      return await _client.get(uri, headers: headers).timeout(requestTimeout);
    } on TimeoutException {
      throw DictionaryServiceException('$serviceName request timed out.');
    } on http.ClientException catch (error) {
      throw DictionaryServiceException(
        '$serviceName connection failed: ${error.message}',
      );
    }
  }

  dynamic _decodeJson(String body, String serviceName) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw DictionaryServiceException(
        '$serviceName returned an invalid response.',
      );
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
