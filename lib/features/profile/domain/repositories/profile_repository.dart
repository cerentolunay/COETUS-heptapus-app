import 'package:coetus/features/auth/domain/models/app_user.dart';

import '../models/profile_data.dart';
import '../models/skill_model.dart';

abstract class ProfileRepository {
  Future<ProfileData> loadProfile();
  Future<List<ProfileData>> loadDiscoverableProfiles({int limit = 50});
  Future<ProfileData> updateProfile(AppUser user);
  Future<ProfileData> saveTeachSkill(SkillModel skill);
  Future<ProfileData> deleteTeachSkill(String skillId);
  Future<ProfileData> saveLearnSkill(SkillModel skill);
  Future<ProfileData> deleteLearnSkill(String skillId);
}
