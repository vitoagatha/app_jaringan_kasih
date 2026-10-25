import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../data/funding_repository.dart';
import '../../../core/presentation/app_layout.dart';
import '../../../core/network/api_client.dart';
import '../../profile/data/photo_selection.dart';
import 'funding_cover.dart';

class FundingEditor extends StatefulWidget {
  final List<FundingCategory> categories;
  final FundingRecord? initial;
  final Future<bool> Function(FundingDraft) onSave;
  final VoidCallback onBack;
  final ApiException? error;
  final bool busy;
  final PhotoPicker? picker;
  final String photoPurpose;
  final Uri? initialPhoto;
  final ValueChanged<bool>? onPickingChanged;
  const FundingEditor(
      {super.key,
      required this.categories,
      required this.onSave,
      required this.onBack,
      required this.busy,
      this.initial,
      this.error,
      this.picker,
      this.photoPurpose = 'funding:new',
      this.initialPhoto,
      this.onPickingChanged});
  @override
  State<FundingEditor> createState() => _FundingEditorState();
}

class _FundingEditorState extends State<FundingEditor> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  int? _category;
  String _status = 'draft';
  MultipartPhoto? _photo;
  bool _removePhoto = false;
  bool _picking = false;
  String? _photoError;
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _title.text = initial.title;
      _description.text = initial.description;
      _amount.text = '${initial.targetAmount}';
      _category = initial.category.id;
      _status = initial.status;
    }
    if (widget.picker != null) unawaited(_pick(recover: true));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    widget.onPickingChanged?.call(false);
    super.dispose();
  }

  InputDecoration decoration(String label, String field) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      errorText: widget.error?.errors[field]?.join('\n'));
  Future<void> _save() async {
    if (widget.busy || _picking || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.onSave(FundingDraft(
        title: _title.text,
        description: _description.text,
        categoryId: _category!,
        targetAmount: int.parse(_amount.text),
        status: _status,
        photo: _photo,
        removePhoto: _removePhoto));
  }

  Future<void> _pick(
      {PhotoSource source = PhotoSource.gallery, bool recover = false}) async {
    if (_picking || widget.busy || widget.picker == null) return;
    _picking = true;
    widget.onPickingChanged?.call(true);
    if (!recover) setState(() => _photoError = null);
    try {
      final photo = recover
          ? await widget.picker!.recover(purpose: widget.photoPurpose)
          : await widget.picker!.pick(source, purpose: widget.photoPurpose);
      if (mounted && photo != null) {
        setState(() {
          _photo = photo;
          _removePhoto = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _photoError = error is ApiException
            ? error.displayMessage
            : 'Foto tidak dapat dibaca. Silakan pilih kembali.');
      }
    } finally {
      widget.onPickingChanged?.call(false);
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(
                widget.initial == null ? 'Buat pendanaan' : 'Edit pendanaan'),
            leading: IconButton(
                onPressed: widget.busy || _picking ? null : widget.onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali')),
        body: AppContent(
            maxWidth: 720,
            child: Form(
                key: _form,
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Foto pendanaan',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          FundingCover(
                              uri: _removePhoto ? null : widget.initialPhoto,
                              preview: _photo?.bytes,
                              label: _photo != null
                                  ? 'Preview foto pendanaan sebelum disimpan'
                                  : 'Foto pendanaan saat ini'),
                          const SizedBox(height: 8),
                          const Text(
                              'JPEG, PNG, atau WebP; maksimal 2 MB, dimensi 32–4096 piksel. Foto disimpan bersama pendanaan.'),
                          if (_photoError != null) Text(_photoError!),
                          if (widget.error?.errors['photo'] != null)
                            Text(widget.error!.errors['photo']!.join('\n')),
                          Wrap(spacing: 8, children: [
                            OutlinedButton(
                                key: const Key('funding_photo_gallery'),
                                onPressed: widget.busy ||
                                        _picking ||
                                        widget.picker == null
                                    ? null
                                    : () => _pick(),
                                child: const Text('Pilih dari galeri')),
                            OutlinedButton(
                                key: const Key('funding_photo_camera'),
                                onPressed: widget.busy ||
                                        _picking ||
                                        widget.picker == null
                                    ? null
                                    : () => _pick(source: PhotoSource.camera),
                                child: const Text('Ambil foto')),
                            if (_photo != null)
                              TextButton(
                                  key: const Key('funding_photo_cancel'),
                                  onPressed: widget.busy || _picking
                                      ? null
                                      : () => setState(() => _photo = null),
                                  child: const Text('Batalkan foto pilihan')),
                            if (widget.initialPhoto != null &&
                                !_removePhoto &&
                                _photo == null)
                              TextButton(
                                  key: const Key('funding_photo_remove'),
                                  onPressed: widget.busy || _picking
                                      ? null
                                      : () =>
                                          setState(() => _removePhoto = true),
                                  child: const Text('Hapus foto')),
                            if (_removePhoto)
                              TextButton(
                                  onPressed: widget.busy || _picking
                                      ? null
                                      : () =>
                                          setState(() => _removePhoto = false),
                                  child: const Text('Urungkan hapus foto')),
                          ]),
                          const SizedBox(height: 16),
                          TextFormField(
                              key: const Key('funding_title'),
                              controller: _title,
                              enabled: !widget.busy,
                              decoration: decoration('Judul', 'title'),
                              validator: (value) => value == null ||
                                      value.trim().isEmpty ||
                                      value.trim().runes.length > 150
                                  ? 'Judul wajib diisi, maksimal 150 karakter.'
                                  : null),
                          const SizedBox(height: 16),
                          TextFormField(
                              key: const Key('funding_description'),
                              controller: _description,
                              enabled: !widget.busy,
                              maxLines: 6,
                              decoration:
                                  decoration('Deskripsi', 'description'),
                              validator: (value) =>
                                  (value?.trim().runes.length ?? 0) < 20 ||
                                          (value?.trim().runes.length ?? 0) >
                                              10000
                                      ? 'Deskripsi harus 20–10000 karakter.'
                                      : null),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                              key: const Key('funding_category'),
                              value: _category,
                              isExpanded: true,
                              decoration: decoration('Kategori', 'category_id'),
                              items: widget.categories
                                  .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: widget.busy
                                  ? null
                                  : (id) => setState(() => _category = id),
                              validator: (id) =>
                                  id == null ? 'Pilih kategori.' : null),
                          const SizedBox(height: 16),
                          TextFormField(
                              key: const Key('funding_target'),
                              controller: _amount,
                              enabled: !widget.busy,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: decoration(
                                      'Target dana (Rp)', 'target_amount')
                                  .copyWith(
                                      helperText:
                                          'Masukkan angka tanpa titik atau koma.',
                                      helperMaxLines: 2),
                              validator: (value) {
                                final amount = int.tryParse(value ?? '');
                                return amount == null ||
                                        amount < 1 ||
                                        amount > 1000000000000
                                    ? 'Target dana harus Rp1–Rp1.000.000.000.000.'
                                    : null;
                              }),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                              key: const Key('funding_status'),
                              value: _status,
                              decoration: decoration('Status', 'status'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'draft',
                                    child: Text('Draft — hanya saya',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(
                                    value: 'published',
                                    child: Text('Published — tampil umum',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis))
                              ],
                              onChanged: widget.busy
                                  ? null
                                  : (value) =>
                                      setState(() => _status = value!)),
                          const SizedBox(height: 16),
                          if (widget.error != null)
                            Text(widget.error!.displayMessage,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                          FilledButton(
                              key: const Key('funding_save'),
                              onPressed: widget.busy || _picking ? null : _save,
                              child: Text(widget.busy
                                  ? 'Menyimpan...'
                                  : 'Simpan pendanaan')),
                        ])))),
      );
}
