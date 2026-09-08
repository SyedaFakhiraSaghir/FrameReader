import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum MediaType { image, video, document }

class MediaItem extends Equatable {
  final String id;
  final String? path;
  final Uint8List? bytes;
  final String fileName;
  final MediaType type;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const MediaItem({
    required this.id,
    this.path,
    this.bytes,
    required this.fileName,
    required this.type,
    required this.createdAt,
    this.metadata = const {},
  });

  String get extension {
    final fromMeta = metadata['extension']?.toString();
    if (fromMeta != null && fromMeta.isNotEmpty) {
      return fromMeta.toLowerCase();
    }
    final name = fileName.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1);
  }

  String? get objectUrl => metadata['objectUrl'] as String?;

  @override
  List<Object?> get props => [id, path, fileName, type, createdAt];
}
