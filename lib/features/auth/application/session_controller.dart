import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../../funding/data/funding_repository.dart';

enum SessionPhase { restoring, signedOut, signedIn, unavailable }

class SessionController extends ChangeNotifier {
  final AuthGateway _auth;
  SessionPhase phase = SessionPhase.restoring;
  AuthUser? user;
  ApiException? error;
  bool busy = false;
  bool _disposed = false;
  bool externalInteraction = false;
  final FundingGateway? funding;

  SessionController(this._auth, {FundingGateway? fundingGateway})
      : funding =
            fundingGateway ?? (_auth is AuthRepository ? _auth.funding : null);

  AccountGateway get _account => _auth as AccountGateway;
  Uri? get photoUri => user == null ? null : _account.photoUri(user!);

  Future<bool> updateProfile(
          String name, String email, String currentPassword) =>
      _accountAction(() async {
        user = await _account.updateProfile(name, email, currentPassword);
      });

  Future<bool> sendVerification() => _accountAction(_account.sendVerification);
  Future<bool> uploadPhoto(MultipartPhoto photo) => _accountAction(() async {
        user = await _account.uploadPhoto(photo);
      });
  Future<bool> deletePhoto() => _accountAction(() async {
        user = await _account.deletePhoto();
      });
  Future<bool> changePassword(
          String currentPassword, String password, String confirmation) =>
      _accountAction(() async {
        await _account.changePassword(currentPassword, password, confirmation);
        user = null;
        phase = SessionPhase.signedOut;
      });
  Future<bool> forgotPassword(String email) =>
      _accountAction(() => _account.forgotPassword(email), public: true);
  Future<bool> resetPassword(
          String email, String token, String password, String confirmation) =>
      _accountAction(
          () => _account.resetPassword(email, token, password, confirmation),
          public: true);

  Future<bool> _accountAction(Future<void> Function() action,
      {bool public = false}) async {
    if (busy ||
        _disposed ||
        phase != (public ? SessionPhase.signedOut : SessionPhase.signedIn)) {
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (failure) {
      error = _message(failure);
      if (failure is SessionStorageException) {
        phase = SessionPhase.unavailable;
      } else if (!public &&
          failure is ApiException &&
          failure.isUnauthenticated) {
        // restore memeriksa ulang dan membersihkan token yang sudah dicabut.
        phase = SessionPhase.restoring;
        try {
          user = await _auth.restore();
          phase = user == null ? SessionPhase.signedOut : SessionPhase.signedIn;
        } catch (restoreFailure) {
          error = _message(restoreFailure);
          phase = SessionPhase.unavailable;
        }
      }
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> restore({bool keepView = false}) async {
    if (busy || _disposed) return;
    busy = true;
    if (!keepView || phase != SessionPhase.signedIn || user == null) {
      phase = SessionPhase.restoring;
    }
    error = null;
    notifyListeners();
    try {
      user = await _auth.restore();
      phase = user == null ? SessionPhase.signedOut : SessionPhase.signedIn;
    } catch (failure) {
      error = _message(failure);
      phase = SessionPhase.unavailable;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> login(String email, String password) =>
      _authenticate(() => _auth.login(email: email, password: password));

  Future<void> register(
          String name, String email, String password, String confirmation) =>
      _authenticate(() => _auth.register(
          name: name,
          email: email,
          password: password,
          confirmation: confirmation));

  Future<void> _authenticate(Future<AuthUser> Function() action) async {
    if (busy || _disposed || phase != SessionPhase.signedOut) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await action();
      phase = SessionPhase.signedIn;
    } catch (failure) {
      error = _message(failure);
      if (failure is SessionStorageException) phase = SessionPhase.unavailable;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> logout() async {
    if (busy || _disposed || phase != SessionPhase.signedIn) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _auth.logout();
      user = null;
      phase = SessionPhase.signedOut;
    } catch (failure) {
      error = _message(failure);
      if (failure is SessionStorageException) phase = SessionPhase.unavailable;
    } finally {
      busy = false;
      _notify();
    }
  }

  ApiException _message(Object failure) => failure is ApiException
      ? failure
      : const ApiException('Terjadi kesalahan. Silakan coba lagi.');

  void clearError() {
    if (busy || _disposed) return;
    error = null;
    notifyListeners();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.close();
    super.dispose();
  }
}
