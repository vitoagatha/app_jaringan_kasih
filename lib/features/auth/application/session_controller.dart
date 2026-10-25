import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';

enum SessionPhase { restoring, signedOut, signedIn, unavailable }

class SessionController extends ChangeNotifier {
  final AuthGateway _auth;
  SessionPhase phase = SessionPhase.restoring;
  AuthUser? user;
  ApiException? error;
  bool busy = false;
  bool _disposed = false;

  SessionController(this._auth);

  Future<void> restore() async {
    if (busy || _disposed) return;
    busy = true;
    phase = SessionPhase.restoring;
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
