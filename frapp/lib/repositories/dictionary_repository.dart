import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/word_meaning.dart';
import '../services/dictionary_service.dart';

class DictionaryRepository {
  final _dictionaryService = DictionaryService();
  final _historyKey = 'dictionary_history';
  
  Future<WordMeaning> getWordMeaning(
    String word, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      // Try local cache first
      final cached = await _getCachedMeaning(word, sourceLanguage, targetLanguage);
      if (cached != null) {
        return cached;
      }
      
      // Fetch from service
      final meaning = await _dictionaryService.lookupWord(
        word,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      
      // Cache the result
      await _cacheMeaning(meaning);
      
      return meaning;
    } catch (e) {
      // Return empty meaning if service fails
      return WordMeaning(
        word: word,
        meaning: 'Meaning not available',
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    }
  }
  
  Future<void> addToHistory(String word, String meaning) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    final item = WordMeaning(
      word: word,
      meaning: meaning,
      sourceLanguage: 'en',
      targetLanguage: 'ur',
    );
    
    history.insert(0, item);
    if (history.length > 50) {
      history.removeLast();
    }
    
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }
  
  Future<List<WordMeaning>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    
    if (historyJson == null) return [];
    
    try {
      final list = jsonDecode(historyJson) as List;
      return list.map((e) => WordMeaning.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
  
  Future<WordMeaning?> _getCachedMeaning(
    String word,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    // Simple cache implementation
    final cacheKey = 'meaning_${sourceLanguage}_${targetLanguage}_$word';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    
    if (cached != null) {
      try {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        return WordMeaning.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
  
  Future<void> _cacheMeaning(WordMeaning meaning) async {
    final cacheKey = 'meaning_${meaning.sourceLanguage}_${meaning.targetLanguage}_${meaning.word}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(meaning.toJson()));
  }
}