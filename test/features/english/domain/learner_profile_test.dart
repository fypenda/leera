import 'package:flutter_test/flutter_test.dart';
import 'package:leera/features/english/domain/learner_profile.dart';

void main() {
  test('only what is known is sent', () {
    expect(const LearnerProfile().toJson(), isEmpty);
    expect(
      const LearnerProfile(
        level: 'B2',
        levelSelfAssessed: true,
        goal: LearnerGoal.exam,
        firstLanguage: ' French ',
      ).toJson(),
      {
        'level': 'B2',
        'levelSelfAssessed': true,
        'goal': 'exam',
        'firstLanguage': 'French',
      },
    );
  });

  test('a first language the backend would refuse is left out', () {
    expect(cleanFirstLanguage('  Haitian   Creole '), 'Haitian Creole');
    expect(cleanFirstLanguage("N'Ko"), "N'Ko");
    expect(cleanFirstLanguage('Français'), 'Français');
    expect(cleanFirstLanguage(''), isNull);
    expect(cleanFirstLanguage('<script>'), isNull);
    expect(cleanFirstLanguage('x' * 41), isNull);
  });

  test('a goal is read back from its name', () {
    expect(LearnerGoal.fromName('travel'), LearnerGoal.travel);
    expect(LearnerGoal.fromName('gold'), isNull);
    expect(LearnerGoal.fromName(null), isNull);
  });
}
