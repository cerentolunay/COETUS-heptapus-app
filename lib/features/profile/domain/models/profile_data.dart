import 'package:coetus/features/auth/domain/models/app_user.dart';

import 'skill_model.dart';

class ProfileData {
  final AppUser user;
  final List<SkillModel> teachSkills;
  final List<SkillModel> learnSkills;
  final List<String> availabilitySlots;

  const ProfileData({
    required this.user,
    required this.teachSkills,
    required this.learnSkills,
    this.availabilitySlots = const [],
  });

  ProfileData copyWith({
    AppUser? user,
    List<SkillModel>? teachSkills,
    List<SkillModel>? learnSkills,
    List<String>? availabilitySlots,
  }) {
    return ProfileData(
      user: user ?? this.user,
      teachSkills: teachSkills ?? this.teachSkills,
      learnSkills: learnSkills ?? this.learnSkills,
      availabilitySlots: availabilitySlots ?? this.availabilitySlots,
    );
  }
}
