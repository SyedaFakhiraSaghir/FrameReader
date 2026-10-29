import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ocr_translator_app/services/dictionary_service.dart';

void main() {
  group('DictionaryService', () {
    test('returns a definition and surfaces failed MyMemory translations',
        () async {
      final service = DictionaryService(
        client: MockClient((request) async {
          if (request.url.host == 'api.dictionaryapi.dev') {
            return http.Response(
              jsonEncode([
                {
                  'word': 'hello',
                  'meanings': [
                    {
                      'partOfSpeech': 'interjection',
                      'definitions': [
                        {'definition': 'A greeting.'}
                      ],
                    }
                  ],
                }
              ]),
              200,
            );
          }
          if (request.url.host == 'api.mymemory.translated.net') {
            return http.Response(
              jsonEncode({
                'responseStatus': 429,
                'responseDetails': 'Translation quota exceeded',
              }),
              200,
            );
          }
          fail('Unexpected service request: ${request.url}');
        }),
      );

      final result = await service.lookupWord(
        'hello',
        sourceLanguage: 'en',
        targetLanguage: 'ur',
      );

      expect(result.meaning, 'A greeting.');
      expect(result.translationError, contains('quota exceeded'));
      expect(result.translations, isEmpty);
    });

    test('throws a useful error when dictionary services fail', () async {
      final service = DictionaryService(
        client: MockClient((request) async => http.Response('', 503)),
      );

      await expectLater(
        service.lookupWord(
          'hello',
          sourceLanguage: 'en',
          targetLanguage: 'ur',
        ),
        throwsA(
          isA<DictionaryServiceException>().having(
              (error) => error.message, 'message', contains('HTTP 503')),
        ),
      );
    });
  });
}
