import 'package:flutter/material.dart';

class OtherUserProfilePage extends StatelessWidget {
  final OtherUserProfileData profile;

  const OtherUserProfilePage({super.key, required this.profile});

  static const Color _bgTop = Color(0xFF0B1120);
  static const Color _bgMid = Color(0xFF0F172A);
  static const Color _bgBottom = Color(0xFF1E1B4B);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _green = Color(0xFF4ADE80);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _textSoft = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                sliver: SliverList.list(
                  children: [
                    _buildHero(),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Bio',
                      icon: Icons.notes_outlined,
                      child: Text(
                        profile.bio.trim().isEmpty
                            ? 'Bu kullanici henuz bio eklememis.'
                            : profile.bio,
                        style: const TextStyle(
                          color: _textSoft,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Ogretir',
                      icon: Icons.school_outlined,
                      child: _SkillWrap(
                        skills: profile.teachSkills,
                        emptyText: 'Henuz ogretecegi skill eklememis.',
                        accent: _cyan,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Ogrenmek istiyor',
                      icon: Icons.gps_fixed,
                      child: _SkillWrap(
                        skills: profile.learnSkills,
                        emptyText: 'Henuz ogrenmek istedigi skill yok.',
                        accent: _violet,
                      ),
                    ),
                    if (profile.matchReason.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Neden onerildi',
                        icon: Icons.auto_awesome_outlined,
                        child: Text(
                          profile.matchReason,
                          style: const TextStyle(
                            color: _textSoft,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Profil Detayi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _cyan]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (profile.verified)
                          const Icon(Icons.verified, color: _cyan, size: 22),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: _textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            profile.location.trim().isEmpty
                                ? 'Konum belirtilmedi'
                                : profile.location,
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 13,
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
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                label: '${profile.trustScore}% Trust',
                icon: Icons.shield_outlined,
                color: _green,
              ),
              if (profile.matchScore > 0)
                _MetricPill(
                  label: '${profile.matchScore}% Match',
                  icon: Icons.favorite_outline,
                  color: _cyan,
                ),
              _MetricPill(
                label: '${profile.creditsRequired} HC',
                icon: Icons.bolt_outlined,
                color: _violet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OtherUserProfileData {
  final String id;
  final String name;
  final String location;
  final String bio;
  final int trustScore;
  final bool verified;
  final int matchScore;
  final int creditsRequired;
  final String matchReason;
  final List<OtherUserSkillData> teachSkills;
  final List<OtherUserSkillData> learnSkills;

  const OtherUserProfileData({
    required this.id,
    required this.name,
    required this.location,
    required this.bio,
    required this.trustScore,
    required this.verified,
    this.matchScore = 0,
    this.creditsRequired = 0,
    this.matchReason = '',
    this.teachSkills = const [],
    this.learnSkills = const [],
  });

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class OtherUserSkillData {
  final String name;
  final String category;
  final int? level;

  const OtherUserSkillData({
    required this.name,
    this.category = '',
    this.level,
  });
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: OtherUserProfilePage._cyan, size: 17),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SkillWrap extends StatelessWidget {
  final List<OtherUserSkillData> skills;
  final String emptyText;
  final Color accent;

  const _SkillWrap({
    required this.skills,
    required this.emptyText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(color: OtherUserProfilePage._textMuted),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        final meta = [
          if (skill.category.trim().isNotEmpty) skill.category,
          if (skill.level != null) 'Level ${skill.level}/7',
        ].join(' - ');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: const TextStyle(
                    color: OtherUserProfilePage._textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
