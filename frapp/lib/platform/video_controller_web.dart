import 'package:video_player/video_player.dart';

import '../models/media_item.dart';

VideoPlayerController createVideoController(MediaItem media) {
  final url = media.objectUrl ?? media.path;
  if (url == null || url.isEmpty) {
    throw ArgumentError('The selected video file is not available.');
  }
  return VideoPlayerController.networkUrl(Uri.parse(url));
}
