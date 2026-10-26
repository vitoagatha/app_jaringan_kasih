import 'package:flutter/material.dart';

import '../../funding/data/funding_repository.dart';
import '../../funding/presentation/funding_screen.dart';
import '../../funding/presentation/home_dashboard.dart';
import '../../profile/data/photo_selection.dart';
import '../../profile/presentation/account_home.dart';
import '../application/session_controller.dart';

class SignedInShell extends StatefulWidget {
  final SessionController session;
  final PhotoPicker? photoPicker;

  const SignedInShell({
    super.key,
    required this.session,
    this.photoPicker,
  });

  @override
  State<SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<SignedInShell> {
  int _selectedTab = 0;
  final Set<int> _visitedTabs = {0};
  FundingList _fundingMode = FundingList.explore;
  int? _categoryId;
  int? _fundingId;
  int _fundingRoute = 0;
  bool _openCreateForm = false;

  void _selectTab(int index) {
    setState(() {
      _selectedTab = index;
      _visitedTabs.add(index);
      if (index == 1) {
        _fundingMode = FundingList.explore;
        _categoryId = null;
        _fundingId = null;
        _openCreateForm = false;
        _fundingRoute++;
      } else if (index == 2) {
        _fundingMode = FundingList.wishlist;
        _categoryId = null;
        _fundingId = null;
      }
    });
  }

  void _openExplore({int? categoryId, int? fundingId}) {
    setState(() {
      _selectedTab = 1;
      _visitedTabs.add(1);
      _fundingMode = FundingList.explore;
      _categoryId = categoryId;
      _fundingId = fundingId;
      _openCreateForm = false;
      _fundingRoute++;
    });
  }

  void _openMyFundings() {
    setState(() {
      _selectedTab = 1;
      _visitedTabs.add(1);
      _fundingMode = FundingList.mine;
      _categoryId = null;
      _fundingId = null;
      _openCreateForm = false;
      _fundingRoute++;
    });
  }

  void _openCreateFunding() {
    setState(() {
      _selectedTab = 1;
      _visitedTabs.add(1);
      _fundingMode = FundingList.mine;
      _categoryId = null;
      _fundingId = null;
      _openCreateForm = true;
      _fundingRoute++;
    });
  }

  Widget _page(int index) {
    if (!_visitedTabs.contains(index)) return const SizedBox.shrink();
    final session = widget.session;
    final gateway = session.funding;
    switch (index) {
      case 0:
        return HomeDashboard(
          session: session,
          gateway: gateway,
          onExplore: () => _openExplore(),
          onCategory: (id) => _openExplore(categoryId: id),
          onOpenFunding: (id) => _openExplore(fundingId: id),
          onAccount: () => _selectTab(3),
          onWishlist: () => _selectTab(2),
          onMyFundings: _openMyFundings,
          onCreateFunding: _openCreateFunding,
        );
      case 1:
        if (gateway == null) return _noFundingMessage();
        return FundingScreen(
          key: ValueKey('funding-$_fundingRoute'),
          session: session,
          gateway: gateway,
          photoPicker: widget.photoPicker,
          initialMode: _fundingMode,
          initialCategoryId: _categoryId,
          initialFundingId: _fundingId,
          openCreateForm: _openCreateForm,
          showModeSwitcher: false,
          showBackButton: false,
          onBack: () => _selectTab(0),
        );
      case 2:
        if (gateway == null) return _noFundingMessage();
        return FundingScreen(
          key: const ValueKey('wishlist-screen'),
          session: session,
          gateway: gateway,
          photoPicker: widget.photoPicker,
          initialMode: FundingList.wishlist,
          showModeSwitcher: false,
          showBackButton: false,
          onBack: () => _selectTab(0),
        );
      default:
        return AccountHome(
          session: session,
          photoPicker: widget.photoPicker,
          onExplore: gateway == null ? null : () => _openExplore(),
          onMyFundings: gateway == null ? null : _openMyFundings,
          onWishlist: gateway == null ? null : () => _selectTab(2),
        );
    }
  }

  Widget _noFundingMessage() => Scaffold(
        appBar: AppBar(title: const Text('Jaringan Kasih')),
        body: const Center(
            child: Text('Fitur pendanaan belum tersedia pada sesi ini.')),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _selectedTab,
          children: List.generate(4, _page),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
                key: Key('nav_home'),
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Beranda'),
            NavigationDestination(
                key: Key('nav_explore'),
                icon: Icon(Icons.search),
                label: 'Jelajahi'),
            NavigationDestination(
                key: Key('nav_wishlist'),
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Wishlist'),
            NavigationDestination(
                key: Key('nav_account'),
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Akun'),
          ],
        ),
      );
}
