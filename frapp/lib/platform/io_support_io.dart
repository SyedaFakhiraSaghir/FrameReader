import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

bool get hasFileSystem => true;

bool get isMacOS => Platform.isMacOS;

Future<Uint8List> readFileBytes(String path) {
  return File(path).readAsBytes();
}

Future<String> saveBytesToAppDir(
  Uint8List bytes,
  String directory,
  String fileName,
) async {
  final appDir = await getApplicationDocumentsDirectory();
  final mediaDir = Directory('${appDir.path}/media/$directory');
  if (!await mediaDir.exists()) {
    await mediaDir.create(recursive: true);
  }
  final safeName =
      '${DateTime.now().millisecondsSinceEpoch}_${p.basename(fileName)}';
  final savedPath = '${mediaDir.path}/$safeName';
  await File(savedPath).writeAsBytes(bytes, flush: true);
  return savedPath;
}
