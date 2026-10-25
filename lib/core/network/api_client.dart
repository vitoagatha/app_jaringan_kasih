import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
      {Map<String, Object?>? body}) async {
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
