import 'dart:io';

import 'package:app_jaringan_kasih/core/config/api_config.dart';
import 'package:app_jaringan_kasih/core/network/api_client.dart';
import 'package:app_jaringan_kasih/features/health/data/health_repository.dart';

Future<void> main(List<String> arguments) async {
  final client = ApiClient(
      baseUri: arguments.isEmpty
          ? ApiConfig.baseUri
          : ApiConfig.parseBaseUri(arguments.single));
  try {
    final health = await HealthRepository(client).check();
    stdout.writeln(
        'PASS: ${health.service}; PostgreSQL connected; ${health.timestamp.toIso8601String()}');
  } finally {
    client.close();
  }
}
