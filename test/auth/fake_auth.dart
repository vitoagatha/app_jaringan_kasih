import 'package:app_jaringan_kasih/features/auth/data/auth_repository.dart';
import 'package:app_jaringan_kasih/core/network/api_client.dart';

class FakeAuth implements AuthGateway, AccountGateway {
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
  int forgotCalls = 0;
  int resetCalls = 0;
  int verificationCalls = 0;
  int uploadCalls = 0;
  AuthUser currentUser = account;
  Future<void> Function()? onAccountAction;

  @override
  Future<AuthUser> updateProfile(
      String name, String email, String currentPassword) async {
    await onAccountAction?.call();
    return currentUser = AuthUser(id: 1, name: name, email: email);
  }

  @override
  Future<void> sendVerification() async {
    verificationCalls++;
    await onAccountAction?.call();
  }

  @override
  Future<void> forgotPassword(String email) async {
    forgotCalls++;
    await onAccountAction?.call();
  }

  @override
  Future<void> resetPassword(
      String email, String token, String password, String confirmation) async {
    resetCalls++;
    await onAccountAction?.call();
  }

  @override
  Future<void> changePassword(
      String currentPassword, String password, String confirmation) async {
    await onAccountAction?.call();
  }

  @override
  Future<AuthUser> uploadPhoto(MultipartPhoto photo) async {
    uploadCalls++;
    await onAccountAction?.call();
    return currentUser;
  }

  @override
  Future<AuthUser> deletePhoto() async {
    await onAccountAction?.call();
    return currentUser;
  }

  @override
  Uri? photoUri(AuthUser user) => null;

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
