import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/session_controller.dart';
import '../data/funding_repository.dart';
import 'funding_editor.dart';
import '../../../core/presentation/app_layout.dart';
import '../../profile/data/photo_selection.dart';
import 'funding_cover.dart';

class FundingScreen extends StatefulWidget {
  final SessionController session;
  final FundingGateway gateway;
  final VoidCallback onBack;
  final PhotoPicker? photoPicker;
  final FundingList initialMode;
  final int? initialCategoryId;
  final int? initialFundingId;
  final bool openCreateForm;
  final bool showModeSwitcher;
  final bool showBackButton;
  const FundingScreen(
      {super.key,
      required this.session,
      required this.gateway,
      required this.onBack,
      this.photoPicker,
      this.initialMode = FundingList.explore,
      this.initialCategoryId,
      this.initialFundingId,
      this.openCreateForm = false,
      this.showModeSwitcher = true,
      this.showBackButton = true});
  @override
  State<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends State<FundingScreen> {
  final _search = TextEditingController();
  List<FundingCategory> _categories = [];
  FundingPage? _result;
  FundingList _mode = FundingList.explore;
  int? _category;
  String? _status;
  int _requestedPage = 1;
  bool _loading = false;
  bool _mutating = false;
  int _generation = 0;
  ApiException? _error;
  FundingRecord? _detail;
  FundingRecord? _editing;
  bool _editor = false;
  bool _picking = false;
  String? _notice;
  bool _initialDetailConsumed = false;
  bool _initialCreateConsumed = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _category = widget.initialCategoryId;
    unawaited(_load());
  }

  @override
  void dispose() {
    _generation++;
    _search.dispose();
    super.dispose();
  }

  Future<void> _failure(Object failure) async {
    if (!mounted) return;
    if (failure is ApiException && failure.isUnauthenticated) {
      await widget.session.restore();
    }
    if (mounted) {
      setState(() => _error = failure is ApiException
          ? failure
          : const ApiException(
              'Pendanaan belum dapat dimuat. Silakan coba lagi.'));
    }
  }

