import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_jaringan_kasih/core/network/api_client.dart';
import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/funding/data/funding_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final item = {
    'id': 1,
    'title': 'Pendanaan contoh',
    'description': 'Deskripsi lengkap pendanaan untuk pengujian.',
    'target_amount': 1000000,
    'owner': {'id': 1, 'name': 'Pemilik'},
    'category': {'id': 1, 'name': 'Pendidikan'},
    'status': 'published',
    'is_wishlisted': false
  };
  late HttpServer server;
  late ApiClient client;
  late FundingRepository repository;
  late List<Map<String, Object?>> requests;
  Object? response;
  int status = 200;

  setUp(() async {
    requests = [];
    response = null;
    status = 200;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body =
          await const Utf8Decoder(allowMalformed: true).bind(request).join();
      requests.add({
        'path': request.uri.path,
        'query': request.uri.queryParameters,
        'method': request.method,
        'token': request.headers.value('authorization'),
        'content_type': request.headers.contentType.toString(),
        'body': body.isEmpty
            ? null
            : request.headers.contentType?.mimeType == 'application/json'
                ? jsonDecode(body)
                : body,
      });
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'success': status < 400,
        'message': 'Test',
        if (status < 400)
          'data': response
        else
          'errors': {
            'title': ['Judul belum valid.']
          }
      }));
      await request.response.close();
    });
    client = ApiClient(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
        tokenProvider: () async => 'test-token');
    repository = FundingRepository(client);
  });
  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  test('Categories are decoded from API', () async {
    response = {
      'items': [
        {'id': 9, 'name': 'Kategori dari API'}
      ]
    };
    expect((await repository.categories()).single.name, 'Kategori dari API');
    expect(requests.single['path'], '/api/v1/categories');
  });

  test(
      'Cover creation and edit send fields and binary file in one multipart request',
      () async {
    response = {
      'funding': {...item, 'photo_url': '/storage/fundings/test.jpg'}
    };
    final draft = FundingDraft(
        title: 'Judul',
        description: 'Deskripsi lengkap pendanaan.',
        categoryId: 1,
        targetAmount: 100000,
        status: 'published',
        photo: MultipartPhoto(
            Uint8List.fromList([255, 216, 255, 0]), 'image/jpeg'));
    final saved = await repository.save(draft);
    expect(repository.photoUri(saved)!.origin, client.baseUri.origin);
    expect(requests.length, 1);
    expect(requests.last['method'], 'POST');
    expect(requests.last['content_type'],
        contains('multipart/form-data; boundary='));
    expect(requests.last['body'], contains('name="title"\r\n\r\nJudul'));
    expect(requests.last['body'],
        contains('name="photo"; filename="profile.jpg"'));
    expect(requests.last['token'], 'Bearer test-token');
    await repository.save(draft, id: 1);
    expect(requests.length, 2);
    expect(requests.last['path'], '/api/v1/fundings/1');
    expect(requests.last['body'], contains('name="_method"\r\n\r\nPATCH'));
  });

  test('Remove cover uses JSON and old records without photo still parse',
      () async {
    response = {'funding': item};
    final record = await repository.save(
        const FundingDraft(
            title: 'Judul',
            description: 'Deskripsi lengkap pendanaan.',
            categoryId: 1,
            targetAmount: 100000,
            status: 'draft',
            removePhoto: true),
        id: 1);
    expect((requests.single['body'] as Map)['remove_photo'], isTrue);
    expect(repository.photoUri(record), isNull);
    expect(requests.single['method'], 'PATCH');
  });

  test(
      'Cover URLs use emulator API host and reject foreign or unsafe locations',
      () {
    final emulatorClient =
        ApiClient(baseUri: Uri.parse('http://10.0.2.2:8000/api/v1/'));
    addTearDown(emulatorClient.close);
    final emulatorRepository = FundingRepository(emulatorClient);
    FundingRecord photo(String? url) =>
        FundingRecord.parse({...item, 'photo_url': url});
    expect(
        emulatorRepository
            .photoUri(photo('/storage/fundings/test.png'))
            .toString(),
        'http://10.0.2.2:8000/storage/fundings/test.png');
    for (final path in [
      'https://other.test/storage/fundings/a.png',
      '/storage/avatars/a.png',
      '/storage/fundings/../secret',
      '/storage/fundings/a.png?token=secret'
    ]) {
      expect(emulatorRepository.photoUri(photo(path)), isNull);
    }
  });

  test('Pagination and filters use encoded query strings for each list',
      () async {
    response = {
      'items': [item],
      'pagination': {'page': 2, 'last_page': 3, 'total': 21}
    };
    final result = await repository.list(FundingList.mine,
        page: 2, search: '  Anak & sekolah  ', categoryId: 1, status: 'draft');
    expect(result.items.single.targetAmount, 1000000);
    expect(result.lastPage, 3);
    expect(requests.single['path'], '/api/v1/me/fundings');
    expect(requests.single['query'], {
      'page': '2',
      'per_page': '10',
      'search': 'Anak & sekolah',
      'category_id': '1',
      'status': 'draft'
    });
    await repository.list(FundingList.wishlist);
    expect(requests.last['path'], '/api/v1/me/wishlist');
  });

  test('Create and edit send safe fields with a bearer token', () async {
    response = {'funding': item};
    const draft = FundingDraft(
        title: ' Judul ',
        description: ' Deskripsi panjang pendanaan. ',
        categoryId: 1,
        targetAmount: 5000,
        status: 'draft');
    await repository.save(draft);
    expect(requests.last['method'], 'POST');
    expect(requests.last['token'], 'Bearer test-token');
    expect(requests.last['body'], {
      'title': 'Judul',
      'description': 'Deskripsi panjang pendanaan.',
      'category_id': 1,
      'target_amount': 5000,
      'status': 'draft'
    });
    await repository.save(draft, id: 1);
    expect(requests.last['path'], '/api/v1/fundings/1');
    expect(requests.last['method'], 'PATCH');
  });

  test(
      'Draft detail uses owner endpoint and public detail uses public endpoint',
      () async {
    response = {'funding': item};
    await repository.detail(1, mine: true);
    expect(requests.last['path'], '/api/v1/me/fundings/1');
    await repository.detail(1);
    expect(requests.last['path'], '/api/v1/fundings/1');
  });

  test('Wishlist uses idempotent PUT and DELETE', () async {
    await repository.setWishlist(1, true);
    expect(requests.last['method'], 'PUT');
    await repository.setWishlist(1, false);
    expect(requests.last['method'], 'DELETE');
    expect(requests.last['path'], '/api/v1/fundings/1/wishlist');
  });

  test('Malformed metadata and records are rejected', () async {
    response = {
      'items': [item],
      'pagination': {'page': 0, 'last_page': 1, 'total': 0}
    };
    await expectLater(
        repository.list(FundingList.explore), throwsA(isA<ApiException>()));
    response = {
      'funding': {...item, 'status': 'approved'}
    };
    await expectLater(repository.detail(1), throwsA(isA<ApiException>()));
  });

  test('Server validation preserves field errors', () async {
    status = 422;
    await expectLater(
        repository.save(const FundingDraft(
            title: '',
            description: '',
            categoryId: 1,
            targetAmount: 0,
            status: 'draft')),
        throwsA(isA<ApiException>().having((error) => error.errors['title'],
            'title errors', ['Judul belum valid.'])));
  });
}
