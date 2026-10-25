import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class HealthStatus {
  final String service;
  final DateTime timestamp;

  const HealthStatus({required this.service, required this.timestamp});
}

class HealthRepository {
  final ApiClient client;

  const HealthRepository(this.client);

  Future<HealthStatus> check() async {
    final data = await client.get('health');
    if (data is! Map<String, dynamic> ||
        data['service'] is! String ||
        data['database'] != 'connected' ||
        data['timestamp'] is! String) {
      throw const ApiException('Data pemeriksaan server tidak valid.');
    }
    final timestamp = DateTime.tryParse(data['timestamp'] as String);
    if (timestamp == null) {
      throw const ApiException('Waktu pemeriksaan server tidak valid.');
    }
    return HealthStatus(
        service: data['service'] as String, timestamp: timestamp);
  }
}
