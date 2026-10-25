import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/network/api_exception.dart';
import 'features/health/data/health_repository.dart';

void main() => runApp(const LocalBackendApp());

/// Entrypoint pengembangan P0; auth aplikasi dipindahkan pada P1.
class LocalBackendApp extends StatelessWidget {
  final Future<HealthStatus> Function()? checkHealth;

  const LocalBackendApp({super.key, this.checkHealth});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Jaringan Kasih Lokal',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: _HealthScreen(checkHealth: checkHealth),
      );
}

class _HealthScreen extends StatefulWidget {
  final Future<HealthStatus> Function()? checkHealth;

  const _HealthScreen({this.checkHealth});

  @override
  State<_HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<_HealthScreen> {
  ApiClient? _client;
  late Future<HealthStatus> _health;

  @override
  void initState() {
    super.initState();
    if (widget.checkHealth == null) {
      _client = ApiClient(baseUri: ApiConfig.baseUri);
    }
    _health = _check();
  }

  Future<HealthStatus> _check() =>
      widget.checkHealth?.call() ?? HealthRepository(_client!).check();

  void _refresh() {
    final nextCheck = _check();
    setState(() {
      _health = nextCheck;
    });
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Jaringan Kasih — P0')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Koneksi backend lokal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SelectableText(ApiConfig.baseUri.toString()),
            const SizedBox(height: 24),
            FutureBuilder<HealthStatus>(
              future: _health,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(error is ApiException
                            ? error.message
                            : 'Pemeriksaan koneksi gagal.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Coba lagi'),
                        ),
                      ]);
                }
                final status = snapshot.data!;
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.teal, size: 48),
                      const SizedBox(height: 12),
                      const Text('API Laravel dan PostgreSQL terhubung.'),
                      Text('Layanan: ${status.service}'),
                      Text('Diperiksa: ${status.timestamp.toLocal()}'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _refresh,
                        child: const Text('Periksa ulang'),
                      ),
                    ]);
              },
            ),
          ],
        ),
      );
}
