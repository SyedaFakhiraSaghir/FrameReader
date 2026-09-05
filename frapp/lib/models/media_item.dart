import 'package:equatable/equatable.dart';

enum MediaType { image, video, document }

class MediaItem extends Equatable {
  final String id;
  final String path;
  final MediaType type;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  
  const MediaItem({
    required this.id,
    required this.path,
    required this.type,
    required this.createdAt,
    this.metadata = const {},
  });
  
  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'],
      path: map['path'],
      type: MediaType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MediaType.image,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'type': type.toString(),
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  @override
  List<Object?> get props => [id, path, type, createdAt];
}