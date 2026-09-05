import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word_meaning.dart';

class DictionaryService {
  static const String baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en'; // Free API
  // You can replace with your own API for multiple languages
  
  Future<WordMeaning> lookupWord(
    String word, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$word'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          final entry = data[0] as Map<String, dynamic>;
          final meanings = entry['meanings'] as List? ?? [];
          
          if (meanings.isNotEmpty) {
            final firstMeaning = meanings[0] as Map<String, dynamic>;
            final definitions = firstMeaning['definitions'] as List? ?? [];
            
            if (definitions.isNotEmpty) {
              final definition = definitions[0] as Map<String, dynamic>;
              
              // For Urdu translation, you might want to use a translation API
              // This is a simplified version
              String urduTranslation = await _translateToUrdu(definition['definition'] ?? '');
              
              return WordMeaning(
                word: word,
                meaning: definition['definition'] ?? 'No definition available',
                partOfSpeech: firstMeaning['partOfSpeech'],
                pronunciation: entry['phonetic'],
                synonyms: (firstMeaning['synonyms'] as List?)?.cast<String>() ?? [],
                antonyms: (firstMeaning['antonyms'] as List?)?.cast<String>() ?? [],
                translations: {
                  'ur': urduTranslation,
                },
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
              );
            }
          }
        }
      }
      
      // Fallback: return word with placeholder meaning
      return WordMeaning(
        word: word,
        meaning: 'Meaning not found',
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    } catch (e) {
      throw Exception('Failed to lookup word: $e');
    }
  }
  
  Future<String> _translateToUrdu(String text) async {
    // Simple approach - you can replace with actual translation API
    // For demo purposes, just return the text with a marker
    return '[Urdu translation pending] $text';
  }
}