import 'dart:io';

import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'features/auth/application/session_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/token_store.dart';
import 'features/auth/presentation/auth_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final baseUri = ApiConfig.baseUri;
  final session = SessionController(AuthRepository(
    baseUri: baseUri,
    store: SecureTokenStore(baseUri),
    deviceName: 'Jaringan Kasih ${Platform.operatingSystem}',
  ));
  runApp(JaringanKasihApp(session: session));
}
