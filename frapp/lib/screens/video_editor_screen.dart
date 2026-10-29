import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../app/routes.dart';
import '../bloc/media/media_bloc.dart';
import '../bloc/media/media_event.dart';
import '../bloc/media/media_state.dart';
import '../bloc/ocr/ocr_bloc.dart';
import '../bloc/ocr/ocr_event.dart';
import '../models/media_item.dart';
import '../platform/video_controller.dart';
import '../services/language_service.dart';
import '../services/service_locator.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  MediaItem? _mediaItem;
  String? _errorMessage;
  bool _isInitializing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mediaItem != null || _errorMessage != null) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is! Map || arguments['mediaItem'] is! MediaItem) {
      _errorMessage = 'The selected video could not be opened.';
      return;
    }

    _mediaItem = arguments['mediaItem'] as MediaItem;
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final media = _mediaItem;
    if (media == null || _isInitializing) return;
    _isInitializing = true;

    try {
      final controller = createVideoController(media);
      _controller = controller;
      await controller.initialize();
      controller.addListener(_onVideoChanged);
      if (mounted) setState(() {});
    } catch (error) {
      _errorMessage = 'Could not load this video: $error';
      if (mounted) setState(() {});
    } finally {
      _isInitializing = false;
    }
  }

  void _onVideoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MediaBloc, MediaState>(
      listenWhen: (previous, current) =>
          current is MediaError ||
          (previous is MediaLoaded &&
              previous.isExtractingFrame &&
              current is MediaLoaded &&
              !current.isExtractingFrame &&
              current.extractedFrame != null),
      listener: (context, state) {
        if (state is MediaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is MediaLoaded && state.extractedFrame != null) {
          context.read<OCRBloc>().add(
                PerformOCREvent(
                  media: state.extractedFrame!,
                  language: getIt<LanguageService>().currentLanguage,
                ),
              );
          Navigator.pushNamed(context, AppRoutes.ocrResult);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Select video frame')),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = _controller;
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final value = controller.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: AspectRatio(
                  aspectRatio:
                      value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              colors: VideoProgressColors(
                playedColor: Theme.of(context).colorScheme.primary,
                bufferedColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.25),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Back 5 seconds',
                  onPressed: () => _seekBy(const Duration(seconds: -5)),
                  icon: const Icon(Icons.replay_5),
                ),
                IconButton.filled(
                  tooltip: value.isPlaying ? 'Pause video' : 'Play video',
                  onPressed: _togglePlayback,
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Forward 5 seconds',
                  onPressed: () => _seekBy(const Duration(seconds: 5)),
                  icon: const Icon(Icons.forward_5),
                ),
              ],
            ),
            Text(
              '${_formatDuration(value.position)} / '
              '${_formatDuration(value.duration)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 24),
            BlocBuilder<MediaBloc, MediaState>(
              builder: (context, state) {
                final isExtracting =
                    state is MediaLoaded && state.isExtractingFrame;
                return FilledButton.icon(
                  onPressed: isExtracting ? null : _extractSelectedFrame,
                  icon: isExtracting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.document_scanner_outlined),
                  label: Text(
                    isExtracting
                        ? 'Extracting frame…'
                        : 'Use this frame for OCR',
                  ),
                );
              },
            ),
          ],
        );

        return Center(
          child: SizedBox(
            width: constraints.maxWidth > 900 ? 900 : double.infinity,
            child: content,
          ),
        );
      },
    );
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _seekBy(Duration offset) async {
    final controller = _controller;
    if (controller == null) return;
    final target = controller.value.position + offset;
    final boundedMilliseconds = target.inMilliseconds
        .clamp(0, controller.value.duration.inMilliseconds);
    await controller.seekTo(Duration(milliseconds: boundedMilliseconds));
  }

  Future<void> _extractSelectedFrame() async {
    final controller = _controller;
    final media = _mediaItem;
    if (controller == null || media == null) return;
    if (controller.value.isPlaying) await controller.pause();
    if (!mounted) return;

    context.read<MediaBloc>().add(
          ExtractFrameEvent(
            videoItem: media,
            position: controller.value.position,
          ),
        );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