  Future<void> _load({int page = 1}) async {
    final generation = ++_generation;
    _requestedPage = page;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories =
          _categories.isEmpty ? await widget.gateway.categories() : _categories;
      if (!mounted || generation != _generation) return;
      final result = await widget.gateway.list(_mode,
          page: page,
          search: _search.text,
          categoryId: _category,
          status: _status);
      if (mounted && generation == _generation) {
        setState(() {
          _categories = categories;
          _result = result;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) await _failure(error);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
    final initialId = widget.initialFundingId;
    if (mounted &&
        generation == _generation &&
        widget.openCreateForm &&
        !_initialCreateConsumed &&
        _categories.isNotEmpty) {
      _initialCreateConsumed = true;
      setState(() {
        _editor = true;
        _notice = null;
      });
    }
    if (mounted &&
        generation == _generation &&
        !_initialDetailConsumed &&
        initialId != null) {
      _initialDetailConsumed = true;
      for (final item in _result?.items ?? const <FundingRecord>[]) {
        if (item.id == initialId) {
          await _open(item);
          break;
        }
      }
    }
  }

  Future<void> _open(FundingRecord item) async {
    if (_loading || _mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final itemDetail = await widget.gateway
          .detail(item.id, mine: item.ownerId == widget.session.user!.id);
      if (mounted) setState(() => _detail = itemDetail);
    } catch (error) {
      await _failure(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _wishlist(FundingRecord item) async {
    if (_mutating || _loading) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      await widget.gateway.setWishlist(item.id, !item.saved);
      if (!mounted) return;
      if (_detail?.id == item.id) {
        final updated = await widget.gateway
            .detail(item.id, mine: item.ownerId == widget.session.user!.id);
        if (mounted) setState(() => _detail = updated);
      }
      if (mounted) {
        setState(() => _notice =
            item.saved ? 'Dihapus dari wishlist.' : 'Ditambahkan ke wishlist.');
        await _load(page: _requestedPage);
        if (mounted &&
            _error == null &&
            _result != null &&
            _result!.items.isEmpty &&
            _requestedPage > 1) {
          await _load(page: _requestedPage - 1);
        }
      }
    } catch (error) {
      await _failure(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<bool> _save(FundingDraft draft) async {
    if (_mutating) return false;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final saved = await widget.gateway.save(draft, id: _editing?.id);
      if (!mounted) return false;
      setState(() {
        _editor = false;
        _editing = null;
        _detail = saved;
        _notice = 'Pendanaan disimpan.';
      });
      await _load();
      return true;
    } catch (error) {
      await _failure(error);
      return false;
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  String money(int amount) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
          .format(amount);

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop || _mutating || _loading || _picking) return;
          if (_editor) {
            setState(() {
              _editor = false;
              _editing = null;
              _error = null;
            });
          } else if (_detail != null) {
            setState(() {
              _detail = null;
              _error = null;
            });
          } else {
            widget.onBack();
          }
        },
        child: _content(context),
      );

  Widget _content(BuildContext context) {
    if (_editor) {
      return FundingEditor(
          categories: _categories,
          initial: _editing,
          busy: _mutating,
          error: _error,
          picker: widget.photoPicker,
          initialPhoto:
              _editing == null ? null : widget.gateway.photoUri(_editing!),
          photoPurpose:
              'funding:${widget.session.user!.id}:${_editing?.id ?? 'new'}',
          onPickingChanged: (busy) {
            _picking = busy;
            widget.session.externalInteraction = busy;
          },
          onSave: _save,
          onBack: () => setState(() {
                _editor = false;
                _editing = null;
                _error = null;
              }));
    }
    final detail = _detail;
    if (detail != null) {
      return Scaffold(
          appBar: AppBar(
              title: const Text('Detail pendanaan'),
              leading: IconButton(
                  tooltip: 'Kembali',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _mutating
                      ? null
                      : () => setState(() {
                            _detail = null;
                            _error = null;
                          }))),
          body: AppContent(
              child: ListView(padding: const EdgeInsets.all(24), children: [
            FundingCover(
                key: const Key('funding_detail_cover'),
                uri: widget.gateway.photoUri(detail),
                label: 'Foto pendanaan ${detail.title}'),
            const SizedBox(height: 16),
            Text(detail.title,
                style: Theme.of(context).textTheme.headlineSmall),
            Text(
                '${detail.category.name} · ${detail.status == 'draft' ? 'Draft' : 'Published'}'),
            Text('Oleh ${detail.ownerName}'),
            const SizedBox(height: 16),
            Text('Target ${money(detail.targetAmount)}'),
            const SizedBox(height: 16),
            SelectableText(detail.description),
            const SizedBox(height: 24),
            if (_error != null) Text(_error!.displayMessage),
            if (_notice != null) Text(_notice!),
            if (detail.status == 'published')
              OutlinedButton.icon(
                  key: const Key('detail_wishlist'),
                  onPressed:
                      _mutating || _loading ? null : () => _wishlist(detail),
                  icon: Icon(
                      detail.saved ? Icons.favorite : Icons.favorite_border),
                  label: Text(detail.saved
                      ? 'Hapus dari wishlist'
                      : 'Simpan ke wishlist')),
            if (detail.ownerId == widget.session.user!.id)
              FilledButton(
                  key: const Key('edit_funding'),
                  onPressed: _mutating || _loading
                      ? null
                      : () => setState(() {
                            _editing = detail;
                            _editor = true;
                            _error = null;
                          }),
                  child: const Text('Edit pendanaan')),
          ])));
    }
    final disabled = _loading || _mutating;
    final title = switch (_mode) {
      FundingList.explore => 'Pendanaan',
      FundingList.mine => 'Pendanaan saya',
      FundingList.wishlist => 'Wishlist',
    };
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: widget.showBackButton,
          title: Text(title),
          leading: widget.showBackButton
              ? IconButton(
                  tooltip: 'Kembali ke akun',
                  onPressed: disabled ? null : widget.onBack,
                  icon: const Icon(Icons.arrow_back))
              : null),
      body: AppContent(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        if (widget.showModeSwitcher)
          Wrap(
              spacing: 8,
              children: FundingList.values
                  .map((mode) => ChoiceChip(
                      key: Key('funding_tab_${mode.name}'),
                      label: Text({
                        FundingList.explore: 'Jelajahi',
                        FundingList.mine: 'Milik saya',
                        FundingList.wishlist: 'Wishlist'
                      }[mode]!),
                      selected: _mode == mode,
                      onSelected: disabled
                          ? null
                          : (_) {
                              setState(() {
                                _mode = mode;
                                _status = null;
                                _notice = null;
                              });
                              unawaited(_load());
                            }))
                  .toList()),
        const SizedBox(height: 16),
        TextField(
            key: const Key('funding_search'),
            controller: _search,
            enabled: !disabled,
            maxLength: 100,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
                labelText: 'Cari judul pendanaan',
                suffixIcon: IconButton(
                    tooltip: 'Cari',
                    onPressed: disabled ? null : () => _load(),
                    icon: const Icon(Icons.search)))),
        DropdownButtonFormField<int>(
            hint: const Text('Semua kategori'),
            value: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: [
              const DropdownMenuItem<int>(
                  value: null, child: Text('Semua kategori')),
              ..._categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis)))
            ],
            onChanged: disabled
                ? null
                : (id) {
                    setState(() => _category = id);
                    unawaited(_load());
                  }),
        if (_mode == FundingList.mine)
          DropdownButtonFormField<String>(
              hint: const Text('Semua status'),
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua status')),
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'published', child: Text('Published'))
              ],
              onChanged: disabled
                  ? null
                  : (status) {
                      setState(() => _status = status);
                      unawaited(_load());
                    }),
        const SizedBox(height: 12),
        const Text('Urutan: terbaru'),
        FilledButton(
            key: const Key('create_funding'),
            onPressed: disabled || _categories.isEmpty
                ? null
                : () => setState(() {
                      _editing = null;
                      _editor = true;
                      _error = null;
                      _notice = null;
                    }),
            child: const Text('Buat pendanaan')),
        if (_notice != null) Text(_notice!),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Column(children: [
            Text(_error!.displayMessage),
            OutlinedButton(
                onPressed: () => _load(page: _requestedPage),
                child: const Text('Coba lagi'))
          ])
        else if (_result != null) ...[
          Text('${_result!.total} pendanaan'),
          if (_result!.items.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada pendanaan yang sesuai.')),
          ..._result!.items.map((item) => Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                        onTap: disabled ? null : () => _open(item),
                        child: FundingCover(
                            key: Key('funding_cover_${item.id}'),
                            uri: widget.gateway.photoUri(item),
                            label: 'Foto pendanaan ${item.title}')),
                    ListTile(
                        key: Key('funding_${item.id}'),
                        onTap: disabled ? null : () => _open(item),
                        title: Text(item.title),
                        subtitle: Text(
                            '${item.category.name} · ${money(item.targetAmount)}\n${item.status}'),
                        trailing: item.status == 'published'
                            ? IconButton(
                                tooltip: item.saved
                                    ? 'Hapus dari wishlist'
                                    : 'Simpan ke wishlist',
                                onPressed:
                                    disabled ? null : () => _wishlist(item),
                                icon: Icon(item.saved
                                    ? Icons.favorite
                                    : Icons.favorite_border))
                            : const Icon(Icons.edit_note)),
                  ]))),
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                    key: const Key('funding_previous'),
                    onPressed: disabled || _result!.page <= 1
                        ? null
                        : () => _load(page: _result!.page - 1),
                    child: const Text('Sebelumnya')),
                Text('${_result!.page}/${_result!.lastPage}'),
                TextButton(
                    key: const Key('funding_next'),
                    onPressed: disabled || _result!.page >= _result!.lastPage
                        ? null
                        : () => _load(page: _result!.page + 1),
                    child: const Text('Berikutnya')),
              ]),
        ],
      ])),
    );
  }
}
