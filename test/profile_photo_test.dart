import 'dart:convert';
import 'package:coetus/app/theme/coetus_theme.dart';
import 'package:coetus/features/auth/domain/models/app_user.dart';
import 'package:coetus/features/profile/data/repositories/local_profile_repository.dart';
import 'package:coetus/features/profile/data/services/profile_photo_service.dart';
import 'package:coetus/features/profile/domain/models/profile_data.dart';
import 'package:coetus/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:coetus/features/profile/presentation/widgets/profile_photo_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

final image = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
);
XFile photoFile() =>
    XFile.fromData(image, name: 'photo.png', mimeType: 'image/png');

class PhotoRepository extends LocalProfileRepository {
  ProfileData profile = const ProfileData(
    user: AppUser(
      id: 'me',
      name: 'Deniz',
      email: '',
      bio: '',
      photoUrl: 'old-photo',
    ),
    teachSkills: [],
    learnSkills: [],
  );
  int saves = 0;
  bool failNextSave = false;
  @override
  Future<ProfileData> loadProfile() async => profile;
  @override
  Future<ProfileData> updateProfile(AppUser user) async {
    saves++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Bağlantı kesildi. Yeniden dene.');
    }
    return profile = profile.copyWith(user: user);
  }
}

Future<GoRouter> openEditor(
  WidgetTester tester,
  PhotoRepository repository, {
  required Future<XFile?> Function(ImageSource) pick,
  required Future<String> Function(ProfilePhoto) upload,
}) async {
  final router = GoRouter(
    initialLocation: '/edit',
    routes: [
      GoRoute(
        path: '/edit',
        builder: (_, _) => EditProfilePage(
          repository: repository,
          pickPhoto: pick,
          uploadPhoto: upload,
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('Kaydedilen profil')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: coetusTheme(useGoogleFonts: false),
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> pickFrom(WidgetTester tester, String source) async {
  final button = find.text('Galeriden seç veya fotoğraf çek');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.tap(find.text(source));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Profili Güncelle'));
  await tester.tap(find.text('Profili Güncelle'));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'photo validation rejects empty, oversized and unsupported files',
    () async {
      expect((await ProfilePhoto.read(photoFile())).contentType, 'image/png');
      await expectLater(
        ProfilePhoto.read(XFile.fromData(Uint8List(0), name: 'empty.png')),
        throwsFormatException,
      );
      await expectLater(
        ProfilePhoto.read(
          XFile.fromData(
            Uint8List(ProfilePhoto.maxBytes + 1),
            name: 'large.png',
          ),
        ),
        throwsFormatException,
      );
      await expectLater(
        ProfilePhoto.read(
          XFile.fromData(utf8.encode('<svg/>'), name: 'script.svg'),
        ),
        throwsFormatException,
      );
    },
  );

  for (final source in [
    (ImageSource.gallery, 'Galeriden fotoğraf seç'),
    (ImageSource.camera, 'Fotoğraf çek'),
  ]) {
    testWidgets(
      '${source.$2} previews the image and uploads only when saving',
      (tester) async {
        final repo = PhotoRepository();
        var uploads = 0;
        ImageSource? chosen;
        await openEditor(
          tester,
          repo,
          pick: (value) async {
            chosen = value;
            return photoFile();
          },
          upload: (photo) async {
            uploads++;
            expect(photo.bytes, image);
            return 'new-photo';
          },
        );
        expect(find.text('Profil fotoğrafı bağlantısı'), findsNothing);
        expect(find.text('Profil fotoğrafı ekle'), findsOneWidget);
        await pickFrom(tester, source.$2);
        expect(chosen, source.$1);
        expect(uploads, 0);
        expect(repo.saves, 0);
        expect(
          tester
              .widget<ProfilePhotoAvatar>(find.byType(ProfilePhotoAvatar))
              .bytes,
          image,
        );
        await save(tester);
        expect(uploads, 1);
        expect(repo.saves, 1);
        expect(repo.profile.user.photoUrl, 'new-photo');
        expect(find.text('Kaydedilen profil'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('cancelled picker preserves the existing photo', (tester) async {
    final repo = PhotoRepository();
    var uploads = 0;
    await openEditor(
      tester,
      repo,
      pick: (_) async => null,
      upload: (_) async {
        uploads++;
        return 'wrong';
      },
    );
    await pickFrom(tester, 'Galeriden fotoğraf seç');
    await save(tester);
    expect(repo.profile.user.photoUrl, 'old-photo');
    expect(uploads, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('permission denial keeps profile unchanged and lets user retry', (
    tester,
  ) async {
    final repo = PhotoRepository();
    await openEditor(
      tester,
      repo,
      pick: (_) async => throw PlatformException(code: 'camera_access_denied'),
      upload: (_) async => 'wrong',
    );
    await pickFrom(tester, 'Fotoğraf çek');
    expect(
      find.text(
        'Fotoğraf seçilemedi. Kamera veya galeri iznini kontrol edip yeniden dene.',
      ),
      findsOneWidget,
    );
    expect(repo.saves, 0);
    expect(repo.profile.user.photoUrl, 'old-photo');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'profile save retry reuses the uploaded image instead of uploading twice',
    (tester) async {
      final repo = PhotoRepository()..failNextSave = true;
      var uploads = 0;
      await openEditor(
        tester,
        repo,
        pick: (_) async => photoFile(),
        upload: (_) async {
          uploads++;
          return 'new-photo';
        },
      );
      await pickFrom(tester, 'Galeriden fotoğraf seç');
      await save(tester);
      expect(repo.profile.user.photoUrl, 'old-photo');
      await save(tester);
      expect(uploads, 1);
      expect(repo.saves, 2);
      expect(repo.profile.user.photoUrl, 'new-photo');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('upload error does not save a broken photo URL', (tester) async {
    final repo = PhotoRepository();
    await openEditor(
      tester,
      repo,
      pick: (_) async => photoFile(),
      upload: (_) async => throw StateError('Fotoğraf yüklenemedi.'),
    );
    await pickFrom(tester, 'Galeriden fotoğraf seç');
    await save(tester);
    expect(find.text('Fotoğraf yüklenemedi.'), findsOneWidget);
    expect(repo.saves, 0);
    expect(repo.profile.user.photoUrl, 'old-photo');
    await tester.pumpWidget(const SizedBox());
  });
}
