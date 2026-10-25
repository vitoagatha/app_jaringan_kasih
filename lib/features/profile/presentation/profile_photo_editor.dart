import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/application/session_controller.dart';
import '../data/photo_selection.dart';

class ProfilePhotoEditor extends StatefulWidget {
  final SessionController session;
  final PhotoPicker? picker;

  const ProfilePhotoEditor({super.key, required this.session, this.picker});

  @override
  State<ProfilePhotoEditor> createState() => _ProfilePhotoEditorState();
}

class _ProfilePhotoEditorState extends State<ProfilePhotoEditor> {
  MultipartPhoto? _selection;
  String? _message;
  bool _picking = false;
  int _imageAttempt = 0;

  @override
  void initState() {
    super.initState();
    if (widget.picker != null) unawaited(_select(recover: true));
  }

  @override
  void dispose() {
    widget.session.externalInteraction = false;
    super.dispose();
  }

  Future<void> _select(
      {PhotoSource source = PhotoSource.gallery, bool recover = false}) async {
    if (_picking || widget.session.busy || widget.picker == null) return;
    _picking = true;
    widget.session.externalInteraction = true;
    if (!recover) setState(() => _message = null);
    try {
      final photo = recover
          ? await widget.picker!
              .recover(purpose: 'profile:${widget.session.user!.id}')
          : await widget.picker!
              .pick(source, purpose: 'profile:${widget.session.user!.id}');
      if (mounted && photo != null) {
        setState(() {
          _selection = photo;
          _message = recover
              ? 'Foto pilihan sebelumnya dipulihkan. Periksa preview sebelum mengunggah.'
              : null;
        });
      }
    } catch (failure) {
      if (mounted) {
        setState(() => _message = failure is ApiException
            ? failure.displayMessage
            : 'Gambar tidak dapat dibaca. Silakan pilih lagi.');
      }
    } finally {
      widget.session.externalInteraction = false;
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _upload() async {
    final photo = _selection;
    if (photo == null) return;
    if (await widget.session.uploadPhoto(photo) && mounted) {
      setState(() {
        _selection = null;
        _message = 'Foto profil disimpan.';
      });
    }
  }

  Future<void> _delete() async {
    if (await widget.session.deletePhoto() && mounted) {
      setState(() => _message = 'Foto profil dihapus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.session.photoUri;
    final disabled = widget.session.busy || _picking;
    Widget fallback() => const Icon(Icons.person, size: 72);
    final preview = _selection != null
        ? Image.memory(_selection!.bytes,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Text('Preview tidak dapat dibaca.'))
        : photoUrl == null
            ? fallback()
            : Image.network(photoUrl.toString(),
                key: ValueKey('$photoUrl-$_imageAttempt'),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Foto tidak dapat dimuat. Periksa koneksi.'),
                      TextButton(
                          onPressed: disabled
                              ? null
                              : () => setState(() => _imageAttempt++),
                          child: const Text('Muat ulang foto')),
                    ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Foto profil', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Semantics(
          image: true,
          label: _selection == null
              ? 'Foto profil saat ini'
              : 'Preview foto profil sebelum diunggah',
          child: ClipRRect(
              borderRadius: BorderRadius.circular(12), child: preview)),
      const SizedBox(height: 8),
      const Text(
          'JPEG, PNG, atau WebP; maksimal 2 MB, dimensi 32–4096 piksel.'),
      if (_message != null) Text(_message!),
      if (widget.session.error?.errors['photo'] != null)
        Text(widget.session.error!.errors['photo']!.join('\n')),
      Wrap(spacing: 8, children: [
        OutlinedButton(
            key: const Key('photo_gallery'),
            onPressed:
                disabled || widget.picker == null ? null : () => _select(),
            child: const Text('Pilih dari galeri')),
        OutlinedButton(
            key: const Key('photo_camera'),
            onPressed: disabled || widget.picker == null
                ? null
                : () => _select(source: PhotoSource.camera),
            child: const Text('Ambil foto')),
        if (_selection != null) ...[
          FilledButton(
              key: const Key('photo_upload'),
              onPressed: disabled ? null : _upload,
              child: const Text('Unggah foto')),
          TextButton(
              onPressed: disabled
                  ? null
                  : () => setState(() {
                        _selection = null;
                        _message = null;
                      }),
              child: const Text('Batal')),
        ],
        if (photoUrl != null && _selection == null)
          TextButton(
              key: const Key('photo_delete'),
              onPressed: disabled ? null : _delete,
              child: const Text('Hapus foto')),
      ]),
    ]);
  }
}
