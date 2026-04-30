import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SkillDiscoveryPage extends StatefulWidget {
  const SkillDiscoveryPage({super.key});

  @override
  State<SkillDiscoveryPage> createState() => _SkillDiscoveryPageState();
}

class _SkillDiscoveryPageState extends State<SkillDiscoveryPage> {
  static const Color _bgTop = Color(0xFF07111F);
  static const Color _bgMid = Color(0xFF10203A);
  static const Color _bgBottom = Color(0xFF1B2754);
  static const Color _cyan = Color(0xFF4FD1C5);
  static const Color _blue = Color(0xFF4C8BF5);
  static const Color _amber = Color(0xFFF6AD55);
  static const Color _surface = Color(0x14FFFFFF);
  static const Color _surfaceStrong = Color(0x1FFFFFFF);
  static const Color _border = Color(0x26FFFFFF);
  static const Color _textMuted = Color(0xFFB8C8DD);
  static const Color _textSoft = Color(0xFFE7EEF9);
  static const Color _chipBackground = Color(0xFF2C3B58);
  static const Color _chipText = Color(0xFFF2F7FF);
  static const Color _chipSelectedText = Color(0xFF06202C);

  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = const [
    'Hepsi',
    'Yazilim',
    'Dil',
    'Tasarim',
    'Muzik',
    'Is',
  ];

  final List<_SkillDiscoveryItem> _skills = const [
    _SkillDiscoveryItem(
      id: 'ui-01',
      title: 'UI Tasarimi Mentorlugu',
      category: 'Tasarim',
      mentorName: 'Zeynep Karaca',
      mentorRole: 'Product Designer',
      location: 'Istanbul',
      levelLabel: 'Orta - Ileri',
      sessionCredits: 35,
      matchScore: 97,
      rating: 4.9,
      reviewCount: 48,
      description:
          'Figma akislari, component dusuncesi ve mobil ekran hiyerarsisini birebir feedback ile gelistir.',
      tags: ['Figma', 'Mobile UX', 'Design System'],
      availability: 'Bu hafta 3 bos slot',
      accent: _cyan,
    ),
    _SkillDiscoveryItem(
      id: 'lang-02',
      title: 'Konusma Odakli Ingilizce',
      category: 'Dil',
      mentorName: 'Mert Aydin',
      mentorRole: 'IELTS Mentor',
      location: 'Ankara',
      levelLabel: 'Baslangic - Orta',
      sessionCredits: 24,
      matchScore: 92,
      rating: 4.8,
      reviewCount: 63,
      description:
          'Gunluk konusma pratigi, telaffuz duzeltmeleri ve hedef odakli mini odevlerle ilerle.',
      tags: ['Speaking', 'Pronunciation', 'Interview'],
      availability: 'Aksam saatleri uygun',
      accent: _blue,
    ),
    _SkillDiscoveryItem(
      id: 'code-03',
      title: 'Flutter ile MVP Gelistirme',
      category: 'Yazilim',
      mentorName: 'Deniz Erdem',
      mentorRole: 'Flutter Developer',
      location: 'Izmir',
      levelLabel: 'Orta Seviye',
      sessionCredits: 42,
      matchScore: 95,
      rating: 5.0,
      reviewCount: 29,
      description:
          'Widget mimarisi, state management ve hizli prototipleme uzerinden gercek urun mantigiyle ilerle.',
      tags: ['Flutter', 'Firebase', 'Architecture'],
      availability: 'Hafta ici 19:00 sonrasi',
      accent: _cyan,
    ),
    _SkillDiscoveryItem(
      id: 'music-04',
      title: 'Akustik Gitar Temelleri',
      category: 'Muzik',
      mentorName: 'Elif Gunes',
      mentorRole: 'Music Instructor',
      location: 'Bursa',
      levelLabel: 'Baslangic',
      sessionCredits: 18,
      matchScore: 88,
      rating: 4.7,
      reviewCount: 37,
      description:
          'Ritim, akor gecisleri ve calisma rutini ile ilk sarkilarini kisa surede calmaya basla.',
      tags: ['Chord', 'Rhythm', 'Practice Plan'],
      availability: 'Hafta sonu atolyeleri acik',
      accent: _amber,
    ),
    _SkillDiscoveryItem(
      id: 'biz-05',
      title: 'Sunum ve Hikayelestirme',
      category: 'Is',
      mentorName: 'Selin Demir',
      mentorRole: 'Growth Lead',
      location: 'Remote',
      levelLabel: 'Tum Seviyeler',
      sessionCredits: 30,
      matchScore: 90,
      rating: 4.9,
      reviewCount: 21,
      description:
          'Pitch deck akisi, hikaye kurgusu ve ikna gucu yuksek sunum teknikleri icin uygulamali destek al.',
      tags: ['Pitch', 'Storytelling', 'Public Speaking'],
      availability: 'Uzaktan birebir gorusme',
      accent: _blue,
    ),
  ];

