import 'dart:typed_data';

bool get hasFileSystem => false;

bool get isMacOS => false;

Future<Uint8List> readFileBytes(String path) {
  throw UnsupportedError('No filesystem on this platform.');
}

Future<String> saveBytesToAppDir(
  Uint8List bytes,
  String directory,
  String fileName,
) {
  throw UnsupportedError('No filesystem on this platform.');
}
