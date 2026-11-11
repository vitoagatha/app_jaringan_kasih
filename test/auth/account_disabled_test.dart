import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/auth/application/session_controller.dart';
import 'package:app_jaringan_kasih/features/auth/data/auth_repository.dart';
import 'package:app_jaringan_kasih/features/auth/data/token_store.dart';
import 'package:app_jaringan_kasih/features/funding/data/funding_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class StatusTokenStore implements TokenStore {
  String? value = '1|old-session';
  bool failDelete = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> delete() async {
    if (failDelete) throw StateError('Storage unavailable');
    value = null;
  }
}

void main() {
  const user = {
    'id': 1,
    'name': 'Akun Belajar',
    'email': 'belajar@example.test'
  };
  const message = 'Akun Anda dinonaktifkan. Hubungi pengelola untuk bantuan.';
  late HttpServer server;
  late AuthRepository auth;
  late SessionController session;
  late StatusTokenStore store;
  late Future<void> Function(HttpRequest request) handler;
  var disabled = false;

  Future<void> reply(HttpRequest request, int status, Object? data,
      {String? code}) async {
    await request.drain<void>();
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({
      'success': status < 400,
      'message': code == 'account_disabled' ? message : 'Test response',
      if (status < 400) 'data': data else 'errors': {},
      if (code != null) 'code': code,
    }));
    await request.response.close();
  }

  setUp(() async {
    disabled = false;
    store = StatusTokenStore();
    handler = (request) async {
      if (disabled) {
        return reply(request, 403, null, code: 'account_disabled');
      }
      return reply(request, 200, {'user': user});
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async => handler(request));
    auth = AuthRepository(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
        store: store,
        deviceName: 'status-test');
    session = SessionController(auth);
  });

  tearDown(() async {
    session.dispose();
    await server.close(force: true);
  });

  test(
      'Disabled response from a funding request signs out and clears the token',
      () async {
    await session.restore();
    expect(session.phase, SessionPhase.signedIn);
    disabled = true;
    await expectLater(
        auth.funding.list(FundingList.mine),
        throwsA(isA<ApiException>()
            .having((e) => e.isAccountDisabled, 'disabled', true)));
    expect(session.phase, SessionPhase.signedOut);
    expect(session.user, isNull);
    expect(store.value, isNull);
    expect(session.error?.message, message);
  });

  test('Restoring a disabled account opens login with the disabled message',
      () async {
    disabled = true;
    await session.restore();
    expect(session.phase, SessionPhase.signedOut);
    expect(session.user, isNull);
    expect(store.value, isNull);
    expect(session.error?.isAccountDisabled, isTrue);
  });

  test('An ordinary permission failure does not discard an active session',
      () async {
    await session.restore();
    handler = (request) => reply(request, 403, null);
    await expectLater(
        auth.funding.list(FundingList.mine), throwsA(isA<ApiException>()));
    expect(session.phase, SessionPhase.signedIn);
    expect(store.value, '1|old-session');
  });

  test('An invalid old session is cleared even when a 401 response is not JSON',
      () async {
    await session.restore();
    handler = (request) async {
      request.response.statusCode = 401;
      request.response.write('<html>Unauthenticated</html>');
      await request.response.close();
    };
    await expectLater(
        auth.funding.list(FundingList.mine), throwsA(isA<ApiException>()));
    expect(session.phase, SessionPhase.signedOut);
    expect(store.value, isNull);
  });

  test('Storage deletion failure locks the gate until the token can be cleared',
      () async {
    await session.restore();
    disabled = true;
    store.failDelete = true;
    await expectLater(auth.funding.list(FundingList.mine),
        throwsA(isA<SessionStorageException>()));
    expect(session.phase, SessionPhase.unavailable);
    expect(session.user, isNull);
    store.failDelete = false;
    await session.restore();
    expect(session.phase, SessionPhase.signedOut);
    expect(store.value, isNull);
  });

  test('A delayed rejection from an old token does not remove a newer login',
      () async {
    await session.restore();
    final started = Completer<void>();
    final release = Completer<void>();
    handler = (request) async {
      if (request.uri.path.endsWith('/me/fundings')) {
        started.complete();
        await release.future;
        return reply(request, 403, null, code: 'account_disabled');
      }
      return reply(request, 200, {
        'user': user,
        'token': '2|new-session',
        'token_type': 'Bearer',
        'expires_at': '2030-01-01T00:00:00Z',
      });
    };
    final oldRequest = expectLater(
        auth.funding.list(FundingList.mine), throwsA(isA<ApiException>()));
    await started.future;
    await auth.login(email: 'belajar@example.test', password: 'Belajar123!');
    release.complete();
    await oldRequest;
    expect(store.value, '2|new-session');
    expect(session.phase, SessionPhase.signedIn);
  });
}
