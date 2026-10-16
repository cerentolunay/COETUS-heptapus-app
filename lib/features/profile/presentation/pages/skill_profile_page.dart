import 'package:coetus/features/verification/presentation/verification_page.dart';
import 'package:coetus/widgets/coetus_delete_dialog.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/coetus_tokens.dart';
import '../../../../widgets/coetus_bottom_nav.dart';
import '../../../../widgets/coetus_widgets.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/data/repositories/auth_repository_factory.dart';
import '../../data/repositories/profile_repository_factory.dart';
import '../../domain/models/profile_data.dart';
import '../../domain/models/skill_model.dart';
import '../../domain/repositories/profile_repository.dart';

class SkillProfilePage extends StatefulWidget {
  const SkillProfilePage({super.key});

  @override
  State<SkillProfilePage> createState() => _SkillProfilePageState();
}

class _SkillProfilePageState extends State<SkillProfilePage> {
  final ProfileRepository _profileRepository =
      ProfileRepositoryFactory.create();
  final AuthRepository _authRepository = AuthRepositoryFactory.create();

  AppUser _user = const AppUser(
    id: 'u1',
    name: 'Alex Chen',
    email: 'alex@example.com',
    bio: 'Yeteneklerini paylaşmayı seven bir topluluk üyesi',
  );

  List<SkillModel> _skills = const [
    SkillModel(id: '1', name: 'Guitar', level: 6),
    SkillModel(id: '2', name: 'English', level: 2),
    SkillModel(id: '3', name: 'Cooking', level: 5),
    SkillModel(id: '4', name: 'Photography', level: 4),
  ];

  List<SkillModel> _learningGoals = const [
    SkillModel(id: '1', name: 'Spanish', level: 1),
    SkillModel(id: '2', name: 'Yoga', level: 1),
    SkillModel(id: '3', name: 'Piano', level: 1),
  ];

  List<String> _availabilitySlots = const [];

  bool _isLoadingProfile = true;
  bool _isSigningOut = false;

  // Dialog surfaces use the shared dark purple palette.
  static const Color _card = CoetusPalette.purple;
  static const Color _indigo = CoetusPalette.blue;
  static const Color _violet = CoetusPalette.blue;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileRepository.loadProfile();

    if (!mounted) return;

