import 'package:flutter/material.dart';
import '../../../profile/presentation/widgets/interest_tree.dart';
import '../../../profile/domain/onboarding/interest_catalog.dart';
import '../../../profile/domain/services/profile_completion_service.dart';
import '../../../../preview/preview_mode.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/profile/data/repositories/profile_repository_factory.dart';

class DiscoveryTestPage extends StatefulWidget {
  const DiscoveryTestPage({super.key});

  @override
  State<DiscoveryTestPage> createState() => _DiscoveryTestPageState();
}

class _DiscoveryTestPageState extends State<DiscoveryTestPage> {
  final _selection = InterestSelection();
  bool _isSaving = false;

  Future<void> _handleContinue() async {
    if (_isSaving) return;
    if (_selection.skills.values.any((skill) => !skill.learn && !skill.teach)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seçtiğin her beceri için bir amaç seç veya beceriyi kaldır.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (!PreviewMode.enabled && Firebase.apps.isNotEmpty) {
        final service = ProfileCompletionService();
        final completed = await service.isProfileCompleted();
        if (!mounted) return;
        if (!completed) {
          context.go('/complete-profile', extra: _selection);
          return;
        }
        final profile = await ProfileRepositoryFactory.create().loadProfile();
        await service.completeProfile(
          displayName: profile.user.name,
          bio: profile.user.bio,
          location: profile.user.location ?? '',
          photoUrl: profile.user.photoUrl,
          interests: _selection.selectedInterestIds,
          skills: _selection.selectedSkills,
        );
      } else {
        final repository = ProfileRepositoryFactory.create();
        for (final skill in _selection.selectedSkills) {
          if (skill.learnable) {
            await repository.saveLearnSkill(skill.copyWith(teachable: false));
          }
          if (skill.teachable) {
            await repository.saveTeachSkill(skill.copyWith(learnable: false));
          }
        }
      }

      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seçimlerin kaydedilemedi. Lütfen yeniden dene.'),
          ),
        );
      }
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
              Expanded(
                child: SingleChildScrollView(
                  child: InterestTree(
                    selection: _selection,
                    enabled: !_isSaving,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_selection.selectedInterestIds.length} alan · ${_selection.skills.length} beceri seçildi',
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
                            color: CoetusPalette.purple,
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
