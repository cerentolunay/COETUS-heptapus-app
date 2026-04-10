import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MatchingFeedPage extends StatefulWidget {
  const MatchingFeedPage({super.key});

  @override
  State<MatchingFeedPage> createState() => _MatchingFeedPageState();
}

class _MatchingFeedPageState extends State<MatchingFeedPage> {
  final List<_UserMatch> _users = const [
    _UserMatch(
      id: '1',
      name: 'Sarah Martinez',
      location: 'Barcelona, Spain',
      trustScore: 96,
      bio:
          'Native Spanish speaker and certified language teacher. I love helping people learn through conversation and cultural immersion.',
      canTeach: [
        _TeachSkill(name: 'Spanish', level: 7, emoji: '🇪🇸'),
        _TeachSkill(name: 'Guitar', level: 5, emoji: '🎸'),
      ],
      wantToLearn: [
        _LearnGoal(name: 'English', emoji: '🇬🇧'),
        _LearnGoal(name: 'Coding', emoji: '💻'),
      ],
      personalityTraits: [
        'Patient Teacher',
        'Cultural Explorer',
        'Music Lover',
      ],
      matchPercentage: 94,
      creditsRequired: 50,
      totalSwaps: 32,
    ),
    _UserMatch(
      id: '2',
      name: 'David Kim',
      location: 'Seoul, South Korea',
      trustScore: 98,
      bio:
          'Senior software engineer at a tech startup. Passionate about teaching web development and learning new languages.',
      canTeach: [
        _TeachSkill(name: 'Coding', level: 7, emoji: '💻'),
        _TeachSkill(name: 'English', level: 6, emoji: '🇬🇧'),
      ],
      wantToLearn: [
        _LearnGoal(name: 'Spanish', emoji: '🇪🇸'),
        _LearnGoal(name: 'Guitar', emoji: '🎸'),
      ],
      personalityTraits: [
        'Tech Enthusiast',
        'Structured Learner',
        'Goal-Oriented',
      ],
      matchPercentage: 91,
      creditsRequired: 50,
      totalSwaps: 45,
    ),
    _UserMatch(
      id: '3',
      name: 'Emily Chen',
      location: 'London, UK',
      trustScore: 95,
      bio:
          'Professional guitarist and music producer. Teaching guitar for 8+ years. Want to improve my Spanish conversation.',
      canTeach: [
        _TeachSkill(name: 'Guitar', level: 7, emoji: '🎸'),
        _TeachSkill(name: 'English', level: 7, emoji: '🇬🇧'),
      ],
      wantToLearn: [
        _LearnGoal(name: 'Spanish', emoji: '🇪🇸'),
        _LearnGoal(name: 'Design', emoji: '🎨'),
      ],
      personalityTraits: [
        'Creative Artist',
        'Patient Mentor',
        'Detail-Oriented',
      ],
      matchPercentage: 89,
      creditsRequired: 50,
      totalSwaps: 28,
    ),
  ];

  int _currentIndex = 0;
  int _swipeDirection = 0; // -1 left, 1 right, 0 idle

  static const Color _bgTop = Color(0xFF0B1120);
  static const Color _bgMid = Color(0xFF0F172A);
  static const Color _bgBottom = Color(0xFF1E1B4B);

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _violetSoft = Color(0xFFA78BFA);
  static const Color _green = Color(0xFF4ADE80);

  static const Color _surface = Color(0x14FFFFFF);
  static const Color _surfaceBorder = Color(0x1AFFFFFF);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _textSoft = Color(0xFFCBD5E1);
  static const Color _textDarkMuted = Color(0xFF64748B);

