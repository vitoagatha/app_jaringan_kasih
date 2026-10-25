import 'package:app_jaringan_kasih/features/auth/data/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Secure storage adapter isolates backend addresses and deletes one key',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureTokenStore(Uri.parse('http://127.0.0.1:8000/api/v1/'));
    final other = SecureTokenStore(Uri.parse('http://10.0.2.2:8000/api/v1/'));
    await local.write('local-test-token');
    await other.write('other-test-token');
    expect(await local.read(), 'local-test-token');
    expect(await other.read(), 'other-test-token');
    await local.delete();
    expect(await local.read(), isNull);
    expect(await other.read(), 'other-test-token');
  });
}
