import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:coetus/preview/preview_repositories.dart';
import 'package:coetus/features/auth/domain/models/app_user.dart';
import 'package:coetus/features/profile/domain/models/profile_data.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';
import '../domain/profile_identity.dart';

class ProfileConnectionResult {
  const ProfileConnectionResult({
    required this.id,
    required this.chatId,
    required this.confirmed,
  });
  final String id, chatId;
  final bool confirmed;
}

class ProfileIdentityService {
  bool get local => PreviewMode.enabled || Firebase.apps.isEmpty;
  String get currentUserId =>
      local ? PreviewMode.userId : FirebaseAuth.instance.currentUser?.uid ?? '';
  static final Map<String, String> _localNames = {};
  Future<String> claimUsername(
    String username, {
    bool automatic = false,
  }) async {
    final name = normalizeUsername(username);
    if (!automatic && usernameError(name) != null) {
      throw FormatException(usernameError(name)!);
    }
    if (local) {
      final actual = automatic ? suggestUsername(name, '00001') : name;
      if (PreviewProfileRepository.candidates.any(
        (p) => p.user.username == actual && p.user.id != currentUserId,
      )) {
        throw StateError('Bu kullanıcı adı kullanımda.');
      }
      final owner = _localNames[actual];
      if (owner != null && owner != currentUserId) {
        throw StateError('Bu kullanıcı adı kullanımda.');
      }
      _localNames[actual] = currentUserId;
      PreviewProfileRepository.profile = PreviewProfileRepository.profile
          .copyWith(
            user: PreviewProfileRepository.profile.user.copyWith(
              username: actual,
            ),
          );
      return actual;
    }
    final db = FirebaseFirestore.instance;
    for (var attempt = 0; attempt < 8; attempt++) {
      final actual = automatic
          ? suggestUsername(
              name,
              Random.secure().nextInt(0xffffff).toRadixString(16),
            )
          : name;
      try {
        return await db.runTransaction((tx) async {
          final userRef = db.doc('users/$currentUserId');
          final user = await tx.get(userRef);
          if (!user.exists) throw StateError('Önce profilini oluştur.');
          final old = user.data()?['username'] as String? ?? '';
          final oldRef = usernameError(old) == null
              ? db.doc('usernames/$old')
              : null;
          final oldDoc = oldRef == null ? null : await tx.get(oldRef);
          if (automatic &&
              oldDoc?.data()?['userId'] == currentUserId &&
              oldDoc?.data()?['active'] == true) {
            return old;
          }
          final nameRef = db.doc('usernames/$actual');
          final reservation = await tx.get(nameRef);
          if (reservation.exists &&
              reservation.data()?['userId'] != currentUserId) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'already-exists',
              message: 'Bu kullanıcı adı kullanımda.',
            );
          }
          if (old != actual && oldDoc?.data()?['userId'] == currentUserId) {
            tx.update(oldRef!, {
              'active': false,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          tx.set(nameRef, {
            'userId': currentUserId,
            'active': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          tx.update(userRef, {
            'username': actual,
            'usernameChangedAt': FieldValue.serverTimestamp(),
          });
          return actual;
        });
      } on FirebaseException catch (error) {
        if (!automatic || error.code != 'already-exists') rethrow;
      }
    }
    throw StateError('Kullanıcı adı oluşturulamadı. Yeniden dene.');
  }

  Future<ProfileData> find({String? username, String? userId}) async {
    if (local) {
      final profiles = [
        PreviewProfileRepository.profile,
        ...PreviewProfileRepository.candidates,
      ];
      final query = username == null ? null : normalizeUsername(username);
      final matches = profiles.where(
        (p) => userId != null
            ? p.user.id == userId
            : normalizeUsername(p.user.username).isNotEmpty &&
                  normalizeUsername(p.user.username) == query,
      );
      if (matches.isEmpty) throw StateError('Kullanıcı bulunamadı.');
      return matches.first;
    }
    final db = FirebaseFirestore.instance;
    var uid = userId;
    if (username != null) {
      final name = normalizeUsername(username);
      if (usernameError(name) != null) {
        throw FormatException(usernameError(name)!);
      }
      final entry = await db.doc('usernames/$name').get();
      if (entry.data()?['active'] != true) {
        throw StateError('Kullanıcı bulunamadı.');
      }
      uid = entry.data()?['userId'] as String?;
    }
    if (uid == null || !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(uid)) {
      throw StateError('Geçersiz profil.');
    }
    final userRef = db.doc('users/$uid');
    final user = await userRef.get();
    if (!user.exists || user.data()?['accountDeletionPending'] == true) {
      throw StateError('Kullanıcı bulunamadı.');
    }
    final data = user.data()!;
    final teach = await userRef.collection('teachSkills').get();
    final learn = await userRef.collection('learnSkills').get();
    return ProfileData(
      user: AppUser.fromMap({
        'id': uid,
        'name': data['displayName'] ?? data['name'] ?? 'Kullanıcı',
        'username': data['username'] ?? '',
        'bio': data['bio'] ?? '',
        'photoUrl': data['photoUrl'] ?? '',
        'location': data['location'] ?? '',
        'trustScore': data['trustScore'] ?? 0,
      }),
      teachSkills: teach.docs
          .map((s) => SkillModel.fromMap({...s.data(), 'id': s.id}))
          .toList(),
      learnSkills: learn.docs
          .map((s) => SkillModel.fromMap({...s.data(), 'id': s.id}))
          .toList(),
    );
  }

  Future<ProfileConnectionResult> connect(String userId) async {
    if (userId == currentUserId) throw StateError('Bu senin profilin.');
    if (local) {
      return const ProfileConnectionResult(
        id: 'preview-connection',
        chatId: 'preview-chat',
        confirmed: true,
      );
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(userId)) {
      throw StateError('Geçersiz profil.');
    }
    final db = FirebaseFirestore.instance;
    final participants = [currentUserId, userId]..sort();
    final id =
        'face_${base64Url.encode(utf8.encode(jsonEncode(participants))).replaceAll('=', '')}';
    return db.runTransaction((tx) async {
      final ref = db.doc('profileConnections/$id');
      final mine = await tx.get(db.doc('users/$currentUserId'));
      final theirs = await tx.get(db.doc('users/$userId'));
      final connection = await tx.get(ref);
      final chat = await tx.get(db.doc('chats/$id'));
      if (!mine.exists ||
          !theirs.exists ||
          theirs.data()?['accountDeletionPending'] == true) {
        throw StateError('Profil bulunamadı.');
      }
      final votes = List<String>.from(connection.data()?['confirmedBy'] ?? []);
      if (!votes.contains(currentUserId)) votes.add(currentUserId);
      final confirmed = participants.every(votes.contains);
      if (!(connection.data()?['confirmedBy'] as List? ?? []).contains(
        currentUserId,
      )) {
        tx.set(
          ref,
          {
            'participants': participants,
            'confirmedBy': votes,
            'status': confirmed ? 'confirmed' : 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
            if (!connection.exists) 'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        if (!confirmed) {
          tx.set(db.doc('notifications/${id}_$currentUserId'), {
            'userId': userId,
            'senderId': currentUserId,
            'type': 'profile_connection',
            'title': 'Tanışma isteği',
            'message': 'Profilini açıp tanışmayı onaylayabilirsin.',
            'targetRoute': '/find-profile',
            'targetId': currentUserId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      if (confirmed && !chat.exists) {
        tx.set(db.doc('chats/$id'), {
          'id': id,
          'participants': participants,
          'participantNames': {
            currentUserId:
                mine.data()?['displayName'] ??
                mine.data()?['name'] ??
                'Kullanıcı',
            userId:
                theirs.data()?['displayName'] ??
                theirs.data()?['name'] ??
                'Kullanıcı',
          },
          'kind': 'in_person',
          'credits': 0,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return ProfileConnectionResult(id: id, chatId: id, confirmed: confirmed);
    });
  }

  Stream<bool> watchConnection(String id) => local
      ? Stream.value(true)
      : FirebaseFirestore.instance
            .doc('profileConnections/$id')
            .snapshots()
            .map((s) => s.data()?['status'] == 'confirmed');
}

String identityError(Object error) {
  if (error is StateError) return error.message;
  if (error is FormatException) return error.message;
  if (error is FirebaseException) {
    return error.message ?? 'İşlem tamamlanamadı.';
  }
  return 'Bağlantı kurulamadı. Yeniden dene.';
}
