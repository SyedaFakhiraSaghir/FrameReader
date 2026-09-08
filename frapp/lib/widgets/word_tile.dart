import 'package:flutter/material.dart';

import '../models/word_meaning.dart';

class WordTile extends StatelessWidget {
  final WordMeaning wordMeaning;
  final VoidCallback onTap;

  const WordTile({
    super.key,
    required this.wordMeaning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Text(
            wordMeaning.word[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          wordMeaning.word,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          wordMeaning.meaning.length > 50
              ? '${wordMeaning.meaning.substring(0, 50)}...'
              : wordMeaning.meaning,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}