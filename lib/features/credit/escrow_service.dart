import 'package:coetus/features/credit/escrow_record.dart';
import 'package:coetus/features/credit/escrow_status.dart';

class EscrowService {
  const EscrowService();

  EscrowRecord lockCredits(EscrowRecord escrow) {
    _ensureStatus(escrow, EscrowStatus.pending);
    return escrow.copyWith(status: EscrowStatus.locked);
  }

  EscrowRecord completeSession(EscrowRecord escrow) {
    _ensureStatus(escrow, EscrowStatus.locked);
    return escrow.copyWith(status: EscrowStatus.completed);
  }

  EscrowRecord refundCredits(EscrowRecord escrow) {
    _ensureStatus(escrow, EscrowStatus.locked);
    return escrow.copyWith(status: EscrowStatus.refunded);
  }

  EscrowRecord cancelBeforeLock(EscrowRecord escrow) {
    _ensureStatus(escrow, EscrowStatus.pending);
    return escrow.copyWith(status: EscrowStatus.cancelled);
  }

  void _ensureStatus(EscrowRecord escrow, EscrowStatus expectedStatus) {
    if (escrow.status != expectedStatus) {
      throw StateError(
        'Escrow ${escrow.id} must be ${expectedStatus.name}, '
        'but was ${escrow.status.name}.',
      );
    }
  }
}
