import 'dart:io';

class ApiConfig {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static Uri get baseUri => parseBaseUri(
        _configuredUrl.isNotEmpty
            ? _configuredUrl
            : 'http://${Platform.isAndroid ? '10.0.2.2' : '127.0.0.1'}:8000/api/v1/',
      );

  static Uri parseBaseUri(String value) {
    final uri = Uri.parse(value);
    if (!['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
          'API_BASE_URL harus berupa alamat HTTP(S) tanpa query atau kredensial.');
    }
    return uri.replace(
        path: uri.path.endsWith('/') ? uri.path : '${uri.path}/');
  }
}
