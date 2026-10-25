import 'dart:io';

import 'package:app_jaringan_kasih/core/network/api_client.dart';
import 'package:app_jaringan_kasih/features/funding/data/funding_repository.dart';
import 'package:app_jaringan_kasih/features/funding/presentation/funding_cover.dart';
import 'package:app_jaringan_kasih/features/funding/presentation/funding_editor.dart';
import 'package:app_jaringan_kasih/features/profile/data/photo_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const initial = FundingRecord(
    id: 1,
    title: 'Pendanaan foto',
    description: 'Deskripsi lengkap pendanaan dengan gambar.',
    targetAmount: 100000,
    ownerId: 1,
    ownerName: 'Pemilik',
    category: FundingCategory(1, 'Pendidikan'),
    status: 'published',
    saved: false);

class StubFundingPhotoPicker implements PhotoPicker {
  MultipartPhoto? selected;
  MultipartPhoto? recovered;
  String? purpose;
  @override
  Future<MultipartPhoto?> pick(PhotoSource source,
      {String purpose = 'profile'}) async {
    this.purpose = purpose;
    return selected;
  }

  @override
  Future<MultipartPhoto?> recover({String purpose = 'profile'}) async {
    this.purpose = purpose;
    return recovered;
  }
}

void main() {
  late StubFundingPhotoPicker picker;
  FundingDraft? submitted;
  int calls = 0;
  setUp(() {
    picker = StubFundingPhotoPicker();
    submitted = null;
    calls = 0;
  });
  Future<void> open(WidgetTester tester, {Uri? image}) async {
    await tester.pumpWidget(MaterialApp(
        home: FundingEditor(
            initial: initial,
            initialPhoto: image,
            categories: const [FundingCategory(1, 'Pendidikan')],
            busy: false,
            picker: picker,
            photoPurpose: 'funding:1:1',
            onBack: () {},
            onSave: (draft) async {
              calls++;
              submitted = draft;
              return true;
            })));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(Key(key));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  MultipartPhoto image() => validatePhotoBytes(
      File('assets/images/icon_launcher2.png').readAsBytesSync());

  testWidgets(
      'Pick shows preview without uploading until the whole funding is saved',
      (tester) async {
    picker.selected = image();
    await open(tester);
    await tap(tester, 'funding_photo_gallery');
    expect(calls, 0);
    expect(find.byType(FundingCover), findsOneWidget);
    expect(tester.widget<FundingCover>(find.byType(FundingCover)).preview,
        isNotNull);
    await tap(tester, 'funding_save');
    expect(calls, 1);
    expect(submitted!.photo!.mimeType, 'image/png');
    expect(submitted!.removePhoto, isFalse);
    expect(picker.purpose, 'funding:1:1');
  });

  testWidgets(
      'Cancelling a selection preserves existing cover without a removal flag',
      (tester) async {
    picker.selected = image();
    final original =
        Uri.parse('http://127.0.0.1:8000/storage/fundings/old.png');
    await open(tester, image: original);
    await tap(tester, 'funding_photo_gallery');
    await tap(tester, 'funding_photo_cancel');
    expect(
        tester.widget<FundingCover>(find.byType(FundingCover)).uri, original);
    await tap(tester, 'funding_save');
    expect(submitted!.photo, isNull);
    expect(submitted!.removePhoto, isFalse);
  });

  testWidgets('Delete only takes effect when saving the funding',
      (tester) async {
    await open(tester,
        image: Uri.parse('http://127.0.0.1:8000/storage/fundings/old.png'));
    await tap(tester, 'funding_photo_remove');
    expect(calls, 0);
    await tap(tester, 'funding_save');
    expect(submitted!.removePhoto, isTrue);
    expect(submitted!.photo, isNull);
  });

  testWidgets('Recovered cover stays a preview and keeps its funding context',
      (tester) async {
    picker.recovered = image();
    await open(tester);
    expect(picker.purpose, 'funding:1:1');
    expect(tester.widget<FundingCover>(find.byType(FundingCover)).preview,
        isNotNull);
    expect(calls, 0);
  });
}