  void _handleSwipe(String direction) {
    if (_currentIndex >= _users.length) return;

    setState(() {
      _swipeDirection = direction == 'right' ? 1 : -1;
    });

    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() {
        _currentIndex += 1;
        _swipeDirection = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinished = _currentIndex >= _users.length;
    final _UserMatch? currentUser = isFinished ? null : _users[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgMid, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: isFinished
              ? _buildFinishedState(context)
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Stack(
                          children: [
                            AnimatedSlide(
                              duration: const Duration(milliseconds: 260),
                              offset: Offset(
                                _swipeDirection == 0
                                    ? 0
                                    : (_swipeDirection == 1 ? 1.2 : -1.2),
                                0,
                              ),
                              child: AnimatedRotation(
                                duration: const Duration(milliseconds: 260),
                                turns: _swipeDirection == 0
                                    ? 0
                                    : (_swipeDirection == 1 ? 0.04 : -0.04),
                                child: _MatchCard(user: currentUser!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildActionButtons(context, currentUser),
                    _buildBottomNav(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFinishedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_violet, _cyan]),
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Caught Up!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back soon for more skill-swap opportunities',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_violet, _cyan]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () {
                  context.go('/profile-advanced');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back to Profile',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final remaining = _users.length - _currentIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Discover Matches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$remaining profiles available',
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Icon(
              Icons.my_location_outlined,
              color: _cyan,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, _UserMatch user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                size: 64,
                borderColor: Colors.white.withOpacity(0.10),
                icon: Icons.close,
                iconColor: Colors.redAccent,
                onTap: () => _handleSwipe('left'),
              ),
              const SizedBox(width: 24),
              _GradientActionButton(
                size: 80,
                icon: Icons.favorite,
                onTap: () {
                  context.go('/match-success');
                },
              ),
              const SizedBox(width: 24),
              _ActionButton(
                size: 64,
                borderColor: _cyan.withOpacity(0.35),
                icon: Icons.auto_awesome,
                iconColor: _cyan,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Swipe requires ${user.creditsRequired} HC commitment',
            style: const TextStyle(
              color: _textDarkMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgMid.withOpacity(0.86),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () => context.go('/profile-advanced'),
          ),
          _BottomNavItem(
            icon: Icons.trending_up,
            label: 'Discover',
            isActive: true,
            onTap: () {},
          ),
          _BottomNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chats',
            showDot: true,
            onTap: () => context.go('/chat'),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final _UserMatch user;

  const _MatchCard({required this.user});

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _violetSoft = Color(0xFFA78BFA);
  static const Color _green = Color(0xFF4ADE80);

  static const Color _surface = Color(0x14FFFFFF);
  static const Color _surfaceBorder = Color(0x1AFFFFFF);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _textSoft = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _surfaceBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopSection(),
                    const SizedBox(height: 22),
                    _buildTeachSection(),
                    const SizedBox(height: 22),
                    _buildLearnSection(),
                    const SizedBox(height: 22),
                    _buildTraitsSection(),
                  ],
                ),
              ),
            ),
            _buildSessionCost(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _cyan,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📍 ${user.location}',
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _violet.withOpacity(0.20),
                              _cyan.withOpacity(0.20),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _violet.withOpacity(0.30)),
                        ),
                        child: Text(
                          '${user.matchPercentage}% Match',
                          style: const TextStyle(
                            color: _violetSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _green.withOpacity(0.30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 12, color: _green),
                            const SizedBox(width: 4),
                            Text(
                              '${user.trustScore}% Trust',
                              style: const TextStyle(
                                color: _green,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _cyan.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _cyan.withOpacity(0.30)),
                        ),
                        child: Text(
                          '${user.totalSwaps} Swaps',
                          style: const TextStyle(
                            color: _cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.bio,
          style: const TextStyle(
            color: _textSoft,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildTeachSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.trending_up, color: _cyan, size: 16),
            SizedBox(width: 8),
            Text(
              'CAN TEACH YOU',
              style: TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: user.canTeach
              .map((skill) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TeachSkillCard(skill: skill),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLearnSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.gps_fixed, color: _violet, size: 16),
            SizedBox(width: 8),
            Text(
              'WANTS TO LEARN',
              style: TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: user.wantToLearn.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final goal = user.wantToLearn[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 8),
                  Text(
                    goal.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildTraitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: _cyan, size: 16),
            SizedBox(width: 8),
            Text(
              'SHARED TRAITS',
              style: TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: user.personalityTraits
              .map(
                (trait) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Text(
                    trait,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSessionCost() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _violet.withOpacity(0.20),
              _cyan.withOpacity(0.20),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _violet.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: _cyan, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Session Cost',
                style: TextStyle(
                  color: _textSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${user.creditsRequired} HC',
              style: const TextStyle(
                color: _cyan,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeachSkillCard extends StatelessWidget {
  final _TeachSkill skill;

  const _TeachSkillCard({required this.skill});

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(skill.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Expert Level',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _cyan]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${skill.level}/7',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                        ? const LinearGradient(colors: [_violet, _cyan])
                        : null,
                    color: active ? null : Colors.white.withOpacity(0.10),
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

class _ActionButton extends StatelessWidget {
  final double size;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.size,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientActionButton({
    required this.size,
    required this.icon,
    required this.onTap,
  });

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_violet, _cyan]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _violet.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool showDot;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.showDot = false,
  });

  static const Color _active = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _active : Colors.white.withOpacity(0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (showDot)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _active,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMatch {
  final String id;
  final String name;
  final String location;
  final int trustScore;
  final String bio;
  final List<_TeachSkill> canTeach;
  final List<_LearnGoal> wantToLearn;
  final List<String> personalityTraits;
  final int matchPercentage;
  final int creditsRequired;
  final int totalSwaps;

  const _UserMatch({
    required this.id,
    required this.name,
    required this.location,
    required this.trustScore,
    required this.bio,
    required this.canTeach,
    required this.wantToLearn,
    required this.personalityTraits,
    required this.matchPercentage,
    required this.creditsRequired,
    required this.totalSwaps,
  });
}

class _TeachSkill {
  final String name;
  final int level;
  final String emoji;

  const _TeachSkill({
    required this.name,
    required this.level,
    required this.emoji,
  });
}

class _LearnGoal {
  final String name;
  final String emoji;

  const _LearnGoal({
    required this.name,
    required this.emoji,
  });
}