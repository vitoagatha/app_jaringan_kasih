import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'photo_selection.dart';

class DevicePhotoPicker implements PhotoPicker {
  final ImagePicker _picker;
  final FlutterSecureStorage _storage;
  final String _purposeKey;
  final String _scope;
  bool _busy = false;

  DevicePhotoPicker(
      {ImagePicker? picker, FlutterSecureStorage? storage, Uri? baseUri})
      : _picker = picker ?? ImagePicker(),
        _storage = storage ??
            const FlutterSecureStorage(
                aOptions: AndroidOptions(encryptedSharedPreferences: true)),
        _purposeKey = 'jk_pending_photo_context',
        _scope = base64Url.encode(utf8.encode(baseUri?.toString() ?? 'local'));

  @override
  Future<MultipartPhoto?> pick(PhotoSource source,
      {String purpose = 'profile'}) async {
    if (_busy) {
      throw const ApiException(
          'Pemilihan gambar masih berlangsung. Silakan tunggu.');
    }
    _busy = true;
    try {
      await _storage.write(key: _purposeKey, value: '$_scope:$purpose');
      final file = await _picker.pickImage(
          source: source == PhotoSource.gallery
              ? ImageSource.gallery
              : ImageSource.camera,
          maxWidth: 4096,
          maxHeight: 4096,
          imageQuality: 85,
          requestFullMetadata: false);
      await _storage.delete(key: _purposeKey);
      return file == null ? null : await _read(file);
    } on PlatformException catch (error) {
      throw _pickerError(error);
    } finally {
      _busy = false;
    }
  }

  @override
  Future<MultipartPhoto?> recover({String purpose = 'profile'}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    if (_busy) return null;
    _busy = true;
    try {
      if (await _storage.read(key: _purposeKey) != '$_scope:$purpose') {
        return null;
      }
      final data = await _picker.retrieveLostData();
      await _storage.delete(key: _purposeKey);
      if (data.exception != null) throw _pickerError(data.exception!);
      final files = data.files;
      return files == null || files.isEmpty ? null : await _read(files.first);
    } on PlatformException catch (error) {
      throw _pickerError(error);
    } finally {
      _busy = false;
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
