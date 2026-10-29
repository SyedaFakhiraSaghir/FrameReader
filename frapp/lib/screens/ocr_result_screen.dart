import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ocr/ocr_bloc.dart';
import '../bloc/ocr/ocr_state.dart';
import '../models/ocr_result.dart';
import '../models/word_meaning.dart';
import '../repositories/dictionary_repository.dart';
import '../services/service_locator.dart';

class OCRResultScreen extends StatelessWidget {
  final String? imagePath;
  final String? ocrText;

  const OCRResultScreen({
    super.key,
    this.imagePath,
    this.ocrText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Result')),
      body: BlocBuilder<OCRBloc, OCRState>(
        builder: (context, state) {
          if (state is OCRLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OCRError) {
            return Center(child: Text(state.message));
          }
          if (state is OCRCompleted) {
            return _ResultBody(result: state.result);
          }
          return Center(child: Text(ocrText ?? 'No OCR result available.'));
        },
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final OCRResult result;

  const _ResultBody({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SelectableText(result.text),
        const SizedBox(height: 24),
        if (result.words.isEmpty)
          const Text('No selectable words were detected.'),
        ...result.words.map(
          (word) => ListTile(
            title: Text(word.text),
            onTap: () => _showMeaning(context, word.text, result.language),
          ),
        ),
      ],
    );
  }

  void _showMeaning(
    BuildContext context,
    String word,
    String sourceLanguage,
  ) {
    final repository = getIt<DictionaryRepository>();
    final lookup = repository.getWordMeaning(
      word,
      sourceLanguage: sourceLanguage,
      targetLanguage: 'ur',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => FutureBuilder<WordMeaning>(
        future: lookup,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox.square(
                dimension: 48,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (snapshot.hasError) {
            return AlertDialog(
              icon: Icon(
                Icons.cloud_off_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Lookup failed'),
              content: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const AlertDialog(
              title: Text('Meaning unavailable'),
              content: Text('The dictionary returned no result.'),
            );
          }

          final meaning = snapshot.data!;
          return AlertDialog(
            title: Text(meaning.word),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(meaning.meaning),
                  if (meaning.translations['ur'] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Urdu translation',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(meaning.translations['ur']!),
                  ] else if (meaning.translationError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Translation unavailable: ${meaning.translationError}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
