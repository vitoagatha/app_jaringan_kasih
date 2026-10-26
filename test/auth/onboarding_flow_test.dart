import 'dart:async';

import 'package:app_jaringan_kasih/features/auth/application/session_controller.dart';
import 'package:app_jaringan_kasih/features/auth/data/onboarding_store.dart';
import 'package:app_jaringan_kasih/features/auth/presentation/auth_app.dart';
import 'package:app_jaringan_kasih/features/auth/presentation/signed_in_shell.dart';
import 'package:app_jaringan_kasih/features/auth/presentation/welcome_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth.dart';

class MemoryOnboardingStore implements OnboardingStore {
  bool completed = false;
  Future<bool> Function()? onRead;

  @override
  Future<bool> hasCompleted() async =>
      onRead == null ? completed : await onRead!();

  @override
  Future<void> complete() async => completed = true;
}

void main() {
  Future<void> open(WidgetTester tester, MemoryOnboardingStore store,
      {bool signedIn = false}) async {
    final auth = FakeAuth();
    if (signedIn) auth.onRestore = () async => FakeAuth.account;
    await tester.pumpWidget(JaringanKasihApp(
        session: SessionController(auth), onboardingStore: store));
    await tester.pumpAndSettle();
  }

  testWidgets('Startup waits for onboarding status before opening a screen',
      (tester) async {
    final read = Completer<bool>();
    final store = MemoryOnboardingStore()..onRead = () => read.future;
    await tester.pumpWidget(JaringanKasihApp(
        session: SessionController(FakeAuth()), onboardingStore: store));
    await tester.pump();
    expect(find.byType(StartupSplash), findsOneWidget);
    expect(find.byKey(const Key('auth_email')), findsNothing);
    read.complete(false);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeOnboarding), findsOneWidget);
    expect(find.byType(StartupSplash), findsNothing);
  });

  for (final action in ['Mulai sekarang', 'Lewati']) {
    testWidgets('$action completes onboarding and next launch opens login',
        (tester) async {
      final store = MemoryOnboardingStore();
      await open(tester, store);
      expect(find.byType(WelcomeOnboarding), findsOneWidget);
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(store.completed, isTrue);
      expect(find.byKey(const Key('auth_email')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await open(tester, store);
      expect(find.byType(WelcomeOnboarding), findsNothing);
      expect(find.byKey(const Key('auth_email')), findsOneWidget);
    });
  }

  testWidgets('Completed onboarding and valid session open home',
      (tester) async {
    final store = MemoryOnboardingStore()..completed = true;
    await open(tester, store, signedIn: true);
    expect(find.byType(SignedInShell), findsOneWidget);
    expect(find.byType(WelcomeOnboarding), findsNothing);
    expect(find.byKey(const Key('auth_email')), findsNothing);
  });

  testWidgets('Unreadable onboarding status does not silently skip the guide',
      (tester) async {
    final store = MemoryOnboardingStore()
      ..onRead = () async => throw StateError('Storage unavailable');
    await open(tester, store);
    expect(find.byType(WelcomeOnboarding), findsOneWidget);
    expect(find.byKey(const Key('auth_email')), findsNothing);
    await tester.tap(find.byKey(const Key('onboarding_continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth_email')), findsOneWidget);
  });
}
