import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SkillProfilePage extends StatefulWidget {
  const SkillProfilePage({super.key});

  @override
  State<SkillProfilePage> createState() => _SkillProfilePageState();
}

class _SkillProfilePageState extends State<SkillProfilePage> {
  final List<_Skill> _skills = const [
    _Skill(id: '1', name: 'Guitar', level: 6, emoji: '🎸'),
    _Skill(id: '2', name: 'English', level: 2, emoji: '🇬🇧'),
    _Skill(id: '3', name: 'Cooking', level: 5, emoji: '👨‍🍳'),
    _Skill(id: '4', name: 'Photography', level: 4, emoji: '📷'),
  ];

  final List<_Goal> _learningGoals = const [
    _Goal(id: '1', name: 'Spanish', emoji: '🇪🇸'),
    _Goal(id: '2', name: 'Yoga', emoji: '🧘'),
    _Goal(id: '3', name: 'Piano', emoji: '🎹'),
  ];

  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _card = Color(0xFF1A1A2E);
  static const Color _card2 = Color(0xFF16162A);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _indigoText = Color(0xFF818CF8);
  static const Color _violetText = Color(0xFFC4B5FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildProfileCard(),
                    const SizedBox(height: 28),
                    _buildSkillsSection(),
                    const SizedBox(height: 28),
                    _buildLearningGoalsSection(),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Your Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_indigo, _violet],
            ),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_indigo, _violet],
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alex Chen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'San Francisco, CA',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      text: '4 skills',
                      background: _indigo.withOpacity(0.20),
                      textColor: _indigoText,
                    ),
                    _InfoChip(
                      text: '12 matches',
                      background: _violet.withOpacity(0.20),
                      textColor: _violetText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Skills',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: _indigoText, size: 18),
              label: const Text(
                'Add Skill',
                style: TextStyle(
                  color: _indigoText,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: _skills.map((skill) => _SkillCard(skill: skill)).toList(),
        ),
      ],
    );
  }

  Widget _buildLearningGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Want to Learn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: _indigoText, size: 18),
              label: const Text(
                'Add Goal',
                style: TextStyle(
                  color: _indigoText,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: _learningGoals.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final goal = _learningGoals[index];
            return Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 10),
                  Text(
                    goal.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _card2,
        border: Border(
          top: BorderSide(color: _border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: true,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            label: 'Discover',
            onTap: () {
              context.go('/matching');
            },
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chats',
            onTap: () {
              context.go('/chat');
            },
          ),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final _Skill skill;

  const _SkillCard({required this.skill});

  static const Color _bg = Color(0xFF1A1A2E);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _track = Color(0xFF0A0A0F);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _indigoText = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final widthFactor = skill.level / 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(skill.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skill.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${skill.level}/7',
                style: const TextStyle(
                  color: _indigoText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: _track),
                  FractionallySizedBox(
                    widthFactor: widthFactor,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_indigo, _violet],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (index) {
              final active = index < skill.level;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == 6 ? 0 : 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: active
                        ? const LinearGradient(colors: [_indigo, _violet])
                        : null,
                    color: active ? null : _border,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color textColor;

  const _InfoChip({
    required this.text,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  static const Color _active = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _active : Colors.white.withOpacity(0.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skill {
  final String id;
  final String name;
  final int level;
  final String emoji;

  const _Skill({
    required this.id,
    required this.name,
    required this.level,
    required this.emoji,
  });
}

class _Goal {
  final String id;
  final String name;
  final String emoji;

  const _Goal({
    required this.id,
    required this.name,
    required this.emoji,
  });
}