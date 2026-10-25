import 'dart:async';

import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/health/data/health_repository.dart';
import 'package:app_jaringan_kasih/main_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Menampilkan loading lalu koneksi backend berhasil',
      (tester) async {
    final completer = Completer<HealthStatus>();
    await tester
        .pumpWidget(LocalBackendApp(checkHealth: () => completer.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(HealthStatus(
        service: 'jaringan-kasih-api', timestamp: DateTime.utc(2026, 10, 25)));
    await tester.pumpAndSettle();

    expect(find.text('API Laravel dan PostgreSQL terhubung.'), findsOneWidget);
    expect(find.text('Layanan: jaringan-kasih-api'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Pengguna dapat mencoba ulang setelah koneksi gagal',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(LocalBackendApp(checkHealth: () async {
      attempts++;
      if (attempts == 1) {
        throw const ApiException('Server belum tersedia.');
      }
      return HealthStatus(
          service: 'jaringan-kasih-api', timestamp: DateTime.utc(2026, 10, 25));
    }));
    await tester.pumpAndSettle();
    expect(find.text('Server belum tersedia.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('API Laravel dan PostgreSQL terhubung.'), findsOneWidget);
    expect(find.text('Server belum tersedia.'), findsNothing);
  });

  testWidgets('Periksa ulang menampilkan loading dan hasil pemeriksaan baru',
      (tester) async {
    var attempts = 0;
    final nextCheck = Completer<HealthStatus>();
    await tester.pumpWidget(LocalBackendApp(checkHealth: () {
      attempts++;
      if (attempts == 1) {
        return Future.value(HealthStatus(
            service: 'hasil-pertama', timestamp: DateTime.utc(2026, 10, 25)));
      }
      return nextCheck.future;
    }));
    await tester.pumpAndSettle();
    expect(find.text('Layanan: hasil-pertama'), findsOneWidget);

    await tester.tap(find.text('Periksa ulang'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    nextCheck.complete(HealthStatus(
        service: 'hasil-terbaru', timestamp: DateTime.utc(2026, 10, 25, 1)));
    await tester.pumpAndSettle();
    expect(find.text('Layanan: hasil-terbaru'), findsOneWidget);
    expect(find.text('Layanan: hasil-pertama'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
