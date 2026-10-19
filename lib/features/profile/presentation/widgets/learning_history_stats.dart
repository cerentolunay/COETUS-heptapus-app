import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/coetus_tokens.dart';
import '../../../exchange/data/repositories/exchange_repository_factory.dart';
import '../../../exchange/domain/models/exchange_session.dart';
import '../../../exchange/domain/repositories/exchange_repository.dart';
import '../../domain/learning_history.dart';

/// Both counters and the open history share one session listener.
class LearningHistoryStats extends StatefulWidget {
  const LearningHistoryStats({
    super.key,
    required this.userId,
    required this.onOpenSession,
    this.repository,
  });
  final String userId;
  final ValueChanged<String> onOpenSession;
  final ExchangeRepository? repository;
  @override
  State<LearningHistoryStats> createState() => _LearningHistoryStatsState();
}

class _LearningHistoryStatsState extends State<LearningHistoryStats> {
  final _snapshot = ValueNotifier(
    const AsyncSnapshot<List<ExchangeSession>>.waiting(),
  );
  StreamSubscription<List<ExchangeSession>>? _subscription;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(LearningHistoryStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.repository != widget.repository) {
      _listen();
    }
  }

  void _listen() {
    _subscription?.cancel();
    _snapshot.value = const AsyncSnapshot.waiting();
    try {
      _subscription = (widget.repository ?? ExchangeRepositoryFactory.create())
          .streamUserSessions(widget.userId)
          .listen(
            (data) => _snapshot.value = AsyncSnapshot.withData(
              ConnectionState.active,
              data,
            ),
            onError: (Object error, StackTrace stack) => _snapshot.value =
                AsyncSnapshot.withError(ConnectionState.active, error, stack),
          );
    } catch (error, stack) {
      _snapshot.value = AsyncSnapshot.withError(
        ConnectionState.done,
        error,
        stack,
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _snapshot.dispose();
    super.dispose();
  }

  void _open(LearningHistoryRole role) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: CoetusPalette.cream,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .85,
        child: ValueListenableBuilder(
          valueListenable: _snapshot,
          builder: (_, snapshot, _) => _HistoryList(
            role: role,
            snapshot: snapshot,
            userId: widget.userId,
            onRetry: _listen,
            onOpen: (id) {
              Navigator.pop(sheetContext);
              widget.onOpenSession(id);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _snapshot,
    builder: (_, snapshot, _) => Row(
      children: [
        for (final role in LearningHistoryRole.values) ...[
          if (role == LearningHistoryRole.learned)
            Container(
              width: 1,
              height: 26,
              color: Colors.white.withValues(alpha: .15),
            ),
          Expanded(child: _counter(role, snapshot)),
        ],
      ],
    ),
  );

  Widget _counter(
    LearningHistoryRole role,
    AsyncSnapshot<List<ExchangeSession>> snapshot,
  ) {
    final label = role == LearningHistoryRole.taught ? 'ÖĞRETTİM' : 'ÖĞRENDİM';
    final count = snapshot.hasError
        ? '—'
        : !snapshot.hasData
        ? '…'
        : '${completedLearningHistory(snapshot.data!, widget.userId, role).length}';
    final theme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$label: $count. Tamamlanan oturumları görüntüle',
      child: InkWell(
        onTap: () => _open(role),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                count,
                style: theme.titleLarge?.copyWith(color: CoetusColors.oat),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.labelSmall?.copyWith(
                  color: CoetusColors.oat.withValues(alpha: .65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.role,
    required this.snapshot,
    required this.userId,
    required this.onRetry,
    required this.onOpen,
  });
  final LearningHistoryRole role;
  final AsyncSnapshot<List<ExchangeSession>> snapshot;
  final String userId;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final taught = role == LearningHistoryRole.taught;
    final items = completedLearningHistory(snapshot.data ?? [], userId, role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  taught ? 'Öğrettiklerim' : 'Öğrendiklerim',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Kapat',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Tamamlanan oturumlar · En yeniden en eskiye'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: snapshot.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Geçmiş yüklenemedi. Bağlantını veya hesap erişimini kontrol edip yeniden dene.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: onRetry,
                          child: const Text('Yeniden dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      taught
                          ? 'Henüz tamamladığın bir öğretme oturumu yok.'
                          : 'Henüz tamamladığın bir öğrenme oturumu yok.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final session = items[index],
                        date = sessionHistoryDate(items[index]);
                    final localizations = MaterialLocalizations.of(context);
                    final localDate = date?.toLocal();
                    final dateLabel = localDate == null
                        ? 'Tarih bilgisi yok'
                        : '${localizations.formatMediumDate(localDate)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localDate), alwaysUse24HourFormat: true)}';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          taught
                              ? Icons.school_outlined
                              : Icons.menu_book_outlined,
                          color: CoetusPalette.purple,
                        ),
                        title: Text(
                          session.skill.trim().isEmpty
                              ? 'Öğrenme oturumu'
                              : session.skill,
                        ),
                        subtitle: Text(
                          '$dateLabel\nTamamlandı · ${session.credits} token',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onOpen(session.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
