import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/profile/data/repositories/profile_repository_factory.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';

class DiscoveryTestPage extends StatefulWidget {
  const DiscoveryTestPage({super.key});

  @override
  State<DiscoveryTestPage> createState() => _DiscoveryTestPageState();
}

class _DiscoveryTestPageState extends State<DiscoveryTestPage> {
  static const List<_InterestCategory> _categories = [
    _InterestCategory(name: 'Müzik', icon: Icons.music_note_outlined),
    _InterestCategory(name: 'Yazılım', icon: Icons.code),
    _InterestCategory(name: 'Dil', icon: Icons.public),
    _InterestCategory(name: 'Tasarım', icon: Icons.brush_outlined),
    _InterestCategory(name: 'El sanatları', icon: Icons.content_cut),
    _InterestCategory(name: 'Fotoğraf', icon: Icons.photo_camera_outlined),
  ];

  final Set<String> _selected = {};
  bool _isSaving = false;

  void _toggle(String category) {
    setState(() {
      if (_selected.contains(category)) {
        _selected.remove(category);
      } else {
        _selected.add(category);
      }
    });
  }

  String _slugify(String category) {
    return category
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Future<void> _handleContinue() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ProfileRepositoryFactory.create();
      for (final category in _selected) {
        await repository.saveLearnSkill(
          SkillModel(id: _slugify(category), name: category, level: 1),
        );
      }

      if (!mounted) return;
      context.go('/home');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: CoetusColors.card,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: CoetusColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Container(color: CoetusColors.border),
                            FractionallySizedBox(
                              widthFactor: 1,
                              child: Container(color: CoetusColors.navy),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Ne öğrenmek\nistiyorsun?',
                style: textTheme.headlineMedium?.copyWith(
                  color: CoetusColors.navyInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'En az 3 alan seç, eşleşmeleri buna göre kuruyoruz.',
                style: textTheme.bodyMedium?.copyWith(
                  color: CoetusColors.muted,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selected.contains(category.name);
                    return _CategoryCard(
                      category: category,
                      selected: isSelected,
                      onTap: () => _toggle(category.name),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_selected.length} alan seçildi',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleContinue,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: CoetusColors.oat,
                          ),
                        )
                      : const Text('Devam et'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _InterestCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CoetusColors.navy : CoetusColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: CoetusShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      selected ? CoetusColors.oat.withValues(alpha: .18) : CoetusColors.plateWarm,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  color: selected ? CoetusColors.oat : CoetusColors.navy,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: TextStyle(
                  color: selected ? CoetusColors.oat : CoetusColors.navyInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestCategory {
  const _InterestCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}
