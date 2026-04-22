import 'package:coetus/features/auth/domain/models/app_user.dart';
import 'package:coetus/features/auth/data/repositories/local_auth_repository.dart';

import '../../domain/models/profile_data.dart';
import '../../domain/models/skill_model.dart';
import '../../domain/repositories/profile_repository.dart';

class LocalProfileRepository implements ProfileRepository {
  static ProfileData? _profile;

  @override
  Future<ProfileData> loadProfile() async {
    _profile ??= ProfileData(
      user: LocalAuthRepository.currentUser ?? const AppUser(
        id: 'local-user',
        name: 'Alex Chen',
        email: 'alex@example.com',
        bio: 'Skill swapping enthusiast',
      ),
      teachSkills: const [
        SkillModel(id: '1', name: 'Guitar', level: 6),
        SkillModel(id: '2', name: 'English', level: 2),
        SkillModel(id: '3', name: 'Cooking', level: 5),
      ],
      learnSkills: const [
        SkillModel(id: '4', name: 'Spanish', level: 1),
        SkillModel(id: '5', name: 'Yoga', level: 1),
        SkillModel(id: '6', name: 'Piano', level: 1),
      ],
    );

    return _profile!;
  }

  @override
  Future<ProfileData> updateProfile(AppUser user) async {
    final profile = await loadProfile();
    _profile = profile.copyWith(user: user);
    return _profile!;
  }

  @override
  Future<ProfileData> saveTeachSkill(SkillModel skill) async {
    final profile = await loadProfile();
    final skills = [...profile.teachSkills];
    final index = skills.indexWhere((item) => item.id == skill.id);

    if (index >= 0) {
      skills[index] = skill;
    } else {
      skills.add(skill);
    }

    _profile = profile.copyWith(teachSkills: skills);
    return _profile!;
  }

  @override
  Future<ProfileData> deleteTeachSkill(String skillId) async {
    final profile = await loadProfile();
    _profile = profile.copyWith(
      teachSkills: profile.teachSkills.where((skill) => skill.id != skillId).toList(),
    );
    return _profile!;
  }

  @override
  Future<ProfileData> saveLearnSkill(SkillModel skill) async {
    final profile = await loadProfile();
    final skills = [...profile.learnSkills];
    final index = skills.indexWhere((item) => item.id == skill.id);

    if (index >= 0) {
      skills[index] = skill;
    } else {
      skills.add(skill);
    }

    _profile = profile.copyWith(learnSkills: skills);
    return _profile!;
  }

  @override
  Future<ProfileData> deleteLearnSkill(String skillId) async {
    final profile = await loadProfile();
    _profile = profile.copyWith(
      learnSkills: profile.learnSkills.where((skill) => skill.id != skillId).toList(),
    );
    return _profile!;
  }
}
