import 'dart:io';

import 'package:video_player/video_player.dart';

import '../models/media_item.dart';

VideoPlayerController createVideoController(MediaItem media) {
  final path = media.path;
  if (path == null || path.isEmpty) {
    throw ArgumentError('The selected video file is not available.');
  }
  return VideoPlayerController.file(File(path));
}
