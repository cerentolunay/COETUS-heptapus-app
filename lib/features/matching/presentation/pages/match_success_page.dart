import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MatchSuccessPage extends StatelessWidget {
  final MatchedUser user;

  const MatchSuccessPage({super.key, required this.user});

  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _card = Color(0xFF1A1A2E);
  static const Color _card2 = Color(0xFF16162A);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _indigoText = Color(0xFF818CF8);
  static const Color _violetText = Color(0xFFC4B5FD);
  static const Color _gray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.split(' ').first;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  _buildSuccessIcon(),
                  const SizedBox(height: 28),
                  _buildTitle(),
                  const SizedBox(height: 28),
                  _buildMatchDetailsCard(firstName),
                  const SizedBox(height: 24),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final item in _particleOffsets)
          Transform.translate(
            offset: item,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _indigoText,
                shape: BoxShape.circle,
              ),
            ),
          ),
        Container(
          width: 128,
          height: 128,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_indigo, _violet]),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 54),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [_indigoText, _violetText],
            ).createShader(bounds);
          },
          child: const Text(
            "It's a Match!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You and ${user.name} can now start swapping skills',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _gray, fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildMatchDetailsCard(String firstName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_card, _card2],
        ),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildUsersVisual(firstName),
          const SizedBox(height: 24),
          _buildExchangeCard(
            title: "You'll teach",
            items: user.learningGoals
                .map(
                  (goal) => _ExchangeItem(name: goal.name, emoji: goal.emoji),
                )
                .toList(),
            startColor: _indigo,
            endColor: _violet,
            borderColor: _indigo.withOpacity(0.30),
          ),
          const SizedBox(height: 14),
          _buildExchangeCard(
            title: '$firstName will teach',
            items: user.skills
                .take(2)
                .map(
                  (skill) =>
                      _ExchangeItem(name: skill.name, emoji: skill.emoji),
                )
                .toList(),
            startColor: _violet,
            endColor: _indigo,
            borderColor: _violet.withOpacity(0.30),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersVisual(String firstName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _UserMiniProfile(
          label: 'You',
          gradient: const LinearGradient(colors: [_indigo, _violet]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('❤️', style: TextStyle(fontSize: 26)),
        ),
        _UserMiniProfile(
          label: firstName,
          gradient: const LinearGradient(colors: [_violet, _indigo]),
        ),
      ],
    );
  }

  Widget _buildExchangeCard({
    required String title,
    required List<_ExchangeItem> items,
    required Color startColor,
    required Color endColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _gray,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          startColor.withOpacity(0.20),
                          endColor.withOpacity(0.20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.emoji),
                        const SizedBox(width: 6),
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_indigo, _violet]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _indigo.withOpacity(0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              context.go('/chat');
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: const Text(
              'Send Message',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              context.go('/matching');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: _border),
              backgroundColor: _card,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Keep Discovering',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserMiniProfile extends StatelessWidget {
  final String label;
  final Gradient gradient;

  const _UserMiniProfile({required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
          child: const Icon(Icons.person, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
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

class _ExchangeItem {
  final String name;
  final String emoji;

  const _ExchangeItem({required this.name, required this.emoji});
}

const List<Offset> _particleOffsets = [
  Offset(0, -74),
  Offset(52, -52),
  Offset(74, 0),
  Offset(52, 52),
  Offset(0, 74),
  Offset(-52, 52),
  Offset(-74, 0),
  Offset(-52, -52),
];
