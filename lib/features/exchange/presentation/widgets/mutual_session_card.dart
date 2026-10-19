import 'package:flutter/material.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import '../../domain/models/exchange_session.dart';
import '../../domain/mutual_exchange.dart';

class MutualSessionCard extends StatelessWidget {
  const MutualSessionCard({
    super.key,
    required this.session,
    required this.userId,
    required this.onAction,
    this.busy = false,
    this.onChat,
    this.onDetails,
  });
  final ExchangeSession session;
  final String userId;
  final bool busy;
  final ValueChanged<MutualAction> onAction;
  final VoidCallback? onChat, onDetails;
  @override
  Widget build(BuildContext context) {
    final state = session.mutual!;
    final other = state.participants.firstWhere(
      (id) => id != userId,
      orElse: () => '',
    );
    final expired = state.dueForExpiry(DateTime.now());
    final deadline = state.completionRequestedAt
        ?.add(MutualExchange.responseWindow)
        .toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    final label = switch (state.status) {
      'completed' => 'Karşılıklı tamamlandı',
      'cancelled' => 'Karşılıklı iptal edildi',
      'expired' => 'Yanıt süresi doldu',
      'disputed' => 'İtiraz / iptal görüşmesi',
      'requested' => 'Teklif bekliyor',
      _ => 'Karşılıklı takas',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(session.skill, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CoetusPalette.purple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İkiniz de öğretiyor ve öğreniyorsunuz.\nSenin katkın: ${state.deposits[userId] ?? 0} token\nKarşı tarafın katkısı: ${state.deposits[other] ?? 0} token',
            ),
            if (state.terminal) ...[
              const SizedBox(height: 8),
              Text(
                session.funded
                    ? 'Herkes kendi kilitlediği tokenı geri aldı.'
                    : 'Bu teklifte token kilitlenmedi.',
              ),
              if (state.status == 'expired')
                const Text(
                  'Yanıt verilmemesi tamamlanma veya beceri onayı sayılmaz.',
                ),
            ] else if (state.status == 'disputed') ...[
              const SizedBox(height: 8),
              const Text(
                'Otomatik kapanma durdu. Karşılıklı iptalle tokenlarınızı geri alabilirsiniz.',
              ),
            ] else if (state.completionVotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                state.completionVotes.contains(userId)
                    ? 'Tamamlanma onayın kaydedildi; karşı taraf bekleniyor.'
                    : 'Karşı tarafın tamamlanma onayı var. Yanıtın bekleniyor.',
              ),
              const Text(
                'İlk onaydan 24 saat sonra hatırlatma, 72 saat içinde itiraz yoksa süre sonunda iade. Süre kontrolleri Takaslarım açıkken veya yeniden açıldığında yapılır.',
              ),
              if (deadline != null)
                Text(
                  'Son yanıt: ${two(deadline.day)}.${two(deadline.month)}.${deadline.year} ${two(deadline.hour)}:${two(deadline.minute)}',
                ),
              if (state.remindedAt != null)
                const Text('Hatırlatma kaydedildi.'),
            ],
            if (state.status == 'disputed' && state.disputeReason.isNotEmpty)
              Text(state.disputeReason),
            if (!state.terminal &&
                ['active', 'disputed'].contains(state.status)) ...[
              const SizedBox(height: 12),
              if (state.status == 'active')
                FilledButton(
                  onPressed:
                      busy ||
                          expired ||
                          state.completionVotes.contains(userId) ||
                          state.cancellationVotes.isNotEmpty
                      ? null
                      : () => onAction(MutualAction.complete),
                  child: const Text('Tamamladık'),
                ),
              if (state.status == 'active' &&
                  state.completionVotes.length == 1 &&
                  !state.completionVotes.contains(userId) &&
                  !expired)
                OutlinedButton(
                  onPressed: busy ? null : () => onAction(MutualAction.dispute),
                  child: const Text('Takas tamamlanmadı · İtiraz et'),
                ),
              OutlinedButton(
                onPressed:
                    busy || expired || state.cancellationVotes.contains(userId)
                    ? null
                    : () => onAction(MutualAction.cancel),
                child: Text(
                  state.cancellationVotes.contains(userId)
                      ? 'İptal onayın kaydedildi'
                      : state.cancellationVotes.isEmpty
                      ? 'İptal / iade iste'
                      : 'İptali onayla',
                ),
              ),
              if (expired)
                FilledButton(
                  onPressed: busy ? null : () => onAction(MutualAction.expire),
                  child: const Text('Süreyi kontrol et ve iadeyi sonuçlandır'),
                ),
            ],
            if (busy) const LinearProgressIndicator(),
            Wrap(
              spacing: 8,
              children: [
                if (onChat != null)
                  TextButton(onPressed: onChat, child: const Text('Sohbet')),
                if (onDetails != null)
                  TextButton(onPressed: onDetails, child: const Text('Detay')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
