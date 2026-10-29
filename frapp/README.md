# OCR Translator App

A Flutter application that performs OCR on images, videos, and documents with multi-language support.

## Features

- 📷 **Image Input**: Select images from gallery for OCR
- 🎥 **Video Input**: Select videos, pause and extract frames for OCR
- 📄 **Document Input**: Support for PDF, DOCX, and text files
- 🔍 **OCR**: Google ML Kit on Android/iOS, Vision on macOS, and Tesseract.js on web
- 🌍 **Multi-language**: Support for Urdu, English, and other languages
- 📖 **Dictionary**: Click on any word to get its meaning
- 🎨 **Clean UI**: Material Design with dark/light mode support

## Installation

1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter run`

## How to Use

1. **Select Input**: Choose Image, Video, or Document
2. **Process**: For videos, pause and select a frame
3. **OCR**: The app extracts text automatically
4. **Select Word**: Tap any word to see its meaning
5. **History**: Your searches are saved for quick access

## Supported Languages

- English
- Urdu
- Arabic
- Spanish
- French
- German
- Chinese
- Hindi

On Android and iOS, Google ML Kit supports Latin, Chinese, and Devanagari
recognition scripts. Urdu and Arabic OCR are not supported by ML Kit on those
platforms; web and macOS recognition depend on the language data available to
their OCR engines.

## Platform Notes

- iOS requires a minimum deployment target of 15.5 for the Google ML Kit
  Flutter plugin.
- PDF files are rendered and OCR-processed page by page. DOCX text is parsed
  into selectable words directly.

## Architecture

The app follows BLoC (Business Logic Component) architecture with:

- **Repositories**: Handle data operations
- **Services**: External API interactions
- **BLoCs**: Business logic and state management
- **Widgets**: UI components

## Dependencies

- flutter_bloc: State management
- google_ml_kit: OCR functionality
- image_picker: Media selection
- video_player: Video playback
- file_picker: Document selection
- http/dio: API calls

## API Keys

The app uses:
- Free Dictionary API for English definitions
- MyMemory Translation API for Urdu translations

## License

MIT License