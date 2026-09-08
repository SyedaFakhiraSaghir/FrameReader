import 'package:flutter/material.dart';

class MediaCaptureScreen extends StatelessWidget {
  const MediaCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Media')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to media picker'),
        ),
      ),
    );
  }
}
