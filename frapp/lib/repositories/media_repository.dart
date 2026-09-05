import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';
import '../services/media_service.dart';
import '../utils/constants.dart';

class MediaRepository {
  final _mediaService = MediaService();
  
  Future<MediaItem?> pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image == null) return null;
      
      final path = await _mediaService.saveMediaFile(
        File(image.path),
        'image',
      );
      
      return MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: path,
        type: MediaType.image,
        createdAt: DateTime.now(),
        metadata: {'originalPath': image.path},
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<MediaItem?> pickVideo() async {
    try {
      final XFile? video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );
      
      if (video == null) return null;
      
      final path = await _mediaService.saveMediaFile(
        File(video.path),
        'video',
      );
      
      return MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: path,
        type: MediaType.video,
        createdAt: DateTime.now(),
        metadata: {'originalPath': video.path},
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<MediaItem?> pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );
      
      if (result == null || result.files.isEmpty) return null;
      
      final file = File(result.files.first.path!);
      final path = await _mediaService.saveMediaFile(file, 'document');
      
      return MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: path,
        type: MediaType.document,
        createdAt: DateTime.now(),
        metadata: {
          'name': result.files.first.name,
          'size': result.files.first.size,
          'extension': result.files.first.extension,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<String> processMedia(MediaItem mediaItem) async {
    // Process media based on type
    switch (mediaItem.type) {
      case MediaType.image:
        return mediaItem.path;
      case MediaType.video:
        // For video, we'll process later
        return mediaItem.path;
      case MediaType.document:
        // For documents, convert to image for OCR
        return await _mediaService.convertDocumentToImage(mediaItem.path);
    }
  }
  
  Future<String> extractFrame(MediaItem videoItem, Duration position) async {
    final controller = VideoPlayerController.file(File(videoItem.path));
    await controller.initialize();
    await controller.seekTo(position);
    
    // Wait for frame to be rendered
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Capture frame
    final tempDir = await getTemporaryDirectory();
    final framePath = '${tempDir.path}/frame_${DateTime.now().millisecondsSinceEpoch}.png';
    
    // Use video_player's method to capture frame
    // Note: This is a simplified version - you might need to use a more robust method
    final bytes = await controller.video?.renderImage(position) as Future<Uint8List>?;
    
    if (bytes != null) {
      final frameFile = File(framePath);
      await frameFile.writeAsBytes(bytes);
      return framePath;
    }
    
    controller.dispose();
    throw Exception('Failed to extract frame');
  }
}