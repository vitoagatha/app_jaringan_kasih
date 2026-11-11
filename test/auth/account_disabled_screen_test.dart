import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/auth/application/session_controller.dart';
import 'package:app_jaringan_kasih/features/auth/presentation/auth_app.dart';
import 'package:app_jaringan_kasih/features/auth/presentation/signed_in_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth.dart';

void main() {
  const disabled = ApiException(
      'Akun Anda dinonaktifkan. Hubungi pengelola untuk bantuan.',
      statusCode: 403,
      code: 'account_disabled');

  testWidgets(
      'Disabled account restore shows login rather than the offline gate',
      (tester) async {
    final auth = FakeAuth()..onRestore = () async => throw disabled;
    await tester.pumpWidget(JaringanKasihApp(session: SessionController(auth)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth_email')), findsOneWidget);
    expect(find.text(disabled.message), findsOneWidget);
    expect(find.byType(SignedInShell), findsNothing);
    expect(find.text('Sesi belum dapat diperiksa.'), findsNothing);
  });

  testWidgets(
      'A disabled response removes the signed in screen and shows the reason',
      (tester) async {
    final auth = FakeAuth()..onRestore = () async => FakeAuth.account;
    final session = SessionController(auth);
    await tester.pumpWidget(JaringanKasihApp(session: session));
    await tester.pumpAndSettle();
    expect(find.byType(SignedInShell), findsOneWidget);
    auth.onAccountAction = () async => throw disabled;
    await session.sendVerification();
    await tester.pumpAndSettle();
    expect(find.byType(SignedInShell), findsNothing);
    expect(find.byKey(const Key('auth_email')), findsOneWidget);
    expect(find.text(disabled.message), findsOneWidget);
  });
}
