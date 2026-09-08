import 'dart:io';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMediaCategories(context),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildMediaPreview(context, state),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMediaCategories(BuildContext context) {
    return Column(
      children: [
        _CategoryCard(
          icon: Icons.image,
          label: 'Image',
          subtitle: 'Upload or take a photo',
          onTap: () => _showImageOptions(context),
        ),
        const SizedBox(height: 12),
        _CategoryCard(
          icon: Icons.description,
          label: 'Document',
          subtitle: 'Upload a PDF or document file',
          onTap: () => _showDocumentOptions(context),
        ),
      ],
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
              style: const TextStyle(color: Colors.red),
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
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: state.currentMedia!.type.toString().contains('image')
                    ? _imageDecoration(state.currentMedia!)
                    : null,
              ),
              child: state.currentMedia!.type.toString().contains('video')
                  ? const Center(
                      child: Icon(Icons.play_circle_filled, size: 64),
                    )
                  : state.currentMedia!.type.toString().contains('document')
                      ? const Center(
                          child: Icon(Icons.picture_as_pdf, size: 64),
                        )
                      : null,
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
                      if (state.currentMedia!.type.toString().contains('video')) {
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
                          )
                        );
                        Navigator.pushNamed(context, AppRoutes.ocrResult);
                      }
                    }
                  },
                            icon: const Icon(Icons.text_snippet),
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select an image or document to get started',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  DecorationImage _imageDecoration(MediaItem media) {
    if (media.bytes != null) {
      return DecorationImage(
        image: MemoryImage(media.bytes!),
        fit: BoxFit.cover,
      );
    }
    return DecorationImage(
      image: FileImage(File(media.path!)),
      fit: BoxFit.cover,
    );
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
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}