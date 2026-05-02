import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdvancedSkillProfilePage extends StatelessWidget {
  const AdvancedSkillProfilePage({super.key});

  static const Color _bgStart = Color(0xFF0B1120);
  static const Color _bgMiddle = Color(0xFF0F172A);
  static const Color _bgEnd = Color(0xFF1E1B4B);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final radarData = const [
      _RadarItem(skill: "Guitar", level: 6),
      _RadarItem(skill: "English", level: 5),
      _RadarItem(skill: "Coding", level: 6),
      _RadarItem(skill: "Design", level: 4),
      _RadarItem(skill: "Spanish", level: 2),
      _RadarItem(skill: "Marketing", level: 3),
      _RadarItem(skill: "Teaching", level: 5),
    ];

    final verifications = const [
      _VerificationItem(
        skill: "Guitar",
        verifier: "Maria Chen",
        rating: 6,
        comment: "Excellent fingerstyle technique and music theory knowledge",
        hasVideo: true,
        date: "Feb 15, 2026",
      ),
      _VerificationItem(
        skill: "Coding",
        verifier: "James Wilson",
        rating: 6,
        comment: "Strong full-stack development skills, particularly in React",
        hasVideo: true,
        date: "Feb 10, 2026",
      ),
      _VerificationItem(
        skill: "English",
        verifier: "Sophie Martinez",
        rating: 5,
        comment: "Clear communication and professional writing ability",
        hasVideo: false,
        date: "Feb 5, 2026",
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgStart, _bgMiddle, _bgEnd],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AdvancedProfileHeader(),
                    const SizedBox(height: 20),
                    const _CreditsCard(),
                    const SizedBox(height: 20),
                    const _UserInfoCard(),
                    const SizedBox(height: 24),
                    const _SectionTitle(
                      icon: Icons.trending_up,
                      title: 'Skill Radar',
                      color: _cyan,
                    ),
                    const SizedBox(height: 12),
                    _SkillRadarSummaryCard(items: radarData),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionTitle(
                          icon: Icons.workspace_premium,
                          title: 'Verified Skills',
                          color: _purple,
                        ),
                        Text(
                          '${verifications.length} verified',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...verifications.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VerificationCard(item: v),
                        )),
                  ],
                ),
              ),
              _BottomProfileNav(
                onDiscoverTap: () => context.go('/matching'),
                onChatTap: () => context.go('/chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedProfileHeader extends StatelessWidget {
  const _AdvancedProfileHeader();

  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1A7C3AED),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Professional Skill Ecosystem',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CreditsCard extends StatelessWidget {
  const _CreditsCard();

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purple, _cyan],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(124, 58, 237, 0.20),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monetization_on_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heptapus Credits',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '450 HC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Top Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.20),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available for swaps',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              Text(
                '~9 sessions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard();

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [_purple, _cyan],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'AJ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _cyan,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF0F172A),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Alex Johnson',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: _cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'San Francisco, CA',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniChip(
                          text: '7 Skills',
                          bg: const Color(0x3306B6D4),
                          fg: _cyan,
                          border: const Color(0x4D06B6D4),
                        ),
                        _MiniChip(
                          text: '98% Trust Score',
                          bg: const Color(0x337C3AED),
                          fg: const Color(0xFFA78BFA),
                          border: const Color(0x4D7C3AED),
                        ),
                        _MiniChip(
                          text: '24 Swaps',
                          bg: const Color(0x3300C853),
                          fg: Color(0xFF4ADE80),
                          border: const Color(0x4D22C55E),
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
            'Full-stack developer and musician passionate about knowledge sharing. Specialized in React, Node.js, and fingerstyle guitar. Looking to improve Spanish conversation skills.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SkillRadarSummaryCard extends StatelessWidget {
  final List<_RadarItem> items;

  const _SkillRadarSummaryCard({required this.items});

  static const Color _cyan = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.radar,
                  color: _cyan,
                  size: 42,
                ),
                const SizedBox(height: 10),
                Text(
                  'Radar chart placeholder',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'İstersen bir sonraki adımda gerçek radar chart için chart paketi bağlarız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.skill,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x3306B6D4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${item.level}/7',
                        style: const TextStyle(
                          color: _cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final _VerificationItem item;

  const _VerificationCard({required this.item});

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [_purple, _cyan],
                  ),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.skill,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x3306B6D4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${item.rating}/7',
                            style: const TextStyle(
                              color: _cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified by ${item.verifier}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.hasVideo)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0x337C3AED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0x4D7C3AED),
                    ),
                  ),
                  child: const Icon(
                    Icons.videocam_outlined,
                    color: Color(0xFFA78BFA),
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.comment,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.date,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: const [
                  Text(
                    'View Proof',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: _cyan,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomProfileNav extends StatelessWidget {
  final VoidCallback onDiscoverTap;
  final VoidCallback onChatTap;

  const _BottomProfileNav({
    required this.onDiscoverTap,
    required this.onChatTap,
  });

  static const Color _navBg = Color(0xCC0F172A);
  static const Color _cyan = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        decoration: BoxDecoration(
          color: _navBg,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const _BottomNavItem(
              label: 'Profile',
              icon: Icons.person_outline,
              isActive: true,
            ),
            _BottomNavItem(
              label: 'Discover',
              icon: Icons.trending_up,
              onTap: onDiscoverTap,
            ),
            _BottomNavItem(
              label: 'Chats',
              icon: Icons.chat_bubble_outline,
              onTap: onChatTap,
              showDot: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool showDot;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    this.isActive = false,
    this.showDot = false,
    this.onTap,
  });

  static const Color _cyan = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _cyan : Colors.white.withValues(alpha: 0.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 22),
                if (showDot)
                  const Positioned(
                    right: -1,
                    top: -1,
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _cyan,
                          shape: BoxShape.circle,
                        ),
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

class _MiniChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final Color border;

  const _MiniChip({
    required this.text,
    required this.bg,
    required this.fg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RadarItem {
  final String skill;
  final int level;

  const _RadarItem({
    required this.skill,
    required this.level,
  });
}

class _VerificationItem {
  final String skill;
  final String verifier;
  final int rating;
  final String comment;
  final bool hasVideo;
  final String date;

  const _VerificationItem({
    required this.skill,
    required this.verifier,
    required this.rating,
    required this.comment,
    required this.hasVideo,
    required this.date,
  });
}