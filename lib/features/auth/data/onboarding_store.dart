import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class OnboardingStore {
  Future<bool> hasCompleted();
  Future<void> complete();
}

class SecureOnboardingStore implements OnboardingStore {
  static const _key = 'jk_onboarding_complete_v1';
  final FlutterSecureStorage _storage;

  SecureOnboardingStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
                aOptions: AndroidOptions(encryptedSharedPreferences: true));

  @override
  Future<bool> hasCompleted() async => await _storage.read(key: _key) == 'true';

  @override
  Future<void> complete() => _storage.write(key: _key, value: 'true');
}
