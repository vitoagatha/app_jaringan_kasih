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
      {Map<String, Object?>? body,
      MultipartPhoto? photo,
      Map<String, String>? multipartFields}) async {
    if (body != null && photo != null) {
      throw ArgumentError('Gunakan JSON atau multipart, bukan keduanya.');
    }
    if (multipartFields != null && photo == null) {
      throw ArgumentError('Field multipart memerlukan file foto.');
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
          final bytes =
              photo.encode(boundary, fields: multipartFields ?? const {});
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
        final retryAfter =
            _retryAfter(response.headers.value(HttpHeaders.retryAfterHeader));
        dynamic decoded;
        try {
          decoded = jsonDecode(text.toString());
        } on FormatException {
          if (response.statusCode >= 400) {
            throw _httpError(response.statusCode, retryAfter);
          }
          rethrow;
        }
        if (decoded is! Map<String, dynamic> ||
            decoded['success'] is! bool ||
            decoded['message'] is! String) {
          if (response.statusCode >= 400) {
            throw _httpError(response.statusCode, retryAfter);
          }
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
              statusCode: response.statusCode,
              errors: errors,
              retryAfter: retryAfter);
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
    } on HandshakeException {
      throw const ApiException(
          'Koneksi aman ke server gagal. Periksa alamat API dan sertifikat server.');
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

  Duration? _retryAfter(String? value) {
    if (value == null) return null;
    final seconds = int.tryParse(value);
    if (seconds != null) {
      return seconds >= 0 ? Duration(seconds: seconds) : null;
    }
    try {
      final delay = HttpDate.parse(value).difference(DateTime.now().toUtc());
      return delay.isNegative ? Duration.zero : delay;
    } on HttpException {
      return null;
    } on FormatException {
      return null;
    }
  }

  ApiException _httpError(int status, Duration? retryAfter) => ApiException(
      switch (status) {
        401 => 'Silakan masuk kembali.',
        403 => 'Anda tidak memiliki izin untuk tindakan ini.',
        404 => 'Endpoint atau data tidak ditemukan.',
        413 => 'Ukuran unggahan melebihi batas server.',
        429 => 'Terlalu banyak permintaan. Silakan coba lagi nanti.',
        >= 500 => 'Server sementara tidak tersedia. Silakan coba lagi.',
        _ => 'Permintaan gagal. Silakan periksa data dan coba lagi.',
      },
      statusCode: status,
      retryAfter: retryAfter);
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

  Uint8List encode(String boundary, {Map<String, String> fields = const {}}) {
    final extension = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp'
    }[mimeType]!;
    final buffer = BytesBuilder(copy: false);
    for (final entry in fields.entries) {
      if (!RegExp(r'^[A-Za-z0-9_]{1,64}$').hasMatch(entry.key) ||
          entry.key == 'photo') {
        throw ArgumentError('Nama field multipart tidak valid.');
      }
      buffer.add(utf8.encode(
          '--$boundary\r\nContent-Disposition: form-data; name="${entry.key}"\r\n\r\n${entry.value}\r\n'));
    }
    return (buffer
          ..add(utf8.encode(
              '--$boundary\r\nContent-Disposition: form-data; name="photo"; filename="profile.$extension"\r\nContent-Type: $mimeType\r\n\r\n'))
          ..add(bytes)
          ..add(utf8.encode('\r\n--$boundary--\r\n')))
        .takeBytes();
  }
}