    setState(() {
      _applyProfile(profile);
      _isLoadingProfile = false;
    });
  }

  void _applyProfile(ProfileData profile) {
    _user = profile.user;
    _skills = profile.teachSkills;
    _learningGoals = profile.learnSkills;
    _availabilitySlots = profile.availabilitySlots;
  }

  String _skillAvatarText(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return trimmed[0].toUpperCase();
    }

    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  Future<void> _showEditSkillDialog(SkillModel skill) async {
    final nameController = TextEditingController(text: skill.name);
    double selectedLevel = skill.level.toDouble();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Yeteneği düzenle',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      fillColor: _card,
                      hintText: 'Yetenek adı',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _indigo),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Seviye: ${selectedLevel.toInt()}/7',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: selectedLevel,
                    min: 1,
                    max: 7,
                    divisions: 6,
                    activeColor: _indigo,
                    inactiveColor: Colors.white.withValues(alpha: 0.15),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLevel = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedName = nameController.text.trim();
                if (updatedName.isEmpty) return;

                setState(() {
                  final index = _skills.indexWhere((s) => s.id == skill.id);
                  if (index != -1) {
                    _skills[index] = _skills[index].copyWith(
                      name: updatedName,
                      level: selectedLevel.toInt(),
                    );
                  }
                });

                await _profileRepository.saveTeachSkill(
                  skill.copyWith(
                    name: updatedName,
                    level: selectedLevel.toInt(),
                  ),
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _indigo),
              child: const Text(
                'Kaydet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _showDeleteSkillDialog(SkillModel skill) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CoetusDeleteDialog(
        name: skill.name,
        onDelete: () async {
          final updated = await _profileRepository.deleteTeachSkill(skill.id);
          if (mounted) setState(() => _applyProfile(updated));
        },
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final bool? saved = await context.push<bool>('/profile/edit');

    if (!mounted) return;

    if (saved == true) {
      await _loadProfile();
    }
  }

  Future<void> _showAddSkillDialog() async {
    final SkillModel? newSkill = await showDialog<SkillModel>(
      context: context,
      builder: (_) => const _AddSkillDialog(),
    );

    if (!mounted || newSkill == null) return;

    setState(() {
      _skills.add(newSkill);
    });

    await _profileRepository.saveTeachSkill(newSkill);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${newSkill.name} eklendi')));
  }

  Future<void> _showAddGoalDialog() async {
    final SkillModel? newGoal = await showDialog<SkillModel>(
      context: context,
      builder: (_) => const _AddSkillDialog(),
    );

    if (!mounted || newGoal == null) return;

    final updatedGoal = newGoal.copyWith(level: 1);

    setState(() {
      _learningGoals.add(updatedGoal);
    });

    await _profileRepository.saveLearnSkill(updatedGoal);
  }

  Future<void> _showEditGoalDialog(SkillModel goal) async {
    final nameController = TextEditingController(text: goal.name);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Hedefi düzenle',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              fillColor: _card,
              hintText: 'Hedef adı',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _violet),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedName = nameController.text.trim();
                if (updatedName.isEmpty) return;

                setState(() {
                  final index = _learningGoals.indexWhere(
                    (item) => item.id == goal.id,
                  );
                  if (index != -1) {
                    _learningGoals[index] = _learningGoals[index].copyWith(
                      name: updatedName,
                    );
                  }
                });

                await _profileRepository.saveLearnSkill(
                  goal.copyWith(name: updatedName),
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _violet),
              child: const Text(
                'Kaydet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _showDeleteGoalDialog(SkillModel goal) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CoetusDeleteDialog(
        name: goal.name,
        onDelete: () async {
          final updated = await _profileRepository.deleteLearnSkill(goal.id);
          if (mounted) setState(() => _applyProfile(updated));
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
        content: Text(
          'Hesabından çıkış yapmak istediğine emin misin?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.80)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'İptal',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CoetusColors.danger,
            ),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSigningOut = true);

    try {
      await _authRepository.signOut();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Çıkış yapılamadı: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: CoetusColors.oat,
        body: CoetusLoadingState(),
      );
    }

    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: Column(
        children: [
          _buildHeader(t),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        CoetusSpace.screenH,
                        CoetusSpace.xl,
                        CoetusSpace.screenH,
                        CoetusSpace.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.verified_outlined),
                              title: const Text(
                                'Çalışmalarım ve eşleşme onayları',
                              ),
                              subtitle: const Text(
                                'Kanıt paylaş · Onay al · Token kazan',
                              ),
                              trailing: const Icon(Icons.arrow_outward_rounded),
                              onTap: () async {
                                await context.push('/verification');
                                if (mounted) await _loadProfile();
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSkillsSection(t),
                          const SizedBox(height: CoetusSpace.xxl),
                          _buildLearningGoalsSection(t),
                          if (_availabilitySlots.isNotEmpty) ...[
                            const SizedBox(height: CoetusSpace.xxl),
                            WarmNotice(
                              child: Text(
                                'Uygunluk: ${_availabilitySlots.join(', ')}',
                                style: t.bodySmall?.copyWith(
                                  color: CoetusColors.body,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: CoetusSpace.xxl),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
                  ),
                  const CoetusBottomNav(currentIndex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TextTheme t) {
    final initials = _skillAvatarText(_user.name);
    final location = _user.location?.trim();
    final hasLocation = location != null && location.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: CoetusColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(CoetusRadius.sheet),
          bottomRight: Radius.circular(CoetusRadius.sheet),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CoetusSpace.screenH,
            CoetusSpace.md,
            CoetusSpace.screenH,
            CoetusSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => context.go('/notifications'),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Profil',
                        style: t.titleMedium?.copyWith(color: CoetusColors.oat),
                      ),
                    ),
                  ),
                  _HeaderIconButton(
                    icon: Icons.edit_outlined,
                    onTap: _showEditProfileDialog,
                  ),
                ],
              ),
              const SizedBox(height: CoetusSpace.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: CoetusColors.plateWarm,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initials,
                      style: t.titleLarge?.copyWith(color: CoetusColors.navy),
                    ),
                  ),
                  const SizedBox(width: CoetusSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.headlineSmall?.copyWith(
                            color: CoetusColors.oat,
                          ),
                        ),
                        if (hasLocation) ...[
                          const SizedBox(height: 3),
                          Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(
                              color: CoetusColors.oat.withValues(alpha: .7),
                            ),
                          ),
                        ],
                        if (_user.trustScore > 0) ...[
                          const SizedBox(height: CoetusSpace.sm),
                          Wrap(
                            spacing: CoetusSpace.sm,
                            runSpacing: CoetusSpace.sm,
                            children: [
                              if (_user.trustScore > 0) _buildTrustPill(),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CoetusSpace.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: CoetusSpace.md,
                  horizontal: CoetusSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                        value: '${_user.credits}',
                        label: 'KREDİ',
                      ),
                    ),
                    _statDivider(),
                    Expanded(
                      child: _ProfileStat(
                        value: '${_skills.length}',
                        label: 'ÖĞRETTİM',
                      ),
                    ),
                    _statDivider(),
                    Expanded(
                      child: _ProfileStat(
                        value: '${_learningGoals.length}',
                        label: 'ÖĞRENDİM',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: .15),
    );
  }

  Widget _buildTrustPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Güven ${_user.trustScore}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: CoetusColors.oat,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isSigningOut ? null : _handleLogout,
        icon: Icon(
          _isSigningOut ? Icons.hourglass_empty : Icons.logout,
          size: 18,
          color: CoetusColors.danger,
        ),
        label: Text(_isSigningOut ? 'Çıkılıyor...' : 'Çıkış Yap'),
        style: OutlinedButton.styleFrom(
          foregroundColor: CoetusColors.danger,
          side: const BorderSide(color: CoetusColors.danger, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSkillsSection(TextTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ÖĞRETEBİLDİĞİ', style: t.labelSmall),
            TextButton.icon(
              onPressed: _showAddSkillDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ekle'),
            ),
          ],
        ),
        const SizedBox(height: CoetusSpace.sm),
        if (_skills.isEmpty)
          CoetusEmptyState(
            icon: Icons.school_outlined,
            title: 'Henüz beceri eklenmedi',
            message: 'Öğretebileceğin becerileri ekleyerek profilini tamamla.',
            actionLabel: 'Beceri Ekle',
            onAction: _showAddSkillDialog,
          )
        else
          Column(
            children: _skills
                .map(
                  (skill) => _SkillRow(
                    skill: skill,
                    onEdit: () => _showEditSkillDialog(skill),
                    onDelete: () => _showDeleteSkillDialog(skill),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildLearningGoalsSection(TextTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ÖĞRENMEK İSTEDİĞİ', style: t.labelSmall),
        const SizedBox(height: CoetusSpace.sm),
        Wrap(
          spacing: CoetusSpace.sm,
          runSpacing: CoetusSpace.sm,
          children: [
            for (final goal in _learningGoals)
              _GoalChip(
                goal: goal,
                onEdit: () => _showEditGoalDialog(goal),
                onDelete: () => _showDeleteGoalDialog(goal),
              ),
            GestureDetector(
              onTap: _showAddGoalDialog,
              child: const CoetusChip('+ Ekle', dashed: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoetusColors.oat.withValues(alpha: .14),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 18, color: CoetusColors.oat),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: t.titleLarge?.copyWith(color: CoetusColors.oat)),
        const SizedBox(height: 2),
        Text(
          label,
          style: t.labelSmall?.copyWith(
            color: CoetusColors.oat.withValues(alpha: .65),
          ),
        ),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.skill,
    required this.onEdit,
    required this.onDelete,
  });

  final SkillModel skill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: CoetusSpace.md),
      padding: const EdgeInsets.all(CoetusSpace.lg),
      decoration: BoxDecoration(
        color: CoetusColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: CoetusShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: CoetusColors.navy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_outline,
              size: 20,
              color: CoetusColors.oat,
            ),
          ),
          const SizedBox(width: CoetusSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall,
                ),
                const SizedBox(height: 2),
                Text('Seviye ${skill.level}', style: t.bodySmall),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => VerificationPage(skillId: skill.id),
                    ),
                  ),
                  child: const Text('Çalışma ekle (isteğe bağlı)'),
                ),
                if (skill.peerApprovalCount > 0)
                  Text(
                    'Eşleştiği ${skill.peerApprovalCount} kişiden onay',
                    style: TextStyle(
                      color: CoetusColors.successDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: CoetusSpace.sm),
          CoetusChip('Sv. ${skill.level}'),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: CoetusColors.muted,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: CoetusColors.danger,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final SkillModel goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.only(left: 13, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: CoetusColors.coralSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            goal.name,
            style: t.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CoetusColors.coralDeep,
            ),
          ),
          InkWell(
            onTap: onEdit,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.edit_outlined,
                size: 13,
                color: CoetusColors.coralDeep,
              ),
            ),
          ),
          InkWell(
            onTap: onDelete,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.close, size: 13, color: CoetusColors.coralDeep),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSkillDialog extends StatefulWidget {
  const _AddSkillDialog();

  @override
  State<_AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<_AddSkillDialog> {
  final TextEditingController _nameController = TextEditingController();
  double _selectedLevel = 1;

  static const Color _card = CoetusPalette.purple;
  static const Color _indigo = CoetusPalette.blue;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final String skillName = _nameController.text.trim();

    if (skillName.isEmpty) return;

    Navigator.of(context).pop(
      SkillModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: skillName,
        level: _selectedLevel.toInt(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _card,
      title: const Text('Yetenek ekle', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              fillColor: _card,
              hintText: 'Yetenek adı',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _indigo),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Seviye: ${_selectedLevel.toInt()}/7',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: _selectedLevel,
            min: 1,
            max: 7,
            divisions: 6,
            activeColor: _indigo,
            inactiveColor: Colors.white.withValues(alpha: 0.15),
            label: _selectedLevel.toInt().toString(),
            onChanged: (value) {
              setState(() {
                _selectedLevel = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Vazgeç',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: _indigo),
          child: const Text('Ekle', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
