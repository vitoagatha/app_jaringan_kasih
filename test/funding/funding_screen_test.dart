import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/auth/application/session_controller.dart';
import 'package:app_jaringan_kasih/features/auth/presentation/auth_app.dart';
import 'package:app_jaringan_kasih/features/funding/data/funding_repository.dart';
import 'package:app_jaringan_kasih/features/funding/presentation/funding_screen.dart';
import 'package:app_jaringan_kasih/features/funding/presentation/funding_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fake_auth.dart';

const record = FundingRecord(
    id: 1,
    title: 'Pendanaan contoh',
    description: 'Deskripsi lengkap pendanaan untuk pengujian.',
    targetAmount: 1000000,
    ownerId: 1,
    ownerName: 'Pemilik',
    category: FundingCategory(1, 'Pendidikan'),
    status: 'published',
    saved: false);

class FakeFunding implements FundingGateway {
  @override
  Uri? photoUri(FundingRecord funding) => funding.photoUrl == null
      ? null
      : Uri.parse('http://127.0.0.1:8000${funding.photoUrl}');
  int calls = 0;
  int page = 1;
  bool fail = false;
  bool saved = false;
  FundingList? mode;
  String? search;
  FundingDraft? submitted;
  FundingRecord current = record;
  @override
  Future<List<FundingCategory>> categories() async =>
      [const FundingCategory(1, 'Pendidikan')];
  @override
  Future<FundingPage> list(FundingList mode,
      {int page = 1,
      String search = '',
      int? categoryId,
      String? status}) async {
    calls++;
    this.page = page;
    this.mode = mode;
    this.search = search;
    if (fail) throw const ApiException('Server tidak tersedia.');
    return FundingPage(items: [current], page: page, lastPage: 2, total: 11);
  }

  @override
  Future<FundingRecord> detail(int id, {bool mine = false}) async => current;
  @override
  Future<FundingRecord> save(FundingDraft draft, {int? id}) async {
    submitted = draft;
    return current = FundingRecord(
        id: id ?? 2,
        title: draft.title,
        description: draft.description,
        targetAmount: draft.targetAmount,
        ownerId: 1,
        ownerName: 'Pemilik',
        category: const FundingCategory(1, 'Pendidikan'),
        status: draft.status,
        saved: false);
  }

  @override
  Future<void> setWishlist(int id, bool save) async {
    saved = save;
    current = FundingRecord(
        id: 1,
        title: record.title,
        description: record.description,
        targetAmount: record.targetAmount,
        ownerId: 1,
        ownerName: record.ownerName,
        category: record.category,
        status: record.status,
        saved: save);
  }
}

