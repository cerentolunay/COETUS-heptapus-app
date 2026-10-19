import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../../../preview/preview_mode.dart';

class ProfilePhoto {
  const ProfilePhoto({required this.bytes, required this.contentType});
  final Uint8List bytes;
  final String contentType;
  static const maxBytes = 5 * 1024 * 1024;

  static Future<ProfilePhoto> read(XFile file) async {
    if (await file.length() > maxBytes) {
      throw const FormatException('Profil fotoğrafı en fazla 5 MB olabilir.');
    }
    final bytes = await file.readAsBytes();
    final type = lookupMimeType(
      file.name,
      headerBytes: bytes.take(32).toList(),
    );
    if (bytes.isEmpty ||
        bytes.length > maxBytes ||
        !['image/jpeg', 'image/png', 'image/webp'].contains(type)) {
      throw const FormatException(
        'JPG, PNG veya WebP biçiminde bir fotoğraf seç.',
      );
    }
    return ProfilePhoto(bytes: bytes, contentType: type!);
  }
}

class ProfilePhotoService {
  Future<String> upload(ProfilePhoto photo) async {
    if (PreviewMode.enabled) {
      // Local preview repositories keep this URI only in process memory.
      return 'data:${photo.contentType};base64,${base64Encode(photo.bytes)}';
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Fotoğraf eklemek için önce giriş yapmalısın.');
    }
    final ext = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
    }[photo.contentType];
    if (ext == null ||
        photo.bytes.isEmpty ||
        photo.bytes.length > ProfilePhoto.maxBytes) {
      throw const FormatException('Geçerli bir profil fotoğrafı seç.');
    }
    try {
      final ref = FirebaseStorage.instance.ref(
        'profilePhotos/$uid/${DateTime.now().microsecondsSinceEpoch}.$ext',
      );
      await ref.putData(
        photo.bytes,
        SettableMetadata(contentType: photo.contentType),
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      if (error.code == 'unauthorized' || error.code == 'permission-denied') {
        throw StateError(
          'Profil fotoğrafı yükleme izni henüz etkin değil. Fotoğrafın kaydedilmedi.',
        );
      }
      rethrow;
    }
  }

  /// Best effort after the profile is saved; never deletes foreign media.
  Future<void> removePrevious(
    String? previousUrl,
    String replacementUrl,
  ) async {
    if (PreviewMode.enabled ||
        previousUrl == null ||
        previousUrl == replacementUrl) {
      return;
    }
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final storage = FirebaseStorage.instance;
      final ref = storage.refFromURL(previousUrl);
      if (ref.bucket != storage.bucket ||
          !ref.fullPath.startsWith('profilePhotos/$uid/')) {
        return;
      }
      await ref.delete();
    } catch (_) {
      // A cleanup failure must not turn a successful profile update into failure.
    }
  }
}
