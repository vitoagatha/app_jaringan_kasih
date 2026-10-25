import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  final Uri baseUri;
  final Duration timeout;
  final Future<String?> Function()? tokenProvider;
  final HttpClient _httpClient;
  bool _closed = false;

  ApiClient({
    required Uri baseUri,
    this.timeout = const Duration(seconds: 15),
    this.tokenProvider,
    HttpClient? httpClient,
  })  : baseUri = ApiConfig.parseBaseUri(baseUri.toString()),
        _httpClient = httpClient ?? HttpClient();

  Future<Object?> get(String path) => request('GET', path);

  Future<Object?> request(String method, String path,
      {Map<String, Object?>? body, MultipartPhoto? photo}) async {
    if (body != null && photo != null) {
      throw ArgumentError('Gunakan JSON atau multipart, bukan keduanya.');
    }
    const timeoutError =
        ApiException('Koneksi terlalu lama. Silakan coba lagi.');
    const closedError = ApiException('Koneksi API sudah ditutup.');
    if (_closed) throw closedError;

    final endpoint = baseUri.resolve(path.replaceFirst(RegExp(r'^/+'), ''));
    if (endpoint.origin != baseUri.origin ||
        !endpoint.path.startsWith(baseUri.path)) {
      throw ArgumentError('Endpoint harus berada di dalam API_BASE_URL.');
    }
    HttpClientRequest? activeRequest;
    StreamIterator<String>? responseBody;
    var timedOut = false;
    final elapsed = Stopwatch()..start();

    void cancel(ApiException error) {
      activeRequest?.abort(error);
      final stream = responseBody;
      if (stream != null) unawaited(stream.cancel());
    }

    void ensureActive() {
      if (_closed) {
        cancel(closedError);
        throw closedError;
      }
      if (timedOut || elapsed.elapsed >= timeout) {
        timedOut = true;
        cancel(timeoutError);
        throw timeoutError;
      }
    }

    try {
      return await (() async {
        final token = await tokenProvider?.call();
        ensureActive();
        final request = await _httpClient.openUrl(method, endpoint);
        activeRequest = request;
        // openUrl juga bisa selesai setelah pemanggil menerima timeout.
        ensureActive();
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (token != null && token.isNotEmpty) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        }
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        if (photo != null) {
          final boundary =
              'jk${List.generate(24, (_) => Random.secure().nextInt(16).toRadixString(16)).join()}';
          final bytes = photo.encode(boundary);
          request.headers.contentType =
              ContentType.parse('multipart/form-data; boundary=$boundary');
          request.contentLength = bytes.length;
          request.add(bytes);
        }
        final response = await request.close();
        ensureActive();
        final stream = StreamIterator(utf8.decoder.bind(response));
        responseBody = stream;
        final text = StringBuffer();
        while (await stream.moveNext()) {
          ensureActive();
          text.write(stream.current);
        }
        ensureActive();
        final decoded = jsonDecode(text.toString());
        if (decoded is! Map<String, dynamic> ||
            decoded['success'] is! bool ||
            decoded['message'] is! String) {
          throw const FormatException('Invalid API envelope');
        }
        if (response.statusCode < 200 ||
            response.statusCode >= 300 ||
            decoded['success'] != true) {
          final rawErrors = decoded['errors'];
          final errors = <String, List<String>>{};
          if (rawErrors is Map<String, dynamic>) {
            for (final entry in rawErrors.entries) {
              if (entry.value is List) {
                errors[entry.key] = (entry.value as List)
                    .map((value) => value.toString())
                    .toList();
              }
            }
          }
          throw ApiException(decoded['message'] as String,
              statusCode: response.statusCode, errors: errors);
        }
        if (!decoded.containsKey('data')) {
          throw const FormatException('Missing API data');
        }
        return decoded['data'];
      })()
          .timeout(timeout, onTimeout: () {
        timedOut = true;
        cancel(timeoutError);
        throw timeoutError;
      });
    } on SocketException {
      throw const ApiException(
          'Tidak dapat terhubung ke server lokal. Periksa server dan jaringan.');
    } on HttpException {
      throw const ApiException(
          'Koneksi ke server terputus. Silakan coba lagi.');
    } on FormatException {
      throw const ApiException('Respons server tidak sesuai format API.');
    } finally {
      elapsed.stop();
    }
  }

  void close() {
    _closed = true;
    _httpClient.close(force: true);
  }
}

class MultipartPhoto {
  static const maxBytes = 2 * 1024 * 1024;
  final Uint8List bytes;
  final String mimeType;

  MultipartPhoto(this.bytes, this.mimeType) {
    if (!['image/jpeg', 'image/png', 'image/webp'].contains(mimeType) ||
        bytes.isEmpty ||
        bytes.length > maxBytes) {
      throw const ApiException('Gunakan JPEG, PNG, atau WebP maksimal 2 MB.');
    }
  }

  Uint8List encode(String boundary) {
    final extension = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp'
    }[mimeType]!;
    return (BytesBuilder(copy: false)
          ..add(utf8.encode(
              '--$boundary\r\nContent-Disposition: form-data; name="photo"; filename="profile.$extension"\r\nContent-Type: $mimeType\r\n\r\n'))
          ..add(bytes)
          ..add(utf8.encode('\r\n--$boundary--\r\n')))
        .takeBytes();
  }
}
