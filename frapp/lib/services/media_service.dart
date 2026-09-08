import 'dart:typed_data';

import '../platform/io_support.dart';

class MediaService {
  Future<String> saveBytes(
    Uint8List bytes,
    String type,
    String fileName,
  ) {
    return saveBytesToAppDir(bytes, type, fileName);
  }
}
