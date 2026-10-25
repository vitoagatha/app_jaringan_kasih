import 'dart:async';

import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/auth/application/session_controller.dart';
import 'package:app_jaringan_kasih/features/auth/data/auth_repository.dart';
import 'package:app_jaringan_kasih/features/auth/presentation/auth_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth.dart';

void main() {
  Future<void> open(WidgetTester tester, FakeAuth auth) async {
    await tester.pumpWidget(JaringanKasihApp(session: SessionController(auth)));
    await tester.pumpAndSettle();
  }

  Future<void> enterCredentials(WidgetTester tester) async {
    await tester.enterText(
        find.byKey(const Key('auth_email')), 'belajar@example.test');
    await tester.enterText(
        find.byKey(const Key('auth_password')), '  password  ');
  }

  testWidgets('Empty form is rejected without submitting a request',
      (tester) async {
    final auth = FakeAuth();
    await open(tester, auth);
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
    expect(auth.loginCalls, 0);
  });

  testWidgets('Login prevents repeat submit and logout returns to empty form',
      (tester) async {
    final auth = FakeAuth();
    final pending = Completer<AuthUser>();
    auth.onAuthenticate = () => pending.future;
    await open(tester, auth);
    await enterCredentials(tester);
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('auth_submit')))
            .onPressed,
        isNull);
    expect(auth.loginCalls, 1);
    expect(auth.submittedPassword, '  password  ');
    pending.complete(FakeAuth.account);
    await tester.pumpAndSettle();
    expect(find.text('Halo, Akun Belajar'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('auth_logout')), 250);
    await tester.tap(find.byKey(const Key('auth_logout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth_email')), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('auth_password')))
            .controller!
            .text,
        isEmpty);
  });

  testWidgets(
      'Registration rejects mismatch then accepts matching confirmation',
      (tester) async {
    final auth = FakeAuth();
    await open(tester, auth);
    await tester.tap(find.byKey(const Key('auth_toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth_name')), 'Akun Belajar');
    await enterCredentials(tester);
    await tester.enterText(find.byKey(const Key('auth_confirmation')), 'wrong');
    await tester.ensureVisible(find.byKey(const Key('auth_submit')));
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi password tidak cocok.'), findsOneWidget);
    expect(auth.registerCalls, 0);
    await tester.enterText(
        find.byKey(const Key('auth_confirmation')), '  password  ');
    await tester.ensureVisible(find.byKey(const Key('auth_submit')));
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();
    expect(auth.registerCalls, 1);
    expect(auth.submittedConfirmation, '  password  ');
    expect(find.text('Halo, Akun Belajar'), findsOneWidget);
  });

  testWidgets('Returning from background rechecks a revoked session',
      (tester) async {
    final auth = FakeAuth();
    auth.onRestore = () async => FakeAuth.account;
    await open(tester, auth);
    expect(find.text('Halo, Akun Belajar'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    auth.onRestore = () async => null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Halo, Akun Belajar'), findsNothing);
    expect(find.byKey(const Key('auth_email')), findsOneWidget);
  });

  testWidgets('Server validation is displayed next to email field',
      (tester) async {
    final auth = FakeAuth();
    auth.onAuthenticate = () async =>
        throw const ApiException('Data belum valid.', statusCode: 422, errors: {
          'email': ['Email sudah digunakan.']
        });
    await open(tester, auth);
    await enterCredentials(tester);
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email sudah digunakan.'), findsOneWidget);
    expect(find.text('Data belum valid.'), findsOneWidget);
  });

  testWidgets(
      'Restore shows loading and retry instead of opening login offline',
      (tester) async {
    final auth = FakeAuth();
    final pending = Completer<AuthUser?>();
    auth.onRestore = () => pending.future;
    await tester.pumpWidget(JaringanKasihApp(session: SessionController(auth)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(const ApiException('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.byKey(const Key('auth_email')), findsNothing);
    auth.onRestore = () async => FakeAuth.account;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Halo, Akun Belajar'), findsOneWidget);
  });
}
