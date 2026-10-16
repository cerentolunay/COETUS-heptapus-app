import 'package:cloud_functions/cloud_functions.dart';
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
        .asyncMap((snapshot) async {
          final offers = snapshot.docs.map(MatchOffer.fromFirestore).toList();
          final enrichedOffers = await _enrichMissingOfferNames(offers);
          enrichedOffers.sort((a, b) {
            final aDate = a.createdAt ?? a.updatedAt ?? DateTime(0);
            final bDate = b.createdAt ?? b.updatedAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          return enrichedOffers;
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
    await FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).httpsCallable('acceptLearningOffer').call({'matchId': matchId});
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

  Future<List<MatchOffer>> _enrichMissingOfferNames(
    List<MatchOffer> offers,
  ) async {
    final missingUserIds = offers
        .expand((offer) => [offer.requesterId, offer.receiverId])
        .where((userId) => userId.trim().isNotEmpty)
        .where(
          (userId) => offers.any(
            (offer) =>
                (offer.requesterId == userId &&
                    offer.requesterName.trim().isEmpty) ||
                (offer.receiverId == userId &&
                    offer.receiverName.trim().isEmpty),
          ),
        )
        .toSet();

    if (missingUserIds.isEmpty) return offers;

    final fetchedNames = <String, String>{};
    for (final userId in missingUserIds) {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      final name = _readUserName(snapshot);
      if (name.trim().isNotEmpty) fetchedNames[userId] = name;
    }

    return offers.map((offer) {
      return offer.copyWith(
        requesterName: offer.requesterName.trim().isNotEmpty
            ? offer.requesterName
            : fetchedNames[offer.requesterId],
        receiverName: offer.receiverName.trim().isNotEmpty
            ? offer.receiverName
            : fetchedNames[offer.receiverId],
      );
    }).toList();
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
