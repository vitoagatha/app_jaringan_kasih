import 'package:app_jaringan_kasih/core/presentation/app_layout.dart';
import 'package:app_jaringan_kasih/features/auth/application/session_controller.dart';
import 'package:app_jaringan_kasih/features/auth/presentation/auth_app.dart';
import 'package:app_jaringan_kasih/features/funding/presentation/funding_editor.dart';
import 'package:app_jaringan_kasih/features/funding/data/funding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fake_auth.dart';

void main() {
  testWidgets('Narrow login with large text remains scrollable and accessible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    final semantics = tester.ensureSemantics();
    try {
      await tester
          .pumpWidget(JaringanKasihApp(session: SessionController(FakeAuth())));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('auth_submit')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'Unavailable state works on small screen with large text and retry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        theme: appTheme(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: Scaffold(
            body: AppStatusPanel(
                title: 'Sesi belum dapat diperiksa.',
                message:
                    'Server belum dapat dihubungi. Periksa koneksi dan coba lagi.',
                onRetry: () => calls++))));
    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Funding editor limits line width on desktop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        theme: appTheme(),
        home: FundingEditor(
            categories: const [FundingCategory(1, 'Pendidikan')],
            busy: false,
            onSave: (_) async => true,
            onBack: () {})));
    final field = find.byKey(const Key('funding_title'));
    expect(tester.getSize(field).width, lessThanOrEqualTo(720));
    expect(tester.getTopLeft(field).dx, greaterThan(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Unsupported browser shows a useful screen instead of a blank page',
      (tester) async {
    await tester.pumpWidget(const UnsupportedPlatformApp());
    expect(find.text('Gunakan aplikasi Android atau desktop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
