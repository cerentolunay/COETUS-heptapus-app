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
        bio: 'Yeteneklerini paylaşmayı seven bir topluluk üyesi',
      ),
      teachSkills: const [
        SkillModel(id: '1', name: 'Guitar', level: 6, category: 'Music', teachable: true),
        SkillModel(id: '2', name: 'English', level: 2, category: 'Language', teachable: true),
        SkillModel(id: '3', name: 'Cooking', level: 5, category: 'Food', teachable: true),
      ],
      learnSkills: const [
        SkillModel(id: '4', name: 'Spanish', level: 1, category: 'Language', learnable: true),
        SkillModel(id: '5', name: 'Yoga', level: 1, category: 'Health', learnable: true),
        SkillModel(id: '6', name: 'Piano', level: 1, category: 'Music', learnable: true),
      ],
      availabilitySlots: const ['monday-evening', 'wednesday-evening'],
    );

    return _profile!;
  }

  @override
  Future<List<ProfileData>> loadDiscoverableProfiles({int limit = 50}) async {
    return const [
      ProfileData(
        user: AppUser(
          id: 'candidate-1',
          name: 'Sarah Martinez',
          email: 'sarah@example.com',
          bio:
              'Native Spanish speaker and certified language teacher. I love helping people learn through conversation and cultural immersion.',
          trustScore: 96,
          credits: 120,
          verified: true,
        ),
        teachSkills: [
          SkillModel(
            id: '4',
            name: 'Spanish',
            level: 7,
            category: 'Language',
            teachable: true,
          ),
          SkillModel(
            id: '1',
            name: 'Guitar',
            level: 5,
            category: 'Music',
            teachable: true,
          ),
        ],
        learnSkills: [
          SkillModel(
            id: '2',
            name: 'English',
            level: 2,
            category: 'Language',
            learnable: true,
          ),
        ],
        availabilitySlots: ['monday-evening', 'saturday-morning'],
      ),
      ProfileData(
        user: AppUser(
          id: 'candidate-2',
          name: 'David Kim',
          email: 'david@example.com',
          bio:
              'Senior software engineer at a tech startup. Passionate about teaching web development and learning new languages.',
          trustScore: 98,
          credits: 150,
          verified: true,
        ),
        teachSkills: [
          SkillModel(
            id: '7',
            name: 'Coding',
            level: 7,
            category: 'Programming',
            teachable: true,
          ),
          SkillModel(
            id: '2',
            name: 'English',
            level: 6,
            category: 'Language',
            teachable: true,
          ),
        ],
        learnSkills: [
          SkillModel(
            id: '4',
            name: 'Spanish',
            level: 1,
            category: 'Language',
            learnable: true,
          ),
        ],
        availabilitySlots: ['tuesday-evening'],
      ),
      ProfileData(
        user: AppUser(
          id: 'candidate-3',
          name: 'Emily Chen',
          email: 'emily@example.com',
          bio:
              'Professional pianist and music producer. Teaching piano for 8+ years. Want to improve my Spanish conversation.',
          trustScore: 95,
          credits: 100,
          verified: true,
        ),
        teachSkills: [
          SkillModel(
            id: '6',
            name: 'Piano',
            level: 7,
            category: 'Music',
            teachable: true,
          ),
          SkillModel(
            id: '1',
            name: 'Guitar',
            level: 7,
            category: 'Music',
            teachable: true,
          ),
        ],
        learnSkills: [
          SkillModel(
            id: '4',
            name: 'Spanish',
            level: 1,
            category: 'Language',
            learnable: true,
          ),
        ],
        availabilitySlots: ['wednesday-evening', 'sunday-afternoon'],
      ),
    ].take(limit).toList();
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
