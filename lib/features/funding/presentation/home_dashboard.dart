import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/presentation/app_layout.dart';
import '../../auth/application/session_controller.dart';
import '../data/funding_repository.dart';
import 'funding_cover.dart';

class HomeDashboard extends StatefulWidget {
  final SessionController session;
  final FundingGateway? gateway;
  final VoidCallback onExplore;
  final ValueChanged<int> onCategory;
  final ValueChanged<int> onOpenFunding;
  final VoidCallback onAccount;
  final VoidCallback onWishlist;
  final VoidCallback onMyFundings;
  final VoidCallback onCreateFunding;

  const HomeDashboard({
    super.key,
    required this.session,
    required this.gateway,
    required this.onExplore,
    required this.onCategory,
    required this.onOpenFunding,
    required this.onAccount,
    required this.onWishlist,
    required this.onMyFundings,
    required this.onCreateFunding,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  List<FundingCategory> _categories = [];
  List<FundingRecord> _fundings = [];
  ApiException? _error;
  bool _loading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.gateway != null) unawaited(_load());
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _load() async {
    final gateway = widget.gateway;
    if (gateway == null) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        gateway.categories(),
        gateway.list(FundingList.explore, page: 1),
      ]);
      if (!mounted || generation != _generation) return;
      setState(() {
        _categories = results[0] as List<FundingCategory>;
        _fundings = (results[1] as FundingPage).items;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = error is ApiException
          ? error
          : const ApiException('Beranda belum dapat dimuat. Coba lagi.'));
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  String _money(int value) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
          .format(value);

  IconData _categoryIcon(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('pendidikan')) return Icons.school_outlined;
    if (normalized.contains('kesehatan')) {
      return Icons.health_and_safety_outlined;
    }
    if (normalized.contains('zakat')) return Icons.volunteer_activism_outlined;
    if (normalized.contains('lingkungan')) return Icons.park_outlined;
    if (normalized.contains('rumah')) return Icons.mosque_outlined;
    if (normalized.contains('bencana')) return Icons.crisis_alert_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user!;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text('Jaringan Kasih',
            style: Theme.of(context).textTheme.titleMedium),
        actions: [
          IconButton(
            key: const Key('home_account'),
            tooltip: 'Akun saya',
            onPressed: widget.onAccount,
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            key: const Key('auth_logout'),
            tooltip: 'Keluar',
            onPressed: widget.session.busy ? null : widget.session.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AppContent(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text('Halo, ${user.name}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('Mari hadirkan harapan lewat kebaikan bersama.'),
            const SizedBox(height: 18),
            Card(
              color: colors.primary,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mulai melakukan kebaikan',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: colors.onPrimary)),
                    const SizedBox(height: 8),
                    Text('Temukan pendanaan dan bantu komunitas bertumbuh.',
                        style: TextStyle(color: colors.onPrimary)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      FilledButton.tonalIcon(
                        key: const Key('explore_fundings'),
                        onPressed:
                            widget.session.busy ? null : widget.onExplore,
                        icon: const Icon(Icons.search),
                        label: const Text('Jelajahi pendanaan'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('create_funding_home'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: colors.onPrimary,
                            side: BorderSide(color: colors.onPrimary)),
                        onPressed:
                            widget.session.busy ? null : widget.onCreateFunding,
                        icon: const Icon(Icons.add),
                        label: const Text('Buat pendanaan'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: Text('Kategori',
                      style: Theme.of(context).textTheme.titleLarge)),
              TextButton(
                  onPressed: widget.onExplore,
                  child: const Text('Lihat semua')),
            ]),
            const SizedBox(height: 4),
            if (_loading && _categories.isEmpty)
              const LinearProgressIndicator(semanticsLabel: 'Memuat kategori')
            else if (_error != null && _categories.isEmpty)
              TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kategori gagal dimuat. Coba lagi.'))
            else if (_categories.isEmpty)
              const Text('Kategori pendanaan belum tersedia.')
            else
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: GridView.builder(
                    key: const Key('home_category_grid'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _categories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 4,
                            mainAxisExtent: 108),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return InkWell(
                        key: Key('home_category_${category.id}'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => widget.onCategory(category.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor:
                                    colors.surfaceContainerHighest,
                                child: Icon(_categoryIcon(category.name),
                                    color: colors.primary, size: 26),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(category.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: Text('Pendanaan terbaru',
                      style: Theme.of(context).textTheme.titleLarge)),
              TextButton(
                  onPressed: widget.onExplore,
                  child: const Text('Lihat semua')),
            ]),
            if (_loading && _fundings.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()))
            else if (_error != null && _fundings.isEmpty)
              AppStatusPanel(
                  title: 'Beranda belum tersedia',
                  message: _error!.displayMessage,
                  onRetry: _load)
            else if (_fundings.isEmpty)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Belum ada pendanaan yang dipublikasikan.'))
            else
              ..._fundings.take(3).map((funding) => Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: Key('home_funding_${funding.id}'),
                      onTap: () => widget.onOpenFunding(funding.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FundingCover(
                            uri: widget.gateway!.photoUri(funding),
                            label: 'Foto pendanaan ${funding.title}',
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(funding.category.name,
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                const SizedBox(height: 4),
                                Text(funding.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 4),
                                Text('Target ${_money(funding.targetAmount)}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('home_wishlist'),
              onPressed: widget.onWishlist,
              icon: const Icon(Icons.favorite_border),
              label: const Text('Buka wishlist'),
            ),
          ],
        ),
      ),
    );
  }
}
