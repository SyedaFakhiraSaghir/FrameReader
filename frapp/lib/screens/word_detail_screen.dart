import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/word_meaning.dart';
import '../bloc/dictionary/dictionary_bloc.dart';
import '../bloc/dictionary/dictionary_event.dart';
import '../bloc/dictionary/dictionary_state.dart';

class WordDetailScreen extends StatelessWidget {
  final String word;
  final WordMeaning meaning;

  const WordDetailScreen({
    super.key,
    required this.word,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<DictionaryBloc, DictionaryState>(
      listener: (context, state) {
        if (state is DictionaryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is DictionaryHistoryLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to history')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(word),
          actions: [
            IconButton(
              tooltip: 'Save to history',
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {
                context.read<DictionaryBloc>().add(
                      AddToHistoryEvent(word: word, meaning: meaning.meaning),
                    );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Word and pronunciation
              Row(
                children: [
                  Expanded(
                    child: Text(
                      word,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (meaning.pronunciation != null)
                    Chip(
                      label: Text(meaning.pronunciation!),
                      backgroundColor: Colors.grey[200],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Part of speech
              if (meaning.partOfSpeech != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    meaning.partOfSpeech!,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Meaning
              const Text(
                'Meaning:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  meaning.meaning,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              if (meaning.translationError != null &&
                  !meaning.translations.containsKey('ur'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Translation unavailable: ${meaning.translationError}',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),

              // Urdu Translation
              if (meaning.translations.containsKey('ur'))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Urdu Translation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meaning.translations['ur']!,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Synonyms
              if (meaning.synonyms.isNotEmpty) ...[
                const Text(
                  'Synonyms:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: meaning.synonyms
                      .map((synonym) => Chip(
                            label: Text(synonym),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Antonyms
              if (meaning.antonyms.isNotEmpty) ...[
                const Text(
                  'Antonyms:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: meaning.antonyms
                      .map((antonym) => Chip(
                            label: Text(antonym),
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
