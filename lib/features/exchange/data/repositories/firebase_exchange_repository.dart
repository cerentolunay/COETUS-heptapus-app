import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/exchange_session.dart';
import '../../domain/models/match_offer.dart';
import '../../domain/repositories/exchange_repository.dart';

class FirebaseExchangeRepository implements ExchangeRepository {
  FirebaseExchangeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<MatchOffer>> streamUserOffers(String userId) {
    return _firestore
        .collection('matches')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final offers = snapshot.docs.map(MatchOffer.fromFirestore).toList();
          offers.sort((a, b) {
            final aDate = a.createdAt ?? a.updatedAt ?? DateTime(0);
            final bDate = b.createdAt ?? b.updatedAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          return offers;
        });
  }

  @override
  Stream<List<ExchangeSession>> streamUserSessions(String userId) {
    return _firestore
        .collection('sessions')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map(ExchangeSession.fromFirestore)
              .toList();
          sessions.sort((a, b) {
            final aDate = a.updatedAt ?? a.createdAt ?? DateTime(0);
            final bDate = b.updatedAt ?? b.createdAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          return sessions;
        });
  }

  @override
  Future<void> acceptOffer(String matchId, String currentUserId) async {
    final matchRef = _firestore.collection('matches').doc(matchId);
    final sessionRef = _firestore.collection('sessions').doc(matchId);
    final chatRef = _firestore.collection('chats').doc(matchId);
    final notificationRef = _firestore.collection('notifications').doc();

    await _firestore.runTransaction((transaction) async {
      final matchSnapshot = await transaction.get(matchRef);
      if (!matchSnapshot.exists) {
        throw StateError('Match offer $matchId was not found.');
      }

      final offer = MatchOffer.fromFirestore(matchSnapshot);
      if (offer.receiverId != currentUserId) {
        throw StateError('Only the offer receiver can accept this offer.');
      }

      final participants = _normalizedParticipants(
        offer.participants.isEmpty
            ? [offer.requesterId, offer.receiverId]
            : offer.participants,
      );
      final requesterSnapshot = await transaction.get(
        _firestore.collection('users').doc(offer.requesterId),
      );
      final receiverSnapshot = await transaction.get(
        _firestore.collection('users').doc(offer.receiverId),
      );
      final participantNames = {
        offer.requesterId: _readUserName(requesterSnapshot),
        offer.receiverId: _readUserName(receiverSnapshot),
      };
      final now = FieldValue.serverTimestamp();

      transaction.set(matchRef, {
        'id': matchId,
        'status': MatchOfferStatus.accepted.name,
        'updatedAt': now,
      }, SetOptions(merge: true));

      transaction.set(sessionRef, {
        'id': sessionRef.id,
        'matchId': matchId,
        'teacherId': offer.receiverId,
        'studentId': offer.requesterId,
        'participants': participants,
        'skill': offer.skill,
        'credits': offer.credits,
        'status': ExchangeSessionStatus.active.name,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      transaction.set(chatRef, {
        'id': chatRef.id,
        'sessionId': sessionRef.id,
        'matchId': matchId,
        'participants': participants,
        'participantNames': participantNames,
        'skillName': offer.skill,
        'credits': offer.credits,
        'status': ExchangeSessionStatus.active.name,
        'lastMessage': '',
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      transaction.set(notificationRef, {
        'id': notificationRef.id,
        'userId': offer.requesterId,
        'senderId': currentUserId,
        'type': 'offer_accepted',
        'title': 'Teklif kabul edildi',
        'message': '${offer.skill} teklifin kabul edildi.',
        'targetRoute': '/chat-detail',
        'targetId': chatRef.id,
        'matchId': matchId,
        'sessionId': sessionRef.id,
        'read': false,
        'createdAt': now,
      });
    });
  }

  @override
  Future<void> rejectOffer(String matchId, String currentUserId) {
    return _closeOffer(
      matchId: matchId,
      currentUserId: currentUserId,
      status: MatchOfferStatus.rejected,
      notificationType: 'offer_rejected',
      notificationTitle: 'Teklif reddedildi',
      notificationMessage: 'Teklifin reddedildi.',
    );
  }

  @override
  Future<void> cancelOffer(String matchId, String currentUserId) {
    return _closeOffer(
      matchId: matchId,
      currentUserId: currentUserId,
      status: MatchOfferStatus.cancelled,
      notificationType: 'offer_rejected',
      notificationTitle: 'Teklif iptal edildi',
      notificationMessage: 'Teklif iptal edildi.',
    );
  }

  Future<void> _closeOffer({
    required String matchId,
    required String currentUserId,
    required MatchOfferStatus status,
    required String notificationType,
    required String notificationTitle,
    required String notificationMessage,
  }) async {
    final matchRef = _firestore.collection('matches').doc(matchId);
    final notificationRef = _firestore.collection('notifications').doc();

    await _firestore.runTransaction((transaction) async {
      final matchSnapshot = await transaction.get(matchRef);
      if (!matchSnapshot.exists) {
        throw StateError('Match offer $matchId was not found.');
      }

      final offer = MatchOffer.fromFirestore(matchSnapshot);
      if (!offer.participants.contains(currentUserId)) {
        throw StateError('Only a participant can update this offer.');
      }

      final otherUserId = offer.requesterId == currentUserId
          ? offer.receiverId
          : offer.requesterId;
      final now = FieldValue.serverTimestamp();

      transaction.set(matchRef, {
        'id': matchId,
        'status': status.name,
        'updatedAt': now,
      }, SetOptions(merge: true));

      transaction.set(notificationRef, {
        'id': notificationRef.id,
        'userId': otherUserId,
        'senderId': currentUserId,
        'type': notificationType,
        'title': notificationTitle,
        'message': notificationMessage,
        'targetRoute': '/notifications',
        'targetId': matchId,
        'matchId': matchId,
        'sessionId': null,
        'read': false,
        'createdAt': now,
      });
    });
  }

  List<String> _normalizedParticipants(List<String> participants) {
    return participants.where((id) => id.trim().isNotEmpty).toSet().toList()
      ..sort();
  }
}

String _readUserName(DocumentSnapshot<Map<String, dynamic>> snapshot) {
  final data = snapshot.data();
  final name =
      data?['displayName'] as String? ??
      data?['name'] as String? ??
      data?['email'] as String? ??
      '';
  return name.trim().isEmpty ? 'Kullanici' : name.trim();
}
