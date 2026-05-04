import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/models/app_user.dart';
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

  AppUser _user = const AppUser(
    id: 'u1',
    name: 'Alex Chen',
    email: 'alex@example.com',
    bio: 'Skill swapping enthusiast',
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

  bool _isLoadingProfile = true;

  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _card = Color(0xFF1A1A2E);
  static const Color _card2 = Color(0xFF16162A);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _indigoText = Color(0xFF818CF8);
  static const Color _violetText = Color(0xFFC4B5FD);

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
            'Edit Skill',
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
                      hintText: 'Skill name',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.40),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.12),
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
                    'Level: ${selectedLevel.toInt()}/7',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: selectedLevel,
                    min: 1,
                    max: 7,
                    divisions: 6,
                    activeColor: _indigo,
                    inactiveColor: Colors.white.withOpacity(0.15),
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
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.70)),
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
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _showDeleteSkillDialog(SkillModel skill) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Delete Skill',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '${skill.name} skillini silmek istiyor musun?',
            style: TextStyle(color: Colors.white.withOpacity(0.80)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.70)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _skills.removeWhere((s) => s.id == skill.id);
                });

                await _profileRepository.deleteTeachSkill(skill.id);

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
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
    ).showSnackBar(SnackBar(content: Text('${newSkill.name} added')));
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: _border),
              ),
              child: IconButton(
                onPressed: () => context.go('/notifications'),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: _indigoText,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_indigo, _violet]),
              ),
              child: IconButton(
                onPressed: _showEditProfileDialog,
                icon: const Icon(
                  Icons.edit_outlined,
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
              gradient: LinearGradient(colors: [_indigo, _violet]),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _user.bio,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      text: '${_skills.length} skills',
                      background: _indigo.withOpacity(0.20),
                      textColor: _indigoText,
                    ),
                    _InfoChip(
                      text: '${_learningGoals.length} goals',
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
              onPressed: _showAddSkillDialog,
              icon: const Icon(Icons.add, color: _indigoText, size: 18),
              label: const Text(
                'Add Skill',
                style: TextStyle(color: _indigoText, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: _skills.map((skill) {
            return _SkillCard(
              skill: skill,
              onEdit: () => _showEditSkillDialog(skill),
              onDelete: () => _showDeleteSkillDialog(skill),
            );
          }).toList(),
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
              onPressed: _showAddGoalDialog,
              icon: const Icon(Icons.add, color: _indigoText, size: 18),
              label: const Text(
                'Add Goal',
                style: TextStyle(color: _indigoText, fontSize: 14),
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _violet.withOpacity(0.20),
                    child: Text(
                      _skillAvatarText(goal.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
        border: Border(top: BorderSide(color: _border)),
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
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final SkillModel skill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SkillCard({
    required this.skill,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _bg = Color(0xFF1A1A2E);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _track = Color(0xFF0A0A0F);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _indigoText = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final int normalizedLevel = skill.level.clamp(0, 7);
    final double widthFactor = normalizedLevel / 7;

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
              CircleAvatar(
                radius: 16,
                backgroundColor: _indigo.withOpacity(0.20),
                child: Text(
                  skill.name.isNotEmpty ? skill.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                '$normalizedLevel/7',
                style: const TextStyle(
                  color: _indigoText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
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
                        gradient: LinearGradient(colors: [_indigo, _violet]),
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
              final bool active = index < normalizedLevel;
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
    final Color color = isActive ? _active : Colors.white.withOpacity(0.45);

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
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
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

  static const Color _card = Color(0xFF1A1A2E);
  static const Color _indigo = Color(0xFF6366F1);

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
      title: const Text('Add Skill', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Skill name',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.40)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _indigo),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Level: ${_selectedLevel.toInt()}/7',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: _selectedLevel,
            min: 1,
            max: 7,
            divisions: 6,
            activeColor: _indigo,
            inactiveColor: Colors.white.withOpacity(0.15),
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
            'Cancel',
            style: TextStyle(color: Colors.white.withOpacity(0.70)),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: _indigo),
          child: const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