void main() {
  Future<void> open(WidgetTester tester, FakeFunding gateway) async {
    final auth = FakeAuth()..onRestore = () async => FakeAuth.account;
    final session = SessionController(auth, fundingGateway: gateway);
    await session.restore();
    addTearDown(session.dispose);
    await tester.pumpWidget(MaterialApp(
        home:
            FundingScreen(session: session, gateway: gateway, onBack: () {})));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(find.byKey(key), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('List loads API data and pagination requests next page',
      (tester) async {
    final gateway = FakeFunding();
    await open(tester, gateway);
    await tap(tester, const Key('funding_next'));
    expect(gateway.page, 2);
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('List and detail display the cover URI returned by the API',
      (tester) async {
    final gateway = FakeFunding()
      ..current = FundingRecord(
          id: record.id,
          title: record.title,
          description: record.description,
          targetAmount: record.targetAmount,
          ownerId: record.ownerId,
          ownerName: record.ownerName,
          category: record.category,
          status: record.status,
          saved: false,
          photoUrl: '/storage/fundings/cover.png');
    await open(tester, gateway);
    final expected =
        Uri.parse('http://127.0.0.1:8000/storage/fundings/cover.png');
    expect(
        tester
            .widget<FundingCover>(find.byKey(const Key('funding_cover_1')))
            .uri,
        expected);
    await tap(tester, const Key('funding_1'));
    expect(
        tester
            .widget<FundingCover>(find.byKey(const Key('funding_detail_cover')))
            .uri,
        expected);
  });

  testWidgets('Account opens the funding workspace through the shared session',
      (tester) async {
    final gateway = FakeFunding();
    final auth = FakeAuth()..onRestore = () async => FakeAuth.account;
    final session = SessionController(auth, fundingGateway: gateway);
    await tester.pumpWidget(JaringanKasihApp(session: session));
    await tester.pumpAndSettle();
    await tap(tester, const Key('explore_fundings'));
    expect(find.byKey(const Key('funding_tab_explore')), findsOneWidget);
    expect(gateway.calls, 1);
  });

  testWidgets('Search and wishlist switch reset pagination and send filters',
      (tester) async {
    final gateway = FakeFunding();
    await open(tester, gateway);
    await tester.enterText(find.byKey(const Key('funding_search')), 'sekolah');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(gateway.search, 'sekolah');
    await tap(tester, const Key('funding_tab_wishlist'));
    expect(gateway.mode, FundingList.wishlist);
    expect(gateway.page, 1);
  });

  testWidgets('Detail can save wishlist and open owner editor', (tester) async {
    final gateway = FakeFunding();
    await open(tester, gateway);
    await tap(tester, const Key('funding_1'));
    await tap(tester, const Key('detail_wishlist'));
    expect(gateway.saved, isTrue);
    await tap(tester, const Key('edit_funding'));
    expect(find.text('Edit pendanaan'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('funding_title')))
            .controller!
            .text,
        record.title);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Detail pendanaan'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('funding_tab_explore')), findsOneWidget);
  });

  testWidgets('Create validates empty form before sending data',
      (tester) async {
    final gateway = FakeFunding();
    await open(tester, gateway);
    await tap(tester, const Key('create_funding'));
    await tap(tester, const Key('funding_save'));
    expect(gateway.submitted, isNull);
    expect(find.text('Pilih kategori.'), findsOneWidget);
  });

  testWidgets('Create draft sends category amount and status', (tester) async {
    final gateway = FakeFunding();
    await open(tester, gateway);
    await tap(tester, const Key('create_funding'));
    await tester.enterText(
        find.byKey(const Key('funding_title')), 'Pendanaan baru');
    await tester.enterText(find.byKey(const Key('funding_description')),
        'Deskripsi yang cukup panjang untuk pendanaan.');
    await tap(tester, const Key('funding_category'));
    await tester.tap(find.text('Pendidikan').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('funding_target')), '250000');
    await tap(tester, const Key('funding_save'));
    expect(gateway.submitted!.status, 'draft');
    expect(gateway.submitted!.targetAmount, 250000);
    expect(find.text('Detail pendanaan'), findsOneWidget);
  });

  testWidgets('List error offers retry without showing stale data',
      (tester) async {
    final gateway = FakeFunding()..fail = true;
    await open(tester, gateway);
    expect(find.text('Server tidak tersedia.'), findsOneWidget);
    gateway.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Server tidak tersedia.'), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const Key('funding_1')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('funding_1')), findsOneWidget);
  });

  testWidgets('Background session check preserves the funding draft',
      (tester) async {
    final gateway = FakeFunding();
    final auth = FakeAuth()..onRestore = () async => FakeAuth.account;
    final session = SessionController(auth, fundingGateway: gateway);
    await tester.pumpWidget(JaringanKasihApp(session: session));
    await tester.pumpAndSettle();
    await tap(tester, const Key('explore_fundings'));
    await tap(tester, const Key('create_funding'));
    await tester.enterText(
        find.byKey(const Key('funding_title')), 'Draft belum disimpan');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('funding_title')))
            .controller!
            .text,
        'Draft belum disimpan');
    expect(gateway.submitted, isNull);
  });

  testWidgets(
      'Narrow funding list with large text does not overflow pagination',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    await open(tester, FakeFunding());
    await tap(tester, const Key('funding_next'));
    expect(find.text('2/2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
