import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/media_item.dart';
import '../platform/io_support.dart';
import '../platform/web_media.dart';
import '../services/media_service.dart';
import '../services/ocr_service.dart';

class MediaRepository {
  MediaRepository({MediaService? mediaService, OCRService? ocrService})
      : _mediaService = mediaService ?? MediaService(),
        _ocrService = ocrService ?? OCRService();

  final MediaService _mediaService;
  final OCRService _ocrService;
  static const _macCamera = MethodChannel('frapp/camera');

  Future<MediaItem?> pickImage() {
    return _pickFile(FileType.image, MediaType.image, 'image');
  }

  Future<MediaItem?> captureImage() async {
    if (isMacOS) {
      return _captureOnMac('capturePhoto', MediaType.image, 'image', 'jpg');
    }
    return _selectWithImagePicker(ImageSource.camera, MediaType.image, 'image');
  }

  Future<MediaItem?> pickVideo() {
    return _pickFile(FileType.video, MediaType.video, 'video');
  }

  Future<MediaItem?> captureVideo() async {
    if (isMacOS) {
      return _captureOnMac('captureVideo', MediaType.video, 'video', 'mov');
    }
    return _selectWithImagePicker(ImageSource.camera, MediaType.video, 'video');
  }

  Future<MediaItem?> pickDocument() {
    return _pickFile(
      FileType.custom,
      MediaType.document,
      'document',
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'rtf'],
    );
  }

  Future<MediaItem> saveImageBytes(Uint8List bytes,
      {String name = 'frame.jpg'}) {
    return _toMediaItem(
      bytes: bytes,
      fileName: name,
      mediaType: MediaType.image,
      directory: 'image',
    );
  }

  Future<MediaItem> extractFrame(MediaItem video, Duration position) async {
    final bytes = await _ocrService.extractVideoFrame(video, position);
    return saveImageBytes(
      bytes,
      name: 'frame_${position.inMilliseconds}.jpg',
    );
  }

  Future<String> processMedia(MediaItem mediaItem) async {
    switch (mediaItem.type) {
      case MediaType.image:
      case MediaType.video:
        return mediaItem.path ?? mediaItem.fileName;
      case MediaType.document:
        return mediaItem.path ?? mediaItem.fileName;
    }
  }

  Future<MediaItem?> _selectWithImagePicker(
    ImageSource source,
    MediaType mediaType,
    String directory,
  ) async {
    final picker = ImagePicker();
    final XFile? file = mediaType == MediaType.video
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return _toMediaItem(
      bytes: bytes,
      fileName: file.name,
      mediaType: mediaType,
      directory: directory,
      originalPath: file.path,
    );
  }

  Future<MediaItem?> _pickFile(
    FileType type,
    MediaType mediaType,
    String directory, {
    List<String>? allowedExtensions,
  }) async {
    final selected = await FilePicker.pickFile(
      type: type,
      allowedExtensions: allowedExtensions,
    );
    if (selected == null) return null;

    final bytes = await selected.readAsBytes();
    return _toMediaItem(
      bytes: bytes,
      fileName: selected.name,
      mediaType: mediaType,
      directory: directory,
      originalPath: selected.path,
      extraMetadata: {
        'size': await selected.length(),
        'extension': selected.extension,
      },
    );
  }

  Future<MediaItem?> _captureOnMac(
    String method,
    MediaType mediaType,
    String directory,
    String fallbackExtension,
  ) async {
    final capturedPath = await _macCamera.invokeMethod<String>(method);
    if (capturedPath == null || capturedPath.isEmpty) return null;
    final bytes = await readFileBytes(capturedPath);
    return _toMediaItem(
      bytes: bytes,
      fileName: 'capture.$fallbackExtension',
      mediaType: mediaType,
      directory: directory,
      originalPath: capturedPath,
    );
  }

  Future<MediaItem> _toMediaItem({
    required Uint8List bytes,
    required String fileName,
    required MediaType mediaType,
    required String directory,
    String? originalPath,
    Map<String, dynamic>? extraMetadata,
  }) async {
    String? savedPath;
    String? objectUrl;

    if (hasFileSystem) {
      savedPath = await _mediaService.saveBytes(bytes, directory, fileName);
    } else if (kIsWeb) {
      objectUrl = createBlobUrl(bytes, _mimeType(mediaType, fileName));
    }

    final keepBytes = kIsWeb || mediaType != MediaType.video;
    return MediaItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: savedPath ?? originalPath,
      bytes: keepBytes ? bytes : null,
      fileName: fileName,
      type: mediaType,
      createdAt: DateTime.now(),
      metadata: {
        if (originalPath != null) 'originalPath': originalPath,
        if (objectUrl != null) 'objectUrl': objectUrl,
        ...?extraMetadata,
      },
    );
  }

  String _mimeType(MediaType type, String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (type) {
      case MediaType.image:
        return ext == 'png' ? 'image/png' : 'image/jpeg';
      case MediaType.video:
        return switch (ext) {
          'webm' => 'video/webm',
          'mov' => 'video/quicktime',
          'avi' => 'video/x-msvideo',
          _ => 'video/mp4',
        };
      case MediaType.document:
        if (ext == 'pdf') return 'application/pdf';
        return 'application/octet-stream';
    }
  }
}
