import 'package:video_player/video_player.dart';

import '../models/media_item.dart';

VideoPlayerController createVideoController(MediaItem media) {
  throw UnsupportedError('Video playback is not supported on this platform.');
}
