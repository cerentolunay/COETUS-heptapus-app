import '../../domain/models/exchange_session.dart';
import '../../domain/models/match_offer.dart';
import '../../domain/repositories/exchange_repository.dart';

class LocalExchangeRepository implements ExchangeRepository {
  const LocalExchangeRepository();

  @override
  Stream<List<MatchOffer>> streamUserOffers(String userId) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ExchangeSession>> streamUserSessions(String userId) {
    return Stream.value(const []);
  }

  @override
  Future<void> acceptOffer(String matchId, String currentUserId) async {}

  @override
  Future<void> rejectOffer(String matchId, String currentUserId) async {}

  @override
  Future<void> cancelOffer(String matchId, String currentUserId) async {}
}
