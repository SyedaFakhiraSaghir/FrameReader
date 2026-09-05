import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MediaService {
  Future<String> saveMediaFile(File file, String type) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media/$type');
      
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final savedPath = '${mediaDir.path}/$fileName';
      
      await file.copy(savedPath);
      return savedPath;
    } catch (e) {
      throw Exception('Failed to save media: $e');
    }
  }
  
  Future<String> convertDocumentToImage(String documentPath) async {
    // For demo purposes, return the document path
    // In a real app, you would use a PDF reader or document viewer to convert
    return documentPath;
  }
  
  Future<void> deleteMediaFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Log error but don't throw
      print('Failed to delete media file: $e');
    }
  }
}