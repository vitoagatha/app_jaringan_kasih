import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

enum PhotoSource { gallery, camera }

abstract interface class PhotoPicker {
  Future<MultipartPhoto?> pick(PhotoSource source);
  Future<MultipartPhoto?> recover();
}

MultipartPhoto validatePhotoBytes(Uint8List bytes) {
  String? mime;
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 13 &&
      bytes[5] == 10 &&
      bytes[6] == 26 &&
      bytes[7] == 10) {
    mime = 'image/png';
  } else if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    mime = 'image/jpeg';
  } else if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    mime = 'image/webp';
  }
  if (mime == null) {
    throw const ApiException(
        'Format gambar tidak didukung. Pilih JPEG, PNG, atau WebP.');
  }
  return MultipartPhoto(bytes, mime);
}
