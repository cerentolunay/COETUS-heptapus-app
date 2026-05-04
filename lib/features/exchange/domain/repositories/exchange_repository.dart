import '../models/exchange_session.dart';
import '../models/match_offer.dart';

abstract class ExchangeRepository {
  Stream<List<MatchOffer>> streamUserOffers(String userId);
  Stream<List<ExchangeSession>> streamUserSessions(String userId);
  Future<void> acceptOffer(String matchId, String currentUserId);
  Future<void> rejectOffer(String matchId, String currentUserId);
  Future<void> cancelOffer(String matchId, String currentUserId);
}
