import 'dart:io';

import 'package:app_jaringan_kasih/core/network/api_exception.dart';
import 'package:app_jaringan_kasih/features/profile/data/device_photo_picker.dart';
import 'package:app_jaringan_kasih/features/profile/data/photo_selection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class StubImagePicker extends ImagePicker {
  XFile? selected;
  XFile? lost;
  bool interrupted = false;
  int recovered = 0;
  ImageSource? lastSource;
  @override
  Future<XFile?> pickImage(
      {required ImageSource source,
      double? maxWidth,
      double? maxHeight,
      int? imageQuality,
      CameraDevice preferredCameraDevice = CameraDevice.rear,
      bool requestFullMetadata = true}) async {
    lastSource = source;
    if (interrupted) throw PlatformException(code: 'activity_interrupted');
    return selected;
  }

  @override
  Future<LostDataResponse> retrieveLostData() async {
    recovered++;
    return lost == null
        ? LostDataResponse.empty()
        : LostDataResponse(files: [lost!]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StubImagePicker native;
  late DevicePhotoPicker picker;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterSecureStorage.setMockInitialValues({});
    native = StubImagePicker();
    picker = DevicePhotoPicker(
        picker: native, baseUri: Uri.parse('http://10.0.2.2:8000/api/v1/'));
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test(
      'Normal gallery cancellation clears context and does not recover another image',
      () async {
    expect(await picker.pick(PhotoSource.gallery, purpose: 'funding:1:new'),
        isNull);
    expect(await picker.recover(purpose: 'funding:1:new'), isNull);
    expect(native.recovered, 0);
  });

  test(
      'Funding recovery cannot be consumed as avatar or by another user/funding',
      () async {
    native.interrupted = true;
    await expectLater(picker.pick(PhotoSource.gallery, purpose: 'funding:1:23'),
        throwsA(isA<ApiException>()));
    native.lost = XFile.fromData(
        File('assets/images/icon_launcher2.png').readAsBytesSync(),
        name: 'cover.png');
    final restarted = DevicePhotoPicker(
        picker: native, baseUri: Uri.parse('http://10.0.2.2:8000/api/v1/'));
    expect(await restarted.recover(purpose: 'profile:1'), isNull);
    expect(await restarted.recover(purpose: 'funding:2:23'), isNull);
    expect(await restarted.recover(purpose: 'funding:1:24'), isNull);
    expect(native.recovered, 0);
    expect((await restarted.recover(purpose: 'funding:1:23'))!.mimeType,
        'image/png');
    expect(native.recovered, 1);
    expect(await restarted.recover(purpose: 'funding:1:23'), isNull);
  });

  test('Backend context is isolated when recovering a pending image', () async {
    native.interrupted = true;
    await expectLater(picker.pick(PhotoSource.camera, purpose: 'funding:1:new'),
        throwsA(isA<ApiException>()));
    final other = DevicePhotoPicker(
        picker: native, baseUri: Uri.parse('http://127.0.0.1:8000/api/v1/'));
    expect(await other.recover(purpose: 'funding:1:new'), isNull);
    expect(native.recovered, 0);
    expect(native.lastSource, ImageSource.camera);
  });
}
