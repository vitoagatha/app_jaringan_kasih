import 'dart:async';

import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/auth/application/session_controller.dart';
import 'package:app_jaringan_kasih/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth.dart';

void main() {
  late FakeAuth auth;
  late SessionController session;
  setUp(() {
    auth = FakeAuth();
    session = SessionController(auth);
  });
  tearDown(() => session.dispose());

  test(
      'Background validation keeps account visible but locks interaction until result',
      () async {
    auth.onRestore = () async => FakeAuth.account;
    await session.restore();
    final pending = Completer<AuthUser?>();
    auth.onRestore = () => pending.future;
    final check = session.restore(keepView: true);
    expect(session.phase, SessionPhase.signedIn);
    expect(session.busy, isTrue);
    pending.complete(null);
    await check;
    expect(session.phase, SessionPhase.signedOut);
    expect(session.user, isNull);
  });

  test('Background network error retains retry gate instead of claiming logout',
      () async {
    auth.onRestore = () async => FakeAuth.account;
    await session.restore();
    auth.onRestore = () async => throw const ApiException('Offline');
    await session.restore(keepView: true);
    expect(session.phase, SessionPhase.unavailable);
    expect(session.error!.message, 'Offline');
  });

  test('No saved account opens signed out state', () async {
    await session.restore();
    expect(session.phase, SessionPhase.signedOut);
  });

  test('Restore failure blocks account view and retry restores session',
      () async {
    auth.onRestore = () async => throw const ApiException('Offline');
    await session.restore();
    expect(session.phase, SessionPhase.unavailable);
    auth.onRestore = () async => FakeAuth.account;
    await session.restore();
    expect(session.phase, SessionPhase.signedIn);
    expect(session.user!.id, 1);
    expect(session.error, isNull);
  });

  test('Concurrent login submissions issue only one request', () async {
    await session.restore();
    final pending = Completer<AuthUser>();
    auth.onAuthenticate = () => pending.future;
    final first = session.login('test', 'password');
    await session.login('test', 'password');
    expect(auth.loginCalls, 1);
    expect(session.busy, isTrue);
    pending.complete(FakeAuth.account);
    await first;
    expect(session.phase, SessionPhase.signedIn);
  });

  test('Login error preserves server field errors and permits retry', () async {
    await session.restore();
    auth.onAuthenticate = () async =>
        throw const ApiException('Data belum valid.', statusCode: 422, errors: {
          'email': ['Invalid']
        });
    await session.login('test', 'password');
    expect(session.phase, SessionPhase.signedOut);
    expect(session.error!.errors['email'], ['Invalid']);
    auth.onAuthenticate = () async => FakeAuth.account;
    await session.login('test', 'password');
    expect(session.phase, SessionPhase.signedIn);
    expect(session.error, isNull);
  });

  test('Failed logout stays on account and successful retry clears it',
      () async {
    auth.onRestore = () async => FakeAuth.account;
    await session.restore();
    auth.onLogout = () async => throw const ApiException('Offline');
    await session.logout();
    expect(session.phase, SessionPhase.signedIn);
    expect(session.user, isNotNull);
    auth.onLogout = () async {};
    await session.logout();
    expect(session.phase, SessionPhase.signedOut);
    expect(session.user, isNull);
  });

  test('Storage failure locks gate until restore can complete', () async {
    auth.onRestore = () async => FakeAuth.account;
    await session.restore();
    auth.onLogout = () async => throw const SessionStorageException();
    await session.logout();
    expect(session.phase, SessionPhase.unavailable);
    auth.onRestore = () async => null;
    await session.restore();
    expect(session.phase, SessionPhase.signedOut);
  });
}
