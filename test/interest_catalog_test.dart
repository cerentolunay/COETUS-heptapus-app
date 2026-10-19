import 'package:coetus/features/profile/domain/onboarding/interest_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expanded catalog has unique IDs and requested interests', () {
    expect(
      interestBranches.map((b) => b.id).toSet().length,
      interestBranches.length,
    );
    expect(
      interestBranches.map((b) => b.id),
      containsAll([
        'animal_care',
        'psychology',
        'history',
        'strategy_games',
        'video_games',
        'anime',
        'travel',
        'nature',
        'camping',
        'gardening',
        'diy',
        'kitchen',
        'content_creation',
        'finance',
        'astrology',
      ]),
    );
  });

  test('approved community skill keeps its interest when collapsed', () {
    final selection = InterestSelection();
    selection.toggleBranch('community_example');
    selection.toggleSkill(
      'Astronomi',
      'Astronomi',
      branchId: 'community_example',
    );
    selection.toggleBranch('community_example');
    expect(selection.selectedInterestIds, contains('community_example'));
    expect(selection.selectedSkills.single.name, 'Astronomi');
  });
}
