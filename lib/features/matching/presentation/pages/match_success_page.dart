import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/widgets/coetus_mascot.dart';

class MatchSuccessPage extends StatelessWidget {
  const MatchSuccessPage({super.key, required this.user});
  final MatchedUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = user.name.trim().isEmpty ? 'Yeni arkadaşın' : user.name;
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
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: CoetusPalette.red,
                                size: 32,
                              ),
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
                  _ExchangeCard(
                    title: 'Sen paylaşacaksın',
                    items: user.learningGoals
                        .map((g) => '${g.emoji} ${g.name}')
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _ExchangeCard(
                    title: '$name paylaşacak',
                    items: user.skills
                        .map((s) => '${s.emoji} ${s.name}')
                        .toList(),
                  ),
                  const SizedBox(height: 26),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/chat'),
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
