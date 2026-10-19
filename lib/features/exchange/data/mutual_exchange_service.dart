import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';
import '../domain/mutual_exchange.dart';

/// Direct transactions remain a fallback beside the server timeout scheduler.
/// Neither path grants automatic endorsements or creates token rewards.
class MutualExchangeService {
  MutualExchangeService({FirebaseFirestore? firestore, String? userId})
    : _db = firestore ?? FirebaseFirestore.instance,
      _uid = userId ?? FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _db;
  final String _uid;

  Future<void> propose({
    required String otherId,
    required String myName,
    required String otherName,
    required SkillModel myTeach,
    required SkillModel myLearn,
    required SkillModel otherTeach,
    required SkillModel otherLearn,
  }) async {
    if (otherId == _uid) throw StateError('Kendinle takas yapamazsın.');
    final match = _db.collection('matches').doc();
    final participants = [_uid, otherId]..sort();
    final deposits = {_uid: otherTeach.level * 10, otherId: myTeach.level * 10};
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    final title = '${myTeach.name} ↔ ${otherTeach.name}';
    batch.set(match, {
      'id': match.id,
      'schemaVersion': 2,
      'participants': participants,
      'initiatorId': _uid,
      'recipientId': otherId,
      'requesterName': myName,
      'receiverName': otherName,
      'skillName': title,
      'credits': deposits[_uid],
      'deposits': deposits,
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(_db.doc('sessions/${match.id}'), {
      'id': match.id,
      'matchId': match.id,
      'schemaVersion': 2,
      'requesterId': _uid,
      'receiverId': otherId,
      'participants': participants,
      'participantNames': {_uid: myName, otherId: otherName},
      'teachSkillIds': {_uid: myTeach.id, otherId: otherTeach.id},
      'learnSkillIds': {_uid: myLearn.id, otherId: otherLearn.id},
      'taughtNames': {_uid: myTeach.name, otherId: otherTeach.name},
      'levels': {_uid: myTeach.level, otherId: otherTeach.level},
      'skill': title,
      'credits': deposits[_uid],
      'deposits': deposits,
      'status': 'requested',
      'funded': false,
      'completionVotes': <String>[],
      'cancellationVotes': <String>[],
      'completionRequestedAt': null,
      'remindedAt': null,
      'disputedBy': null,
      'disputeReason': '',
      'settledAt': null,
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(_db.doc('chats/${match.id}'), {
      'id': match.id,
      'participants': participants,
      'participantNames': {_uid: myName, otherId: otherName},
      'sessionId': match.id,
      'matchId': match.id,
      'skillName': title,
      'credits': deposits[_uid],
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
    });
    _notify(
      batch,
      match.id,
      otherId,
      'offer',
      'Karşılıklı takas teklifi',
      '$title · Senin katkın ${deposits[otherId]}, karşı tarafın katkısı ${deposits[_uid]} token.',
    );
    await batch.commit();
  }

  Future<void> accept(String id) async {
    await _db.runTransaction((tx) async {
      final ref = _db.doc('sessions/$id');
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (data == null || data['schemaVersion'] != 2) {
        throw StateError(
          'Bu teklif eski sürüme ait; yeni karşılıklı teklif oluştur.',
        );
      }
      final state = MutualExchange.fromMap(data);
      if (data['receiverId'] != _uid) {
        throw StateError('Bu teklifi yalnızca alıcısı kabul edebilir.');
      }
      if (state.status == 'active') return;
      if (state.status != 'requested') {
        throw StateError('Teklif artık beklemiyor.');
      }
      final users = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final uid in state.participants) {
        users[uid] = await tx.get(_db.doc('users/$uid'));
      }
      for (final uid in state.participants) {
        final user = users[uid]!, amount = state.deposits[uid]!;
        final available = (user.data()?['credits'] as num? ?? 0).toInt();
        if (available < amount) {
          throw StateError(
            'Katılımcılardan birinin token bakiyesi yetersiz. Hiçbir token kilitlenmedi.',
          );
        }
        tx.update(user.reference, {
          'credits': available - amount,
          'lockedCredits':
              (user.data()?['lockedCredits'] as num? ?? 0).toInt() + amount,
          'lastExchangeSessionId': id,
        });
      }
      final now = FieldValue.serverTimestamp();
      tx.update(ref, {'status': 'active', 'funded': true, 'updatedAt': now});
      tx.update(_db.doc('matches/$id'), {
        'status': 'accepted',
        'updatedAt': now,
      });
      tx.update(_db.doc('chats/$id'), {'status': 'active', 'updatedAt': now});
      _notify(
        tx,
        id,
        state.participants.firstWhere((u) => u != _uid),
        'accepted',
        'Takas kabul edildi',
        'İkinizin de katkısı kilitlendi. İkiniz de hem öğretiyor hem öğreniyorsunuz.',
      );
    });
  }

  Future<void> act(String id, MutualAction action, {String reason = ''}) async {
    await _db.runTransaction((tx) async {
      final ref = _db.doc('sessions/$id');
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (data == null || data['schemaVersion'] != 2) {
        throw StateError('Eski oturum otomatik dönüştürülmedi.');
      }
      final state = MutualExchange.fromMap(data);
      if (!state.participants.contains(_uid)) {
        throw StateError('Bu takasa erişimin yok.');
      }
      if (state.terminal) return;
      if (!['active', 'disputed'].contains(state.status)) {
        throw StateError('Takas henüz etkin değil.');
      }
      final operation =
          (action == MutualAction.complete || action == MutualAction.cancel) &&
              state.dueForExpiry(DateTime.now())
          ? MutualAction.expire
          : action;
      final now = FieldValue.serverTimestamp();
      final patch = <String, dynamic>{'updatedAt': now};
      var terminal = false, event = operation.name;
      switch (operation) {
        case MutualAction.complete:
          if (state.status != 'active' || state.cancellationVotes.isNotEmpty) {
            throw StateError('Önce iptal/itiraz süreci çözülmeli.');
          }
          if (state.completionVotes.contains(_uid)) return;
          final votes = [...state.completionVotes, _uid];
          patch['completionVotes'] = votes;
          if (votes.length == 1) patch['completionRequestedAt'] = now;
          if (votes.length == 2) {
            patch['status'] = 'completed';
            terminal = true;
          }
        case MutualAction.cancel:
          if (state.cancellationVotes.contains(_uid)) return;
          final votes = [...state.cancellationVotes, _uid];
          patch['cancellationVotes'] = votes;
          if (votes.length == 2) {
            patch['status'] = 'cancelled';
            terminal = true;
          } else if (state.completionVotes.isNotEmpty &&
              state.status == 'active') {
            patch.addAll({
              'status': 'disputed',
              'disputedBy': _uid,
              'disputeReason': 'Tamamlanma isteğinden sonra iptal istendi.',
            });
          }
        case MutualAction.dispute:
          if (state.status != 'active' ||
              state.completionVotes.length != 1 ||
              state.completionVotes.contains(_uid)) {
            throw StateError('Bu tamamlanma isteğine itiraz edemezsin.');
          }
          if (reason.trim().length < 10 || reason.trim().length > 500) {
            throw const FormatException('İtirazını 10–500 karakterle açıkla.');
          }
          patch.addAll({
            'status': 'disputed',
            'disputedBy': _uid,
            'disputeReason': reason.trim(),
          });
        case MutualAction.remind:
          if (!state.dueForReminder(DateTime.now())) return;
          patch['remindedAt'] = now;
        case MutualAction.expire:
          if (!state.dueForExpiry(DateTime.now())) return;
          patch['status'] = 'expired';
          terminal = true;
      }
      final users = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      if (terminal) {
        for (final uid in state.participants) {
          users[uid] = await tx.get(_db.doc('users/$uid'));
        }
        for (final uid in state.participants) {
          final user = users[uid]!, amount = state.deposits[uid]!;
          final locked = (user.data()?['lockedCredits'] as num? ?? 0).toInt();
          if (locked < amount) {
            throw StateError('Kilitli bakiye doğrulanamadı.');
          }
          tx.update(user.reference, {
            'credits': (user.data()?['credits'] as num? ?? 0).toInt() + amount,
            'lockedCredits': locked - amount,
            'lastExchangeSessionId': id,
          });
        }
        patch['settledAt'] = now;
        tx.update(_db.doc('chats/$id'), {
          'status': patch['status'],
          'updatedAt': now,
        });
      }
      tx.update(ref, patch);
      if (terminal) {
        for (final uid in state.participants) {
          _notify(
            tx,
            id,
            uid,
            event,
            operation == MutualAction.expire
                ? 'Yanıt süresi doldu'
                : operation == MutualAction.cancel
                ? 'Takas iptal edildi'
                : 'Takas tamamlandı',
            'Kendi kilitlediğin ${state.deposits[uid]} token hesabına iade edildi.${operation == MutualAction.expire ? ' Sessizlik onay veya referans sayılmaz.' : ''}',
          );
        }
      } else {
        final other = operation == MutualAction.remind
            ? state.participants.firstWhere(
                (u) => !state.completionVotes.contains(u),
              )
            : state.participants.firstWhere((u) => u != _uid);
        _notify(
          tx,
          id,
          other,
          event,
          operation == MutualAction.remind
              ? 'Takas yanıtını bekliyor'
              : operation == MutualAction.dispute
              ? 'Takas için itiraz var'
              : operation == MutualAction.cancel
              ? 'İptal isteği'
              : 'Tamamlanma onayın bekleniyor',
          operation == MutualAction.dispute
              ? 'Otomatik iade durduruldu. Karşılıklı iptalle çözebilirsiniz.'
              : 'İlgili takası açıp yanıt verebilirsin. İtiraz yoksa ilk tamamlanma isteğinden 72 saat sonra süre dolar.',
        );
      }
    });
  }

  void _notify(
    dynamic writer,
    String id,
    String recipient,
    String event,
    String title,
    String message,
  ) {
    writer.set(_db.doc('notifications/mutual_${id}_${event}_$recipient'), {
      'userId': recipient,
      'senderId': _uid,
      'type': 'session_started',
      'title': title,
      'message': message,
      'targetRoute': '/exchange-detail',
      'targetId': id,
      'sessionId': id,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
