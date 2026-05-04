import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/repositories/chat_repository.dart';

class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ChatThread>> streamUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final chats = snapshot.docs.map(ChatThread.fromFirestore).toList();
          final enrichedChats = await _enrichMissingParticipantNames(chats);
          enrichedChats.sort((a, b) {
            final aDate = a.updatedAt ?? a.lastMessageAt ?? DateTime(0);
            final bDate = b.updatedAt ?? b.lastMessageAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          return enrichedChats;
        });
  }

  @override
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ChatMessage.fromFirestore).toList(),
        );
  }

  @override
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    await _firestore.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatRef);
      if (!chatSnapshot.exists) {
        throw StateError('Chat $chatId was not found.');
      }

      final chat = ChatThread.fromFirestore(chatSnapshot);
      if (!chat.participants.contains(senderId)) {
        throw StateError('Only a participant can send messages.');
      }

      final now = FieldValue.serverTimestamp();

      transaction.set(messageRef, {
        'id': messageRef.id,
        'senderId': senderId,
        'text': trimmedText,
        'type': ChatMessageType.text.name,
        'readBy': [senderId],
        'createdAt': now,
      });

      transaction.set(chatRef, {
        'id': chatId,
        'lastMessage': trimmedText,
        'lastSenderId': senderId,
        'lastMessageAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      for (final receiverId in chat.participants.where(
        (participantId) => participantId != senderId,
      )) {
        final notificationRef = _firestore.collection('notifications').doc();
        transaction.set(notificationRef, {
          'id': notificationRef.id,
          'userId': receiverId,
          'senderId': senderId,
          'type': 'new_message',
          'title': 'Yeni mesaj',
          'message': trimmedText,
          'targetRoute': '/chat-detail',
          'targetId': chatId,
          'matchId': chat.matchId,
          'sessionId': chat.sessionId,
          'read': false,
          'createdAt': now,
        });
      }
    });
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      final message = ChatMessage.fromFirestore(doc);
      if (!message.readBy.contains(userId)) {
        batch.set(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        }, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  Future<List<ChatThread>> _enrichMissingParticipantNames(
    List<ChatThread> chats,
  ) async {
    final missingUserIds = chats
        .expand((chat) => chat.participants)
        .where(
          (userId) =>
              userId.trim().isNotEmpty &&
              chats.any(
                (chat) =>
                    chat.participants.contains(userId) &&
                    (chat.participantNames[userId]?.trim().isEmpty ?? true),
              ),
        )
        .toSet();

    if (missingUserIds.isEmpty) return chats;

    final fetchedNames = <String, String>{};
    for (final userId in missingUserIds) {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      final data = snapshot.data();
      final name =
          data?['displayName'] as String? ??
          data?['name'] as String? ??
          data?['email'] as String? ??
          '';
      if (name.trim().isNotEmpty) {
        fetchedNames[userId] = name.trim();
      }
    }

    if (fetchedNames.isEmpty) return chats;

    return chats.map((chat) {
      final names = <String, String>{
        ...chat.participantNames,
        for (final userId in chat.participants)
          if (fetchedNames[userId] != null &&
              (chat.participantNames[userId]?.trim().isEmpty ?? true))
            userId: fetchedNames[userId]!,
      };
      return chat.copyWith(participantNames: names);
    }).toList();
  }
}
