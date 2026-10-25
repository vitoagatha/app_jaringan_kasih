import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'photo_selection.dart';

class DevicePhotoPicker implements PhotoPicker {
  final ImagePicker _picker;

  DevicePhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<MultipartPhoto?> pick(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
          source: source == PhotoSource.gallery
              ? ImageSource.gallery
              : ImageSource.camera,
          maxWidth: 4096,
          maxHeight: 4096,
          imageQuality: 85,
          requestFullMetadata: false);
      return file == null ? null : await _read(file);
    } on PlatformException catch (error) {
      throw _pickerError(error);
    }
  }

  @override
  Future<MultipartPhoto?> recover() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final data = await _picker.retrieveLostData();
      if (data.exception != null) throw _pickerError(data.exception!);
      final files = data.files;
      return files == null || files.isEmpty ? null : await _read(files.first);
    } on PlatformException catch (error) {
      throw _pickerError(error);
    }
  }

  Future<MultipartPhoto> _read(XFile file) async {
    if (await file.length() > MultipartPhoto.maxBytes) {
      throw const ApiException(
          'Gambar maksimal 2 MB. Pilih gambar yang lebih kecil.');
    }
    final photo = validatePhotoBytes(await file.readAsBytes());
    // Baca metadata dimensi sebelum preview mendekode seluruh piksel.
    final buffer = await ui.ImmutableBuffer.fromUint8List(photo.bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width < 32 ||
            descriptor.height < 32 ||
            descriptor.width > 4096 ||
            descriptor.height > 4096) {
          throw const ApiException(
              'Dimensi gambar harus antara 32 dan 4096 piksel pada setiap sisi.');
        }
      } finally {
        descriptor.dispose();
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
          'Gambar rusak atau tidak dapat dibaca. Pilih gambar lain.');
    } finally {
      buffer.dispose();
    }
    return photo;
  }

  ApiException _pickerError(PlatformException error) => ApiException(error.code
              .contains('denied') ||
          error.code.contains('restricted')
      ? 'Akses foto atau kamera ditolak. Periksa izin aplikasi di pengaturan perangkat.'
      : 'Pemilihan gambar gagal. Pastikan galeri atau kamera tersedia.');
}