  String _selectedCategory = 'Hepsi';
  bool _onlyHighMatch = true;

  List<_SkillDiscoveryItem> get _filteredSkills {
    final query = _searchController.text.trim().toLowerCase();

    return _skills.where((skill) {
      final matchesCategory =
          _selectedCategory == 'Hepsi' || skill.category == _selectedCategory;
      final matchesHighMatch = !_onlyHighMatch || skill.matchScore >= 90;
      final matchesQuery =
          query.isEmpty ||
          skill.title.toLowerCase().contains(query) ||
          skill.mentorName.toLowerCase().contains(query) ||
          skill.tags.any((tag) => tag.toLowerCase().contains(query));

      return matchesCategory && matchesHighMatch && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showOfferSheet(_SkillDiscoveryItem skill) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F1B32),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [skill.accent, Colors.white.withValues(alpha: 0.18)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${skill.mentorName} ile teklif hazirla',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OfferLine(
                      icon: Icons.schedule_outlined,
                      label: 'Onerilen sure',
                      value: '45 dakika',
                    ),
                    SizedBox(height: 10),
                    _OfferLine(
                      icon: Icons.bolt_outlined,
                      label: 'Tahmini kredi',
                      value: '24 - 42 HC',
                    ),
                    SizedBox(height: 10),
                    _OfferLine(
                      icon: Icons.handshake_outlined,
                      label: 'Sonraki adim',
                      value: 'Profil ve beklenti uyumu',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.context.go('/matching-feed');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: skill.accent,
                    foregroundColor: const Color(0xFF07111F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Eslesme akisina gec',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSkills = _filteredSkills;

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
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 20),
                            _buildHeroCard(filteredSkills.length),
                            const SizedBox(height: 18),
                            _buildSearchField(),
                            const SizedBox(height: 16),
                            _buildFilterRow(),
                            const SizedBox(height: 18),
                            _buildInsightStrip(),
                            const SizedBox(height: 20),
                            Text(
                              'One cikan skill oturumlari',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.96),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${filteredSkills.length} uygun skill bulundu',
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                    if (filteredSkills.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyDiscoveryState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                        sliver: SliverList.separated(
                          itemCount: filteredSkills.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final skill = filteredSkills[index];
                            return _SkillDiscoveryCard(
                              item: skill,
                              onViewProfile: () =>
                                  context.go('/profile-advanced'),
                              onSendOffer: () => _showOfferSheet(skill),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              _DiscoveryBottomNav(
                onProfileTap: () => context.go('/profile-advanced'),
                onChatTap: () => context.go('/chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Skill Kesfet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ilgine, seviyene ve kredi bakiyene uygun oturumlari filtrele.',
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: IconButton(
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.tune, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(int resultCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF18375F), Color(0xFF12294A)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: _cyan, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Akilli eslesme',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$resultCount aktif ilan',
                style: const TextStyle(
                  color: _textSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Bu hafta yuksek uyumlu skill oturumlari seni bekliyor.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Yazilim, dil, tasarim ve muzik alanlarinda kredi bazli birebir gorusmeleri tek ekranda yonet.',
            style: const TextStyle(color: _textSoft, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Skill, mentor veya etiket ara',
        hintStyle: const TextStyle(color: _textMuted),
        prefixIcon: const Icon(Icons.search, color: _textMuted),
        filled: true,
        fillColor: _surfaceStrong,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _cyan),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;

              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: isSelected ? _chipSelectedText : _chipText,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: _cyan,
                backgroundColor: _chipBackground,
                disabledColor: _chipBackground,
                side: BorderSide(
                  color: isSelected ? Colors.transparent : _border,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            setState(() {
              _onlyHighMatch = !_onlyHighMatch;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: _onlyHighMatch,
                onChanged: (value) {
                  setState(() {
                    _onlyHighMatch = value;
                  });
                },
                activeThumbColor: _cyan,
              ),
              const Text(
                'Sadece %90+ uyumlu skilller',
                style: TextStyle(
                  color: _textSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightStrip() {
    return Row(
      children: const [
        Expanded(
          child: _InsightTile(
            title: 'En hizli donus',
            value: '< 2 saat',
            icon: Icons.schedule,
            accent: _cyan,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _InsightTile(
            title: 'Ort. kredi',
            value: '29 HC',
            icon: Icons.bolt,
            accent: _amber,
          ),
        ),
      ],
    );
  }
}

class _SkillDiscoveryCard extends StatelessWidget {
  final _SkillDiscoveryItem item;
  final VoidCallback onViewProfile;
  final VoidCallback onSendOffer;

  const _SkillDiscoveryCard({
    required this.item,
    required this.onViewProfile,
    required this.onSendOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _SkillDiscoveryPageState._surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _SkillDiscoveryPageState._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [item.accent, Colors.white.withValues(alpha: 0.18)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.explore_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.mentorName} • ${item.mentorRole}',
                      style: const TextStyle(
                        color: _SkillDiscoveryPageState._textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '%${item.matchScore}',
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: const TextStyle(
              color: _SkillDiscoveryPageState._textSoft,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _SkillDiscoveryPageState._border,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(icon: Icons.location_on_outlined, label: item.location),
              _MetaPill(
                icon: Icons.workspace_premium_outlined,
                label: item.levelLabel,
              ),
              _MetaPill(
                icon: Icons.star_border,
                label: '${item.rating} (${item.reviewCount})',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.availability,
                    style: const TextStyle(
                      color: _SkillDiscoveryPageState._textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${item.sessionCredits} HC',
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewProfile,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: _SkillDiscoveryPageState._border,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Profili Gor',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSendOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.accent,
                    foregroundColor: const Color(0xFF07111F),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Teklif Gonder',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _InsightTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _SkillDiscoveryPageState._border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _SkillDiscoveryPageState._textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _SkillDiscoveryPageState._textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryBottomNav extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onChatTap;

  const _DiscoveryBottomNav({
    required this.onProfileTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC10203A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavButton(
            icon: Icons.person_outline,
            label: 'Profil',
            onTap: onProfileTap,
          ),
          const _BottomNavButton(
            icon: Icons.explore_outlined,
            label: 'Kesfet',
            isActive: true,
          ),
          _BottomNavButton(
            icon: Icons.chat_bubble_outline,
            label: 'Sohbet',
            onTap: onChatTap,
          ),
        ],
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _BottomNavButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? _SkillDiscoveryPageState._cyan
        : Colors.white.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OfferLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _SkillDiscoveryPageState._cyan, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _SkillDiscoveryPageState._textMuted,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyDiscoveryState extends StatelessWidget {
  const _EmptyDiscoveryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _SkillDiscoveryPageState._cyan,
                    _SkillDiscoveryPageState._blue,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.travel_explore,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Filtrelere uygun skill bulunamadi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Arama kelimeni sadeleştir veya kategori secimini genislet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _SkillDiscoveryPageState._textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillDiscoveryItem {
  final String id;
  final String title;
  final String category;
  final String mentorName;
  final String mentorRole;
  final String location;
  final String levelLabel;
  final int sessionCredits;
  final int matchScore;
  final double rating;
  final int reviewCount;
  final String description;
  final List<String> tags;
  final String availability;
  final Color accent;

  const _SkillDiscoveryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.mentorName,
    required this.mentorRole,
    required this.location,
    required this.levelLabel,
    required this.sessionCredits,
    required this.matchScore,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.tags,
    required this.availability,
    required this.accent,
  });
}
