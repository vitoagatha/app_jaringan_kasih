import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_jaringan_kasih/core/config/api_config.dart';
import 'package:app_jaringan_kasih/core/network/api_client.dart';
import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/health/data/health_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late ApiClient client;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = ApiClient(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'));
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  void respond(HttpRequest request, Map<String, Object?> payload,
      {int status = 200}) {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(payload));
    request.response.close();
  }

  test('HealthRepository membaca kontrak API melalui HTTP', () async {
    server.listen((request) {
      expect(request.uri.path, '/api/v1/health');
      expect(
          request.headers.value(HttpHeaders.acceptHeader), 'application/json');
      respond(request, {
        'success': true,
        'message': 'Siap',
        'data': {
          'service': 'jaringan-kasih-api',
          'database': 'connected',
          'timestamp': '2026-10-25T00:00:00+00:00',
        },
      });
    });

    final result = await HealthRepository(client).check();
    expect(result.service, 'jaringan-kasih-api');
    expect(result.timestamp, DateTime.utc(2026, 10, 25));
  });

  test('Mempertahankan status 401 untuk penanganan sesi pada P1', () async {
    server.listen((request) => respond(
        request,
        {
          'success': false,
          'message': 'Silakan masuk kembali.',
          'errors': <String, Object?>{},
        },
        status: 401));

    await expectLater(
        client.get('me'),
        throwsA(isA<ApiException>()
            .having(
                (error) => error.isUnauthenticated, 'isUnauthenticated', true)
            .having((error) => error.message, 'message',
                'Silakan masuk kembali.')));
  });

  test('Mempertahankan pesan validasi per field dari HTTP 422', () async {
    server.listen((request) => respond(
        request,
        {
          'success': false,
          'message': 'Data belum valid.',
          'errors': {
            'email': ['Email tidak valid.']
          },
        },
        status: 422));

    await expectLater(
        client.get('validation'),
        throwsA(isA<ApiException>()
            .having((error) => error.statusCode, 'status', 422)
            .having((error) => error.errors['email'], 'errors.email',
                ['Email tidak valid.'])));
  });

  test('Menolak respons HTML yang tidak sesuai kontrak JSON', () async {
    server.listen((request) {
      request.response.write('<html>server error</html>');
      request.response.close();
    });
    await expectLater(
        client.get('health'),
        throwsA(isA<ApiException>().having((error) => error.message, 'message',
            'Respons server tidak sesuai format API.')));
  });

  test('Membatasi waktu tunggu bila server tidak memberikan respons', () async {
    client.close();
    client = ApiClient(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
        timeout: const Duration(milliseconds: 200));
    server.listen((request) {});
    await expectLater(
        client.get('health'),
        throwsA(isA<ApiException>().having((error) => error.message, 'message',
            'Koneksi terlalu lama. Silakan coba lagi.')));
  });

  test('Tidak mengirim request bertoken ke alamat di luar API', () async {
    await expectLater(
        client.get('https://example.invalid/health'), throwsArgumentError);
    await expectLater(client.get('../outside'), throwsArgumentError);
  });

  test('Token yang terlambat tidak membuka POST setelah timeout', () async {
    final token = Completer<String?>();
    final transport = _ProbeHttpClient(() async {
      throw StateError('Transport tidak boleh dibuka setelah timeout.');
    });
    client.close();
    client = ApiClient(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
      timeout: const Duration(milliseconds: 50),
      tokenProvider: () => token.future,
      httpClient: transport,
    );

    await expectLater(
      client.request('POST', 'register', body: {'name': 'Contoh'}),
      throwsA(isA<ApiException>().having((error) => error.message, 'message',
          'Koneksi terlalu lama. Silakan coba lagi.')),
    );
    token.complete('late-token');
    await Future<void>.delayed(Duration.zero);
    expect(transport.attempts, 0);
  });

  test('Koneksi yang selesai setelah timeout dibatalkan sebelum dikirim',
      () async {
    final connection = Completer<HttpClientRequest>();
    final transport = _ProbeHttpClient(() => connection.future);
    final request = _ProbeHttpRequest();
    client.close();
    client = ApiClient(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
      timeout: const Duration(milliseconds: 50),
      httpClient: transport,
    );

    await expectLater(
      client.request('POST', 'register', body: {'name': 'Contoh'}),
      throwsA(isA<ApiException>().having((error) => error.message, 'message',
          'Koneksi terlalu lama. Silakan coba lagi.')),
    );
    expect(transport.attempts, 1);
    connection.complete(request);
    await Future<void>.delayed(Duration.zero);
    expect(request.aborted, true);
    expect(request.sent, false);
  });

  test('Menutup client saat menunggu token mencegah request terkirim',
      () async {
    final token = Completer<String?>();
    final transport = _ProbeHttpClient(() async {
      throw StateError('Transport tidak boleh dibuka setelah client ditutup.');
    });
    client.close();
    client = ApiClient(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
      tokenProvider: () => token.future,
      httpClient: transport,
    );
    final operation =
        client.request('POST', 'register', body: {'name': 'Contoh'});
    final expectation = expectLater(
        operation,
        throwsA(isA<ApiException>().having((error) => error.message, 'message',
            'Koneksi API sudah ditutup.')));

    client.close();
    token.complete('late-token');
    await expectation;
    expect(transport.attempts, 0);
    await expectLater(client.get('health'), throwsA(isA<ApiException>()));
  });

  test('POST mengirim JSON dan bearer token ke endpoint yang benar', () async {
    client.close();
    client = ApiClient(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
      tokenProvider: () async => 'test-token',
    );
    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/profile');
      expect(request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer test-token');
      expect(request.headers.contentType?.mimeType, 'application/json');
      expect(jsonDecode(await utf8.decoder.bind(request).join()),
          {'name': 'Contoh'});
      respond(
          request,
          {
            'success': true,
            'message': 'Tersimpan',
            'data': {'id': 1}
          },
          status: 201);
    });

    expect(await client.request('POST', 'profile', body: {'name': 'Contoh'}),
        {'id': 1});
  });

  test('Menormalisasi base URL dan menolak kredensial atau query', () {
    expect(ApiConfig.parseBaseUri('http://127.0.0.1:8000/api/v1').path,
        '/api/v1/');
    expect(() => ApiConfig.parseBaseUri('http://user:password@localhost/api'),
        throwsArgumentError);
    expect(() => ApiConfig.parseBaseUri('http://localhost/api?token=secret'),
        throwsArgumentError);
  });
}

/// Test double yang berhenti pada batas transport, tanpa mengakses layanan nyata.
class _ProbeHttpClient implements HttpClient {
  final Future<HttpClientRequest> Function() onOpen;
  int attempts = 0;

  _ProbeHttpClient(this.onOpen);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    attempts++;
    return onOpen();
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
      'Unexpected transport operation: ${invocation.memberName}');
}

class _ProbeHttpRequest implements HttpClientRequest {
  bool aborted = false;
  bool sent = false;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    aborted = true;
  }

  @override
  Future<HttpClientResponse> close() async {
    sent = true;
    throw StateError('Request yang terlambat tidak boleh dikirim.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
      'Unexpected request operation: ${invocation.memberName}');
}
