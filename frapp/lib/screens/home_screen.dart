import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/media/media_bloc.dart';
import '../bloc/media/media_state.dart';
import '../bloc/media/media_event.dart';
import '../bloc/ocr/ocr_bloc.dart';
import '../widgets/language_selector.dart';
import '../app/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                  // Media type selection
                  _buildMediaTypeButtons(context),
                  const SizedBox(height: 20),
                  
                  // Selected media preview or placeholder
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
  
  Widget _buildMediaTypeButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.read<MediaBloc>().add(PickImageEvent()),
            icon: const Icon(Icons.photo_library),
            label: const Text('Image'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.read<MediaBloc>().add(PickVideoEvent()),
            icon: const Icon(Icons.video_library),
            label: const Text('Video'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.read<MediaBloc>().add(PickDocumentEvent()),
            icon: const Icon(Icons.description),
            label: const Text('Document'),
          ),
        ),
      ],
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
                    ? DecorationImage(
                        image: FileImage(File(state.currentMedia!.path)),
                        fit: BoxFit.cover,
                      )
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
                        // Process image/document directly
                        context.read<MediaBloc>().add(
                          ProcessMediaEvent(state.currentMedia!)
                        );
                        final ocrBloc = context.read<OCRBloc>();
                        ocrBloc.add(
                          PerformOCREvent(
                            imagePath: state.currentMedia!.path,
                            language: GetIt.I<LanguageService>().currentLanguage,
                          )
                        );
                        Navigator.pushNamed(context, AppRoutes.ocrResult);
                      }
                    }
                  },
                  icon: const Icon(Icons.ocr),
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
              'Select an image, video, or document to get started',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LanguageSelector(),
    );
  }
}