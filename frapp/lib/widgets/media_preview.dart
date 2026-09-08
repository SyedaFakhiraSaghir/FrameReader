import 'package:flutter/material.dart';

import '../models/media_item.dart';

class MediaPreview extends StatelessWidget {
  const MediaPreview({super.key, required this.media});

  final MediaItem media;

  @override
  Widget build(BuildContext context) {
    switch (media.type) {
      case MediaType.image:
        if (media.bytes != null) {
          return Image.memory(media.bytes!, fit: BoxFit.cover);
        }
        return const _Placeholder(icon: Icons.image, label: 'Image selected');
      case MediaType.video:
        return const _Placeholder(
          icon: Icons.play_circle_filled,
          label: 'Video selected',
        );
      case MediaType.document:
        return _Placeholder(
          icon: Icons.picture_as_pdf,
          label: media.fileName,
        );
    }
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
