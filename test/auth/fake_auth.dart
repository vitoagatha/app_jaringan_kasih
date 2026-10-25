import 'package:app_jaringan_kasih/features/auth/data/auth_repository.dart';

class FakeAuth implements AuthGateway {
  static const account =
      AuthUser(id: 1, name: 'Akun Belajar', email: 'belajar@example.test');
  Future<AuthUser?> Function() onRestore = () async => null;
  Future<AuthUser> Function() onAuthenticate = () async => account;
  Future<void> Function() onLogout = () async {};
  int loginCalls = 0;
  int registerCalls = 0;
  int logoutCalls = 0;
  int closeCalls = 0;
  String? submittedPassword;
  String? submittedConfirmation;

  @override
  Future<AuthUser?> restore() => onRestore();

  @override
  Future<AuthUser> login({required String email, required String password}) {
    loginCalls++;
    submittedPassword = password;
    return onAuthenticate();
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) {
    registerCalls++;
    submittedPassword = password;
    submittedConfirmation = confirmation;
    return onAuthenticate();
  }

  @override
  Future<void> logout() {
    logoutCalls++;
    return onLogout();
  }

  @override
  void close() => closeCalls++;
}
