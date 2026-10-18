import 'package:coetus/preview/preview_mode.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../domain/skill_verification.dart';

class VerificationService {
  String? _pendingEntryId, _pendingSignature;
  List<String>? _pendingPaths;
  FirebaseFirestore get _db {
    if (PreviewMode.enabled) {
      throw StateError('Önizlemede sunucu işlemi yapılmaz.');
    }
    return FirebaseFirestore.instance;
  }

  FirebaseStorage get _storage {
    if (PreviewMode.enabled) throw StateError('Önizlemede dosya yüklenmez.');
    return FirebaseStorage.instance;
  }

  FirebaseFunctions get _functions {
    if (PreviewMode.enabled) {
      throw StateError('Önizlemede sunucu işlemi yapılmaz.');
    }
    return FirebaseFunctions.instanceFor(region: 'europe-west1');
  }

  String get userId => PreviewMode.enabled
      ? PreviewMode.userId
      : FirebaseAuth.instance.currentUser?.uid ??
            (throw StateError('Önce giriş yapmalısın.'));

  Stream<List<SkillVerification>> watch({String? ownerId}) {
    if (PreviewMode.enabled) {
      return Stream.value(const [
        SkillVerification(
          id: 'preview-work',
          ownerId: PreviewMode.userId,
          skillName: 'Gitar',
          status: 'published',
          type: 'portfolio',
          description:
              'Bu hafta öğrendiğim akor geçişlerini bir araya getirdim.',
          ownerName: 'Deniz',
        ),
      ]);
    }
    Query<Map<String, dynamic>> query = _db
        .collection('skillVerifications')
        .where('ownerId', isEqualTo: ownerId ?? userId);
    if (ownerId != null && ownerId != userId) {
      query = query.where('status', whereIn: ['approved', 'published']);
    }
    return query.snapshots().map(
      (s) => s.docs
          .map(SkillVerification.fromDoc)
          .where(
            (v) =>
                ownerId == null ||
                ownerId == userId ||
                ['approved', 'published'].contains(v.status),
          )
          .toList(),
    );
  }

  Future<void> submit({
    required String skillId,
    required String description,
    required List<XFile> files,
    required void Function(double) onProgress,
  }) async {
    if (description.trim().length < 10) {
      throw const FormatException('Açıklama en az 10 karakter olmalı.');
    }
    if (files.length > 3) {
      throw const FormatException(
        'En fazla 3 fotoğraf veya video ekleyebilirsin.',
      );
    }
    final uid = userId;
    final signature =
        '$uid|$skillId|${description.trim()}|${files.map((f) => f.path).join('|')}';
    if (_pendingSignature != signature) {
      _pendingEntryId = null;
      _pendingPaths = null;
      _pendingSignature = signature;
    }
    final folder = _pendingEntryId ??= _db
        .collection('skillVerifications')
        .doc()
        .id;
    final paths = _pendingPaths ?? <String>[];
    if (_pendingPaths == null) {
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        if (await file.length() > 50 * 1024 * 1024) {
          throw const FormatException('Dosya en fazla 50 MB olabilir.');
        }
        final bytes = await file.readAsBytes();
        final mime =
            lookupMimeType(file.name, headerBytes: bytes.take(32).toList()) ??
            '';
        final limit = mime.startsWith('video/')
            ? 50 * 1024 * 1024
            : 10 * 1024 * 1024;
        if (![
              'image/jpeg',
              'image/png',
              'image/webp',
              'video/mp4',
              'video/quicktime',
              'video/webm',
            ].contains(mime) ||
            bytes.isEmpty ||
            bytes.length > limit) {
          throw const FormatException(
            'Fotoğraf en fazla 10 MB, video en fazla 50 MB olmalı. JPG, PNG, WebP, MP4, MOV veya WebM kullan.',
          );
        }
        final ref = _storage.ref(
          'portfolioMedia/$uid/$folder/${DateTime.now().microsecondsSinceEpoch}_$i',
        );
        final task = ref.putData(bytes, SettableMetadata(contentType: mime));
        final subscription = task.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            onProgress(
              (i + event.bytesTransferred / event.totalBytes) / files.length,
            );
          }
        });
        try {
          await task;
        } finally {
          await subscription.cancel();
        }
        paths.add(ref.fullPath);
      }
      _pendingPaths = List.of(paths);
    }
    await _functions.httpsCallable('submitSkillEvidence').call({
      'skillId': skillId,
      'entryId': folder,
      'description': description.trim(),
      'paths': paths,
    });
    _pendingEntryId = null;
    _pendingPaths = null;
    _pendingSignature = null;
  }

  Future<void> endorse({
    required String sessionId,
    required String teacherId,
    required String skillName,
    required String comment,
  }) async {
    final skills = await _db
        .collection('users')
        .doc(teacherId)
        .collection('teachSkills')
        .where('name', isEqualTo: skillName)
        .limit(1)
        .get();
    if (skills.docs.isEmpty) {
      throw StateError('Bu yetenek artık profilde bulunmuyor.');
    }
    await _functions.httpsCallable('endorseTeaching').call({
      'sessionId': sessionId,
      'skillId': skills.docs.first.id,
      'comment': comment,
    });
  }

  Future<String> mediaUrl(String path) => _storage.ref(path).getDownloadURL();
}

String verificationError(Object error) {
  if (error is FirebaseFunctionsException) {
    if (error.code == 'not-found' || error.code == 'unimplemented') {
      return 'Çalışma ve eşleşme hizmeti henüz etkin değil. Lütfen daha sonra tekrar dene.';
    }
    return error.message ?? 'İşlem tamamlanamadı.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' || 'unauthorized' =>
        'Bu işlem için iznin yok. Hesabını ve bağlantını kontrol et.',
      'unavailable' ||
      'network-request-failed' => 'Bağlantı kurulamadı. Lütfen yeniden dene.',
      'bucket-not-found' ||
      'object-not-found' => 'Kanıt dosyası veya yükleme alanı bulunamadı.',
      _ => 'İşlem tamamlanamadı. Lütfen yeniden dene.',
    };
  }
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message;
  return 'İşlem tamamlanamadı. Lütfen yeniden dene.';
}
