import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/chat_models.dart';

class FirebaseChatRepository {
  FirebaseChatRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<List<ChatThread>> watchThreads() {
    final user = currentUser;
    if (user == null) return Stream.value(const []);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
          final threads = snapshot.docs.map(ChatThread.fromSnapshot).toList()
            ..sort((a, b) {
              final aTime =
                  a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });
          return threads;
        });
  }

  Stream<ChatThread?> watchThread(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatThread.fromSnapshot(doc);
    });
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ChatMessage.fromSnapshot).toList(),
        );
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String text,
  }) async {
    final user = currentUser;
    final trimmed = text.trim();
    if (user == null || trimmed.isEmpty) return;

    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final senderName = await _currentUserName(user);

    final batch = _firestore.batch();
    batch.set(messageRef, {
      'id': messageRef.id,
      'senderId': user.uid,
      'senderName': senderName,
      'text': trimmed,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(chatRef, {
      'lastMessage': trimmed,
      'lastSenderId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<String> createOrUpdateThread({
    required String otherUserId,
    required String otherUserName,
    required String skillName,
    String? matchId,
    String? sessionId,
    int credits = 0,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Chat olusturmak icin once giris yapmalisin.');
    }

    final participants = [user.uid, otherUserId]..sort();
    final chatId = participants.join('_');
    final userName = await _currentUserName(user);

    await _firestore.collection('chats').doc(chatId).set({
      'id': chatId,
      'participants': participants,
      'participantNames': {user.uid: userName, otherUserId: otherUserName},
      'participantSkills': {
        otherUserId: [skillName],
      },
      'matchId': matchId,
      'sessionId': sessionId,
      'skillName': skillName,
      'lastMessage': '$skillName icin sohbet baslatildi.',
      'lastSenderId': user.uid,
      'unreadCount': 0,
      'credits': credits,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatId;
  }

  Future<String> _currentUserName(User user) async {
    if (user.displayName?.trim().isNotEmpty == true) {
      return user.displayName!.trim();
    }

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    final name = data?['displayName'] as String? ?? data?['name'] as String?;
    if (name?.trim().isNotEmpty == true) return name!.trim();
    return user.email?.split('@').first ?? 'Kullanici';
  }
}
