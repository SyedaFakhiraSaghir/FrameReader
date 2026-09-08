import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/media/media_bloc.dart';
import '../bloc/media/media_event.dart';
import '../bloc/media/media_state.dart';
import '../bloc/ocr/ocr_bloc.dart';
import '../bloc/ocr/ocr_event.dart';
import '../models/media_item.dart';
import '../app/routes.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  MediaItem? _mediaItem;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mediaItem == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      _mediaItem = args['mediaItem'] as MediaItem;
      _initializeVideo();
    }
  }
  
  Future<void> _initializeVideo() async {
    if (_mediaItem == null) return;
    
    final mediaPath = _mediaItem!.path;
    if (mediaPath == null || mediaPath.isEmpty) return;
    _controller = VideoPlayerController.file(File(mediaPath));
    await _controller.initialize();
    
    setState(() {
      _isInitialized = true;
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Editor'),
        actions: [
          TextButton.icon(
            onPressed: _isInitialized ? _extractFrame : null,
            icon: const Icon(Icons.center_focus_strong),
            label: const Text('Extract Frame'),
          ),
        ],
      ),
      body: _isInitialized
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                const SizedBox(height: 16),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.blue,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_controller.value.position.inSeconds > 0) {
                          _controller.seekTo(
                            Duration(seconds: _controller.value.position.inSeconds - 5),
                          );
                        }
                      },
                      icon: const Icon(Icons.skip_previous),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                        setState(() {});
                      },
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 40,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _controller.seekTo(
                          Duration(seconds: _controller.value.position.inSeconds + 5),
                        );
                      },
                      icon: const Icon(Icons.skip_next),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Position: ${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                BlocBuilder<MediaBloc, MediaState>(
                  builder: (context, state) {
                    if (state is MediaLoaded && state.extractedFramePath != null) {
                      return Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(state.extractedFramePath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
  
  void _extractFrame() async {
    final position = _controller.value.position;
    
    context.read<MediaBloc>().add(
      ExtractFrameEvent(
        videoItem: _mediaItem!,
        position: position,
      ),
    );
    
    // Wait for frame extraction
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    // Navigate to OCR with the extracted frame
    final state = context.read<MediaBloc>().state;
    if (state is MediaLoaded && state.extractedFramePath != null) {
      context.read<OCRBloc>().add(
        PerformOCREvent(
          media: state.extractedFrame!,
          language: 'en', // Use selected language
        ),
      );
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.ocrResult);
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}