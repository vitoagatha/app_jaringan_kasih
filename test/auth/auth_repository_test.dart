import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/core/network/api_client.dart';
import 'package:app_jaringan_kasih/features/auth/data/auth_repository.dart';
import 'package:app_jaringan_kasih/features/auth/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryTokenStore implements TokenStore {
  String? value;
  bool failRead = false;
  bool failWrite = false;
  bool failDelete = false;

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('read unavailable');
    return value;
  }

  @override
  Future<void> write(String token) async {
    if (failWrite) throw StateError('write unavailable');
    value = token;
  }

  @override
  Future<void> delete() async {
    if (failDelete) throw StateError('delete unavailable');
    value = null;
  }
}

void main() {
  const user = {
    'id': 1,
    'name': 'Akun Belajar',
    'email': 'belajar@example.test'
  };
  final grant = {
    'user': user,
    'token': '1|example-token-for-tests',
    'token_type': 'Bearer',
    'expires_at': '2026-11-01T00:00:00+00:00',
  };
  late HttpServer server;
  late AuthRepository auth;
  late MemoryTokenStore store;
  late List<(int, Object?)> replies;
  late List<Map<String, Object?>> requests;

  setUp(() async {
    store = MemoryTokenStore();
    replies = [];
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final raw =
          await const Utf8Decoder(allowMalformed: true).bind(request).join();
      requests.add({
        'path': request.uri.path,
        'method': request.method,
        'authorization': request.headers.value('authorization'),
        'content_type': request.headers.contentType.toString(),
        'body': raw.isEmpty
            ? null
            : request.headers.contentType?.mimeType == 'application/json'
                ? jsonDecode(raw)
                : raw,
      });
      final reply = replies.removeAt(0);
      request.response.statusCode = reply.$1;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'success': reply.$1 < 400,
        'message': 'Test response',
        if (reply.$1 < 400) 'data': reply.$2 else 'errors': reply.$2 ?? {},
      }));
      await request.response.close();
    });
    auth = AuthRepository(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
        store: store,
        deviceName: 'Test device');
  });

  tearDown(() async {
    auth.close();
    await server.close(force: true);
  });

  test('No stored token means signed out without an HTTP request', () async {
    expect(await auth.restore(), isNull);
    expect(requests, isEmpty);
  });

  test(
      'Profile update returns fresh verification and device-relative photo URL',
      () async {
    replies.add((
      200,
      {
        'user': {
          ...user,
          'name': 'Baru',
          'email_verified_at': '2026-10-25',
          'photo_url': '/storage/avatars/test.png'
        }
      }
    ));
    final result = await auth.updateProfile(
        ' Baru ', ' belajar@example.test ', '  password  ');
    expect(result.name, 'Baru');
    expect(result.emailVerified, isTrue);
    expect(auth.photoUri(result)!.host, '127.0.0.1');
    expect(auth.photoUri(result)!.port, server.port);
    expect(requests.single['method'], 'PATCH');
    expect(
        (requests.single['body'] as Map)['current_password'], '  password  ');
  });

  test('Password change clears persisted session after server success',
      () async {
    store.value = 'saved';
    replies.addAll([
      (200, {'user': user}),
      (200, null)
    ]);
    await auth.restore();
    await auth.changePassword('old', 'new-password', 'new-password');
    expect(store.value, isNull);
    expect(await auth.restore(), isNull);
  });

  test('Password recovery sends email, token and untrimmed new password',
      () async {
    replies.addAll([(200, null), (200, null)]);
    await auth.forgotPassword(' belajar@example.test ');
    await auth.resetPassword(
        ' belajar@example.test ', ' token ', '  password  ', '  password  ');
    expect(requests.first['path'], '/api/v1/auth/forgot-password');
    expect(requests.last['body'], {
      'email': 'belajar@example.test',
      'token': 'token',
      'password': '  password  ',
      'password_confirmation': '  password  '
    });
    expect(store.value, isNull);
  });

  test('Photo upload sends multipart boundary, field name, MIME and token',
      () async {
    store.value = 'saved';
    replies.addAll([
      (200, {'user': user}),
      (200, {'user': user}),
      (200, {'user': user})
    ]);
    await auth.restore();
    await auth.uploadPhoto(
        MultipartPhoto(Uint8List.fromList([255, 216, 255, 0]), 'image/jpeg'));
    expect(requests.last['path'], '/api/v1/auth/profile/photo');
    expect(requests.last['content_type'],
        contains('multipart/form-data; boundary='));
    expect(requests.last['body'],
        contains('name="photo"; filename="profile.jpg"'));
    expect(requests.last['body'], contains('Content-Type: image/jpeg'));
    expect(requests.last['authorization'], 'Bearer saved');
    await auth.deletePhoto();
    expect(requests.last['method'], 'DELETE');
  });

  test('Foreign or traversing photo URLs are rejected', () {
    for (final path in [
      'https://example.test/storage/avatars/a.png',
      '/storage/avatars/../secret',
      '//example.test/avatar'
    ]) {
      expect(
          auth.photoUri(AuthUser(
              id: 1, name: 'Nama', email: 'test@example.test', photoUrl: path)),
          isNull);
    }
  });

  test('Verification request uses authenticated API path', () async {
    replies.add((200, null));
    await auth.sendVerification();
    expect(requests.single['path'],
        '/api/v1/auth/email/verification-notification');
  });

  test(
      'Login stores token, preserves password and authenticates later requests',
      () async {
    replies.addAll([
      (200, grant),
      (200, {'user': user})
    ]);
    final result = await auth.login(
        email: ' belajar@example.test ', password: '  password  ');
    expect(result.id, 1);
    expect(store.value, grant['token']);
    expect(requests.first['body'], {
      'email': 'belajar@example.test',
      'password': '  password  ',
      'device_name': 'Test device',
    });
    expect((await auth.restore())!.email, 'belajar@example.test');
    expect(requests.last['authorization'], 'Bearer ${grant['token']}');
  });

  test('Registration sends confirmation and saves session', () async {
    replies.add((201, grant));
    await auth.register(
        name: ' Akun Belajar ',
        email: 'belajar@example.test',
        password: 'password',
        confirmation: 'password');
    expect(requests.single['path'], '/api/v1/auth/register');
    final body = requests.single['body'] as Map<String, dynamic>;
    expect(body['name'], 'Akun Belajar');
    expect(body['password_confirmation'], 'password');
    expect(store.value, grant['token']);
  });

  test('Expired or revoked token is removed on restore 401', () async {
    store.value = 'expired';
    replies.add((401, null));
    expect(await auth.restore(), isNull);
    expect(store.value, isNull);
  });

  test('Server failure preserves saved token for retry', () async {
    store.value = 'saved';
    replies.addAll([
      (503, null),
      (200, {'user': user})
    ]);
    await expectLater(auth.restore(), throwsA(isA<ApiException>()));
    expect(store.value, 'saved');
    expect((await auth.restore())!.id, 1);
  });

  test('Validation error retains field messages and does not save token',
      () async {
    replies.add((
      422,
      {
        'email': ['Email sudah digunakan.']
      }
    ));
    await expectLater(
        auth.register(
            name: 'Nama',
            email: 'test',
            password: 'password',
            confirmation: 'x'),
        throwsA(isA<ApiException>().having(
            (error) => error.errors['email'], 'email errors', isNotEmpty)));
    expect(store.value, isNull);
  });

  test('Successful logout deletes the stored token', () async {
    store.value = 'saved';
    replies.addAll([
      (200, {'user': user}),
      (200, null)
    ]);
    await auth.restore();
    await auth.logout();
    expect(requests.last['authorization'], 'Bearer saved');
    expect(store.value, isNull);
  });

  test('Already revoked token is still cleared when logout returns 401',
      () async {
    store.value = 'saved';
    replies.addAll([
      (200, {'user': user}),
      (401, null)
    ]);
    await auth.restore();
    await auth.logout();
    expect(store.value, isNull);
  });

  test('Failed logout preserves token and permits retry', () async {
    store.value = 'saved';
    replies.addAll([
      (200, {'user': user}),
      (500, null),
      (200, null)
    ]);
    await auth.restore();
    await expectLater(auth.logout(), throwsA(isA<ApiException>()));
    expect(store.value, 'saved');
    await auth.logout();
    expect(requests.last['authorization'], 'Bearer saved');
    expect(store.value, isNull);
  });

  test('Malformed session cannot authenticate or overwrite storage', () async {
    replies.add((200, {...grant, 'token_type': 'Unknown'}));
    await expectLater(auth.login(email: 'test', password: 'password'),
        throwsA(isA<ApiException>()));
    expect(store.value, isNull);
  });

  test('Storage read failure can be retried without sending a request',
      () async {
    store.failRead = true;
    await expectLater(auth.restore(), throwsA(isA<SessionStorageException>()));
    expect(requests, isEmpty);
    store.failRead = false;
    expect(await auth.restore(), isNull);
  });

  test('Storage write failure attempts to revoke newly issued token', () async {
    store.failWrite = true;
    replies.addAll([(200, grant), (200, null)]);
    await expectLater(auth.login(email: 'test', password: 'password'),
        throwsA(isA<SessionStorageException>()));
    expect(requests.last['path'], '/api/v1/auth/logout');
    expect(requests.last['authorization'], 'Bearer ${grant['token']}');
    expect(store.value, isNull);
  });

  test('Storage delete failure is reported instead of claiming logout complete',
      () async {
    store.value = 'saved';
    store.failDelete = true;
    replies.addAll([
      (200, {'user': user}),
      (200, null)
    ]);
    await auth.restore();
    await expectLater(auth.logout(), throwsA(isA<SessionStorageException>()));
    expect(store.value, 'saved');
  });
}
