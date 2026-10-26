import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/config/api_config.dart';
import 'core/presentation/app_layout.dart';
import 'features/auth/application/session_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/onboarding_store.dart';
import 'features/auth/data/token_store.dart';
import 'features/auth/presentation/auth_app.dart';
import 'features/profile/data/device_photo_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    runApp(const UnsupportedPlatformApp());
    return;
  }
  final baseUri = ApiConfig.baseUri;
  final session = SessionController(AuthRepository(
    baseUri: baseUri,
    store: SecureTokenStore(baseUri),
    deviceName: 'Jaringan Kasih ${Platform.operatingSystem}',
  ));
  runApp(JaringanKasihApp(
      session: session,
      photoPicker: DevicePhotoPicker(baseUri: baseUri),
      onboardingStore: SecureOnboardingStore()));
}
