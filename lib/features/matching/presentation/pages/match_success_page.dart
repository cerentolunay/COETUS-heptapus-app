import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../preview/preview_mode.dart';
import '../../data/first_match_gift.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/widgets/coetus_mascot.dart';

class MatchSuccessPage extends StatefulWidget {
  const MatchSuccessPage({
    super.key,
    required this.user,
    this.claimGift = true,
    this.chatId,
  });
  final bool claimGift;
  final String? chatId;
  final MatchedUser user;

  @override
  State<MatchSuccessPage> createState() => _MatchSuccessPageState();
}

class _MatchSuccessPageState extends State<MatchSuccessPage> {
  bool _gift = false;
  bool _loadingGift = false;
  String? _giftError;
  @override
  void initState() {
    super.initState();
    if (!widget.claimGift) return;
    if (PreviewMode.enabled) {
      return;
    } else {
      _claimGift();
    }
  }

  Future<void> _claimGift() async {
    if (Firebase.apps.isEmpty || _loadingGift) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _loadingGift = true;
      _giftError = null;
    });
    try {
      final granted = await FirstMatchGift.claim(uid);
      if (mounted) setState(() => _gift = granted);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _giftError = 'Hediyen kontrol edilemedi. Yeniden deneyebilirsin.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingGift = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = widget.user.name.trim().isEmpty
        ? 'Yeni arkadaşın'
        : widget.user.name;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: CoetusPalette.purple,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Column(
                      children: [
                        const CoetusMascot(size: 180),
                        Text(
                          'Harika bir eşleşme!',
                          textAlign: TextAlign.center,
                          style: text.headlineMedium?.copyWith(
                            color: CoetusPalette.lime,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$name ile birlikte öğrenmeye hazırsınız.',
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: CoetusPalette.cream,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Expanded(
                              child: _Person(label: 'Sen', initial: 'S'),
                            ),
                            const SizedBox(
                              width: 104,
                              height: 112,
                              child: MatchHeartSparkles(),
                            ),
                            Expanded(
                              child: _Person(
                                label: name,
                                initial: name.characters.first.toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_gift) ...[
                    Container(
                      key: const ValueKey('first-match-gift'),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: CoetusPalette.lime,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.card_giftcard_rounded,
                            color: CoetusPalette.purple,
                            size: 32,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'İlk eşleşmeni kutluyoruz!',
                            style: text.titleLarge?.copyWith(
                              color: CoetusPalette.purple,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'COETUS’tan sana hediye 20 token!',
                            style: TextStyle(
                              color: CoetusPalette.purple,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            PreviewMode.enabled
                                ? 'Önizleme hediyesi · Gerçek bakiyene token eklenmez.'
                                : 'Hediyen hesabına eklendi. Birlikte öğrenmenin ilk adımı bizden!',
                            style: const TextStyle(color: CoetusPalette.purple),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_loadingGift)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('İlk eşleşme hediyen kontrol ediliyor…'),
                    ),
                  if (_giftError != null) ...[
                    Text(_giftError!),
                    TextButton(
                      onPressed: _claimGift,
                      child: const Text('Yeniden dene'),
                    ),
                  ],
                  _ExchangeCard(
                    title: 'Sen paylaşacaksın',
                    items: widget.user.learningGoals
                        .map((g) => '${g.emoji} ${g.name}')
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _ExchangeCard(
                    title: '$name paylaşacak',
                    items: widget.user.skills
                        .map((s) => '${s.emoji} ${s.name}')
                        .toList(),
                  ),
                  const SizedBox(height: 26),
                  ElevatedButton.icon(
                    onPressed: () => context.go(
                      widget.chatId == null
                          ? '/chat'
                          : '/chat-detail/${widget.chatId}',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Sohbete başla'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/matching'),
                    child: const Text('Keşfetmeye devam et'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.label, required this.initial});
  final String label;
  final String initial;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 30,
        backgroundColor: CoetusPalette.lavender,
        child: Text(
          initial,
          style: const TextStyle(
            color: CoetusPalette.purple,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: CoetusPalette.cream,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: CoetusPalette.cream,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            'Yeteneklerinizi sohbette birlikte belirleyin.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((s) => Chip(label: Text(s))).toList(),
          ),
      ],
    ),
  );
}

class MatchedUser {
  final String name;
  final List<MatchedSkill> skills;
  final List<MatchedGoal> learningGoals;
  const MatchedUser({
    required this.name,
    required this.skills,
    required this.learningGoals,
  });
}

class MatchedSkill {
  final String name;
  final String emoji;
  const MatchedSkill({required this.name, required this.emoji});
}

class MatchedGoal {
  final String name;
  final String emoji;
  const MatchedGoal({required this.name, required this.emoji});
}

/// Particles originate at the heart, expand outward and fade with distance.
class MatchHeartSparkles extends StatefulWidget {
  const MatchHeartSparkles({super.key});
  @override
  State<MatchHeartSparkles> createState() => _MatchHeartSparklesState();
}

class _MatchHeartSparklesState extends State<MatchHeartSparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Eşleşme kutlaması',
    image: true,
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final reduced = MediaQuery.disableAnimationsOf(context);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            children: [
              if (!reduced)
                for (var i = 0; i < 14; i++)
                  Builder(
                    builder: (_) {
                      final progress = (_controller.value + i / 14) % 1;
                      final angle = i * 2.39996;
                      final distance = 8 + progress * 42;
                      final size =
                          (i % 3 == 0
                              ? 13.0
                              : i % 3 == 1
                              ? 8.0
                              : 5.0) *
                          (1 - .35 * progress);
                      return Transform.translate(
                        offset: Offset(
                          math.cos(angle) * distance,
                          math.sin(angle) * distance,
                        ),
                        child: Opacity(
                          opacity:
                              math.sin(progress * math.pi) * (1 - progress),
                          child: Icon(
                            i.isEven
                                ? Icons.auto_awesome
                                : Icons.favorite_rounded,
                            size: size,
                            color: CoetusPalette.red,
                          ),
                        ),
                      );
                    },
                  ),
              Transform.scale(
                scale: reduced
                    ? 1
                    : 1 + .09 * math.sin(_controller.value * math.pi * 4),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: CoetusPalette.red,
                  size: 34,
                  shadows: [Shadow(color: Color(0x66FF5577), blurRadius: 18)],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
