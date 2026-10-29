import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/media/media_bloc.dart';
import '../bloc/media/media_state.dart';
import '../bloc/media/media_event.dart';
import '../bloc/ocr/ocr_bloc.dart';
import '../bloc/ocr/ocr_event.dart';
import '../models/media_item.dart';
import '../services/language_service.dart';
import '../services/service_locator.dart';
import '../widgets/language_selector.dart';
import '../app/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Translator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<MediaBloc, MediaState>(
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'What would you like to read?',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildMediaCategories(context),
                      const SizedBox(height: 20),
                      Expanded(child: _buildMediaPreview(context, state)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaCategories(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12.0;
        final cardWidth = constraints.maxWidth >= 700
            ? (constraints.maxWidth - gap * 2) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: _CategoryCard(
                icon: Icons.image_outlined,
                label: 'Image',
                subtitle: 'Choose or capture a photo',
                onTap: () => _showImageOptions(context),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _CategoryCard(
                icon: Icons.movie_outlined,
                label: 'Video',
                subtitle: 'Choose a frame to scan',
                onTap: () => _showVideoOptions(context),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _CategoryCard(
                icon: Icons.description_outlined,
                label: 'Document',
                subtitle: 'PDF, DOCX, TXT, or RTF',
                onTap: () => _showDocumentOptions(context),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImageOptions(BuildContext context) {
    _showOptionsSheet(
      context,
      title: 'Add image',
      options: [
        _SheetOption(
          icon: Icons.camera_alt,
          label: 'Take photo',
          onTap: () => context.read<MediaBloc>().add(CaptureImageEvent()),
        ),
        _SheetOption(
          icon: Icons.photo_library,
          label: 'Choose from device',
          onTap: () => context.read<MediaBloc>().add(PickImageEvent()),
        ),
      ],
    );
  }

  void _showDocumentOptions(BuildContext context) {
    _showOptionsSheet(
      context,
      title: 'Add document',
      options: [
        _SheetOption(
          icon: Icons.upload_file,
          label: 'Upload from device',
          onTap: () => context.read<MediaBloc>().add(PickDocumentEvent()),
        ),
      ],
    );
  }

  void _showVideoOptions(BuildContext context) {
    _showOptionsSheet(
      context,
      title: 'Add video',
      options: [
        _SheetOption(
          icon: Icons.videocam_outlined,
          label: 'Record a video',
          onTap: () => context.read<MediaBloc>().add(CaptureVideoEvent()),
        ),
        _SheetOption(
          icon: Icons.video_library_outlined,
          label: 'Choose from device',
          onTap: () => context.read<MediaBloc>().add(PickVideoEvent()),
        ),
      ],
    );
  }

  void _showOptionsSheet(
    BuildContext context, {
    required String title,
    required List<_SheetOption> options,
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...options.map(
              (option) => ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  option.onTap();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, MediaState state) {
    if (state is MediaLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is MediaError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      );
    }

    if (state is MediaLoaded && state.currentMedia != null) {
      return Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                image: state.currentMedia!.type == MediaType.image
                    ? _imageDecoration(state.currentMedia!)
                    : null,
              ),
              child: switch (state.currentMedia!.type) {
                MediaType.video => const Center(
                    child: Icon(Icons.play_circle_outline, size: 64),
                  ),
                MediaType.document => const Center(
                    child: Icon(Icons.description_outlined, size: 64),
                  ),
                MediaType.image => null,
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (state.currentMedia != null) {
                      // Process media and navigate to OCR
                      if (state.currentMedia!.type == MediaType.video) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.videoEditor,
                          arguments: {'mediaItem': state.currentMedia},
                        );
                      } else {
                        final ocrBloc = context.read<OCRBloc>();
                        ocrBloc.add(
                          PerformOCREvent(
                            media: state.currentMedia!,
                            language: getIt<LanguageService>().currentLanguage,
                          ),
                        );
                        Navigator.pushNamed(context, AppRoutes.ocrResult);
                      }
                    }
                  },
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Perform OCR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<MediaBloc>().add(ClearMediaEvent());
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Select an image, video, or document to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _imageDecoration(MediaItem media) {
    if (media.bytes != null) {
      return DecorationImage(
        image: MemoryImage(media.bytes!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LanguageSelector(),
    );
  }
}

class _SheetOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
