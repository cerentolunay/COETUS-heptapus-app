import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/matching/models/match_candidate.dart';
import 'package:coetus/widgets/coetus_widgets.dart';
import 'package:flutter/material.dart';

/// Skill detay ekranı — grid'de bir [SkillCard]'a dokunulduğunda açılır.
/// Takas teklifi gönderme ve öğretmenin profiline geçiş, çağırıcı
/// (matching_feed_page.dart) tarafından sağlanan callback'ler üzerinden
/// gerçek Firestore işlemlerini tetikler; bu sayfa sadece görüntüleme ve
/// tetikleme yapar.
class SkillDetailPage extends StatelessWidget {
  const SkillDetailPage({
    super.key,
    required this.candidate,
    required this.onSendOffer,
    required this.onViewProfile,
  });

  final MatchCandidate candidate;
  final VoidCallback onSendOffer;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final icon = _categoryIcon(
      candidate.teacherSkill.category,
      candidate.teacherSkill.name,
    );
    final category = candidate.teacherSkill.category.isNotEmpty
        ? candidate.teacherSkill.category
        : 'Genel';
    final description = candidate.user.bio.trim().isNotEmpty
        ? candidate.user.bio
        : 'Bu ogretmen henuz bir aciklama eklemedi.';
    final matchLabel = candidate.matchScore > 0
        ? '${(candidate.matchScore * 100).round()}% eslesme'
        : '${(candidate.trustScore * 100).round()}% guven';

    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildHero(icon, category)),
                    const SizedBox(height: CoetusSpace.xxl),
                    _buildTitleRow(t),
                    const SizedBox(height: CoetusSpace.md),
                    Wrap(
                      spacing: CoetusSpace.sm,
                      runSpacing: CoetusSpace.sm,
                      children: [
                        CoetusChip('Seviye ${candidate.teacherSkill.level}/7'),
                        CoetusChip(matchLabel, tone: CoetusChipTone.warm),
                      ],
                    ),
                    const SizedBox(height: CoetusSpace.lg),
                    Text(description, style: t.bodyMedium),
                    if (candidate.partnerLearnSkills.isNotEmpty) ...[
                      const SizedBox(height: CoetusSpace.lg),
                      WarmNotice(
                        child: Text.rich(
                          TextSpan(
                            style: t.bodySmall?.copyWith(
                              color: CoetusColors.body,
                            ),
                            children: [
                              TextSpan(text: '${candidate.user.name} '),
                              const TextSpan(text: 'karsiliginda '),
                              TextSpan(
                                text: candidate.partnerLearnSkills.first.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: CoetusColors.navyInk,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    ' ogrenmek istiyor. Takas teklifin buna uygunsa oncelik kazanir.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(IconData icon, String category) {
    return SizedBox(
      width: 270,
      height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 270,
            height: 270,
            decoration: const BoxDecoration(
              color: CoetusColors.plateWarm,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 200,
            height: 200,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: CoetusColors.navy,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: CoetusColors.oat),
          ),
          Positioned(
            bottom: 14,
            child: CoetusChip(category, tone: CoetusChipTone.warm),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(TextTheme t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            candidate.teacherSkill.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.headlineSmall,
          ),
        ),
        const SizedBox(width: CoetusSpace.md),
        GestureDetector(
          onTap: onViewProfile,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: CoetusColors.navyTint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _initials(candidate.user.name),
                  style: const TextStyle(
                    color: CoetusColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: CoetusColors.card,
        border: Border(top: BorderSide(color: CoetusColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oturum bedeli',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              CreditBadge(amount: candidate.creditsRequired),
            ],
          ),
          const SizedBox(width: CoetusSpace.lg),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                onSendOffer();
                Navigator.pop(context);
              },
              child: const Text('Takas teklif et'),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
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

/// Kategori/skill adına göre bir Material ikonu döndürür — matching_feed_page
/// içindeki grid kartıyla aynı görseli üretmek için aynı eşlemenin bir
/// kopyası (bkz. matching_feed_page.dart `categoryIcon`).
IconData _categoryIcon(String category, String name) {
  final key = '$category $name'.toLowerCase();
  if (key.contains('muzik') || key.contains('müzik') || key.contains('music')) {
    return Icons.music_note_outlined;
  }
  if (key.contains('yazilim') ||
      key.contains('yazılım') ||
      key.contains('software') ||
      key.contains('code') ||
      key.contains('kod') ||
      key.contains('programlama')) {
    return Icons.code;
  }
  if (key.contains('dil') || key.contains('language')) {
    return Icons.public;
  }
  if (key.contains('tasarim') ||
      key.contains('tasarım') ||
      key.contains('design')) {
    return Icons.brush_outlined;
  }
  if (key.contains('el sanat') || key.contains('craft')) {
    return Icons.content_cut;
  }
  if (key.contains('fotograf') ||
      key.contains('fotoğraf') ||
      key.contains('photo')) {
    return Icons.photo_camera_outlined;
  }
  return Icons.star_outline;
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoetusColors.navyTint,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: CoetusColors.navy, size: 18),
        ),
      ),
    );
  }
}
