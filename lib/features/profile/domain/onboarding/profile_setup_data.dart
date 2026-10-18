import '../models/skill_model.dart';

class ProfileSetupData {
  const ProfileSetupData({
    required this.displayName,
    required this.bio,
    required this.location,
    required this.photoUrl,
    required this.interests,
    required this.skills,
  });
  final String displayName, bio, location, photoUrl;
  final List<String> interests;
  final List<SkillModel> skills;
}
