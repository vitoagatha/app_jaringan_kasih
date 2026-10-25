import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'token_store.dart';

class AuthUser {
  final int id;
  final String name;
  final String email;
  final bool emailVerified;
  final String? photoUrl;

  const AuthUser(
      {required this.id,
      required this.name,
      required this.email,
      this.emailVerified = false,
      this.photoUrl});

  static AuthUser parse(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! int ||
        (value['id'] as int) <= 0 ||
        value['name'] is! String ||
        (value['name'] as String).trim().isEmpty ||
        value['email'] is! String ||
        (value['email'] as String).trim().isEmpty) {
      throw const ApiException('Data akun dari server tidak valid.');
    }
    return AuthUser(
        id: value['id'] as int,
        name: value['name'] as String,
        email: value['email'] as String,
        emailVerified: value['email_verified_at'] != null,
        photoUrl:
            value['photo_url'] is String ? value['photo_url'] as String : null);
  }
}

abstract interface class AuthGateway {
  Future<AuthUser?> restore();
  Future<AuthUser> login({required String email, required String password});
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  });
  Future<void> logout();
  void close();
}

abstract interface class AccountGateway {
  Future<AuthUser> updateProfile(
      String name, String email, String currentPassword);
  Future<void> sendVerification();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(
      String email, String token, String password, String confirmation);
  Future<void> changePassword(
      String currentPassword, String password, String confirmation);
  Future<AuthUser> uploadPhoto(MultipartPhoto photo);
  Future<AuthUser> deletePhoto();
  Uri? photoUri(AuthUser user);
}

class SessionStorageException extends ApiException {
  const SessionStorageException()
      : super('Penyimpanan sesi perangkat gagal. Silakan coba lagi.');
}

class AuthRepository implements AuthGateway, AccountGateway {
  final ApiClient _client;
  final TokenStore _store;
  final String deviceName;
  String? _token;

  AuthRepository._(this._client, this._store, this.deviceName);

  factory AuthRepository({
    required Uri baseUri,
    required TokenStore store,
    required String deviceName,
  }) {
    late AuthRepository repository;
    final client = ApiClient(
        baseUri: baseUri, tokenProvider: () async => repository._token);
    repository = AuthRepository._(client, store, deviceName);
    return repository;
  }

  @override
  Future<AuthUser?> restore() async {
    try {
      _token = await _store.read();
    } catch (_) {
      throw const SessionStorageException();
    }
    if (_token == null || _token!.isEmpty) return null;
    try {
      final data = await _client.get('auth/me');
      return _userFrom(data);
    } on ApiException catch (error) {
      if (!error.isUnauthenticated) rethrow;
      await _clearToken();
      return null;
    }
  }

  @override
  Future<AuthUser> login({required String email, required String password}) =>
      _authenticate(
          'auth/login', {'email': email.trim(), 'password': password});

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) =>
      _authenticate('auth/register', {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': confirmation,
      });

  AuthUser _userFrom(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Data akun dari server tidak valid.');
    }
    return AuthUser.parse(data['user']);
  }

  Future<AuthUser> _authenticate(
      String path, Map<String, Object?> credentials) async {
    final data = await _client.request('POST', path,
        body: {...credentials, 'device_name': deviceName});
    final user = _userFrom(data);
    final grant = data as Map<String, dynamic>;
    final token = grant['token'];
    final expiresAt = grant['expires_at'];
    if (token is! String ||
        token.trim().isEmpty ||
        grant['token_type'] != 'Bearer' ||
        expiresAt is! String ||
        DateTime.tryParse(expiresAt) == null) {
      throw const ApiException('Respons sesi dari server tidak valid.');
    }
    _token = token;
    try {
      await _store.write(token);
    } catch (_) {
      // Jika penyimpanan gagal, upayakan mencabut token yang baru diterbitkan.
      try {
        await _client.request('POST', 'auth/logout');
      } catch (_) {
        // Saat server tak terjangkau token tetap berakhir sesuai expiry backend.
      }
      try {
        await _store.delete();
      } catch (_) {
        // Gate sesi dikunci sampai penyimpanan dapat diakses kembali.
      }
      _token = null;
      throw const SessionStorageException();
    }
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await _client.request('POST', 'auth/logout');
    } on ApiException catch (error) {
      if (!error.isUnauthenticated) rethrow;
    }
    // Kegagalan jaringan mempertahankan token agar logout dapat dicoba lagi.
    await _clearToken();
  }

  Future<void> _clearToken() async {
    _token = null;
    try {
      await _store.delete();
    } catch (_) {
      throw const SessionStorageException();
    }
  }

  @override
  Future<AuthUser> updateProfile(
          String name, String email, String currentPassword) async =>
      _userFrom(await _client.request('PATCH', 'auth/profile', body: {
        'name': name.trim(),
        'email': email.trim(),
        'current_password': currentPassword,
      }));

  @override
  Future<void> sendVerification() async {
    await _client.request('POST', 'auth/email/verification-notification');
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _client
        .request('POST', 'auth/forgot-password', body: {'email': email.trim()});
  }

  @override
  Future<void> resetPassword(
      String email, String token, String password, String confirmation) async {
    await _client.request('POST', 'auth/reset-password', body: {
      'email': email.trim(),
      'token': token.trim(),
      'password': password,
      'password_confirmation': confirmation,
    });
  }

  @override
  Future<void> changePassword(
      String currentPassword, String password, String confirmation) async {
    await _client.request('POST', 'auth/change-password', body: {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': confirmation,
    });
    await _clearToken();
  }

  @override
  Future<AuthUser> uploadPhoto(MultipartPhoto photo) async => _userFrom(
      await _client.request('POST', 'auth/profile/photo', photo: photo));

  @override
  Future<AuthUser> deletePhoto() async =>
      _userFrom(await _client.request('DELETE', 'auth/profile/photo'));

  @override
  Uri? photoUri(AuthUser user) {
    final path = user.photoUrl;
    if (path == null) return null;
    final uri = _client.baseUri.resolve(path);
    // Foto publik harus berasal dari storage backend sendiri.
    if (uri.origin != _client.baseUri.origin ||
        !uri.path.startsWith('/storage/avatars/')) {
      return null;
    }
    return uri;
  }

  @override
  void close() => _client.close();
}
