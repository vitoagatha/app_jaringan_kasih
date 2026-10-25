import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_jaringan_kasih/core/network/api_client.dart';
import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/auth/application/session_controller.dart';
import 'package:app_jaringan_kasih/features/auth/presentation/auth_app.dart';
import 'package:app_jaringan_kasih/features/profile/data/photo_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth.dart';

class FakePhotoPicker implements PhotoPicker {
  Future<MultipartPhoto?> Function() onPick = () async => null;
  Future<MultipartPhoto?> Function() onRecover = () async => null;
  @override
  Future<MultipartPhoto?> pick(PhotoSource source) => onPick();
  @override
  Future<MultipartPhoto?> recover() => onRecover();
}

void main() {
  Future<void> open(WidgetTester tester, FakeAuth auth,
      {bool signedIn = true, PhotoPicker? picker}) async {
    if (signedIn) auth.onRestore = () async => FakeAuth.account;
    await tester.pumpWidget(JaringanKasihApp(
        session: SessionController(auth), photoPicker: picker));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.scrollUntilVisible(find.byKey(Key(key)), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('Profile form saves name and refreshes account without logout',
      (tester) async {
    final auth = FakeAuth();
    await open(tester, auth);
    await tap(tester, 'edit_profile');
    await tester.enterText(
        find.descendant(
            of: find.byKey(const Key('profile_name')),
            matching: find.byType(TextFormField)),
        'Nama Baru');
    await tap(tester, 'profile_save');
    await tester.scrollUntilVisible(find.text('Halo, Nama Baru'), -200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Halo, Nama Baru'), findsOneWidget);
  });

  testWidgets('Verification action shows instructions after delivery succeeds',
      (tester) async {
    final auth = FakeAuth();
    await open(tester, auth);
    await tap(tester, 'verify_email');
    expect(auth.verificationCalls, 1);
    expect(find.textContaining('Tautan verifikasi dikirim.'), findsOneWidget);
  });

  testWidgets('Password change signs user out after successful request',
      (tester) async {
    final auth = FakeAuth();
    await open(tester, auth);
    await tap(tester, 'change_password');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'old-password');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.enterText(fields.at(2), 'new-password');
    await tap(tester, 'password_save');
    expect(find.byKey(const Key('auth_email')), findsOneWidget);
  });

  testWidgets(
      'Forgot password opens token form and reset returns success message',
      (tester) async {
    final auth = FakeAuth();
    await open(tester, auth, signedIn: false);
    await tap(tester, 'forgot_password');
    await tester.enterText(
        find.byType(TextFormField).first, 'belajar@example.test');
    await tap(tester, 'reset_submit');
    expect(auth.forgotCalls, 1);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), List.filled(64, 'a').join());
    await tester.enterText(fields.at(2), 'new-password');
    await tester.enterText(fields.at(3), 'new-password');
    await tap(tester, 'reset_submit');
    expect(auth.resetCalls, 1);
    expect(find.text('Password direset. Silakan login dengan password baru.'),
        findsOneWidget);
  });

  testWidgets('Cancelling gallery does not upload or change account',
      (tester) async {
    final auth = FakeAuth();
    await open(tester, auth, picker: FakePhotoPicker());
    await tap(tester, 'photo_gallery');
    expect(auth.uploadCalls, 0);
    expect(find.byKey(const Key('photo_upload')), findsNothing);
    expect(find.byKey(const Key('auth_email')), findsNothing);
  });

  testWidgets('Permission error is displayed without uploading',
      (tester) async {
    final auth = FakeAuth();
    final picker = FakePhotoPicker();
    picker.onPick = () async => throw const ApiException('Akses foto ditolak.');
    await open(tester, auth, picker: picker);
    await tap(tester, 'photo_gallery');
    expect(find.text('Akses foto ditolak.'), findsOneWidget);
    expect(auth.uploadCalls, 0);
  });

  testWidgets(
      'Gallery lifecycle preserves preview and upload requires confirmation',
      (tester) async {
    final auth = FakeAuth();
    final picker = FakePhotoPicker();
    final pending = Completer<MultipartPhoto?>();
    picker.onPick = () => pending.future;
    await open(tester, auth, picker: picker);
    await tap(tester, 'photo_gallery');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    auth.onRestore = () async => null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    pending.complete(validatePhotoBytes(
        File('assets/images/icon_launcher2.png').readAsBytesSync()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo_upload')), findsOneWidget);
    expect(auth.uploadCalls, 0);
    await tap(tester, 'photo_upload');
    expect(auth.uploadCalls, 1);
    expect(find.text('Foto profil disimpan.'), findsOneWidget);
  });

  testWidgets(
      'Recovered Android picker result remains preview until user uploads',
      (tester) async {
    final picker = FakePhotoPicker();
    final bytes = File('assets/images/icon_launcher2.png').readAsBytesSync();
    picker.onRecover = () async => validatePhotoBytes(bytes);
    final auth = FakeAuth();
    await open(tester, auth, picker: picker);
    expect(find.byKey(const Key('photo_upload')), findsOneWidget);
    expect(auth.uploadCalls, 0);
  });

  test('Unsupported and oversized images are rejected before upload', () {
    expect(() => validatePhotoBytes(Uint8List.fromList('<svg/>'.codeUnits)),
        throwsA(isA<ApiException>()));
    final bytes = Uint8List(MultipartPhoto.maxBytes + 1)
      ..setRange(0, 3, [255, 216, 255]);
    expect(() => validatePhotoBytes(bytes), throwsA(isA<ApiException>()));
  });

  test(
      '401 on account action clears revoked session instead of retaining account',
      () async {
    final auth = FakeAuth();
    final session = SessionController(auth);
    addTearDown(session.dispose);
    auth.onRestore = () async => FakeAuth.account;
    await session.restore();
    auth.onAccountAction =
        () async => throw const ApiException('Sesi berakhir.', statusCode: 401);
    auth.onRestore = () async => null;
    expect(await session.sendVerification(), isFalse);
    expect(session.phase, SessionPhase.signedOut);
    expect(session.user, isNull);
  });
}
