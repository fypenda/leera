import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocara/features/english/domain/feedback_codec.dart';
import 'package:vocara/features/english/domain/session_feedback.dart';

import '../../../support/fake_ai.dart';

/// The JSON the backend sends, as in backend/README.md.
Map<String, Object?> _backendJson() => {
  'promptVersion': 'feedback-v1',
  'model': 'claude-sonnet-5-5',
  'createdAt': '2026-10-05T10:00:00Z',
  'estimatedLevel': 'B2+',
  'headline': 'Clear and well built',
  'summary': 'Good structure.',
  // Typed as the decoded JSON is, so a test can put a wrong type in.
  'scores': <String, Object?>{
    'grammar': 7,
    'vocabulary': 8,
    'naturalness': 6,
    'structure': 9,
    'content': 8,
  },
  'corrections': [
    {
      'kind': 'naturalness',
      'original': 'It permits to ships to avoid Africa',
      'corrected': 'It allows ships to avoid Africa',
      'mistake': 'permits to ships',
      'fix': 'allows ships',
      'explanation': 'A calque from French.',
      'tag': 'false-friends',
    },
  ],
  'vocabulary': [
    {
      'expression': 'chokepoint',
      'meaning': 'a narrow passage',
      'example': 'Suez is a chokepoint.',
    },
  ],
  'followUpQuestions': ['Why?'],
  'recurringMistakesSeen': ['prepositions'],
  'aFieldAddedLater': true,
};

void main() {
  test('the backend JSON is read, unknown fields ignored', () {
    final feedback = decodeFeedback(_backendJson());

    expect(feedback.model, 'claude-sonnet-5-5');
    expect(feedback.createdAt, DateTime.utc(2026, 10, 5, 10));
    expect(feedback.createdAt.isUtc, isTrue);
    expect(feedback.estimatedLevel, 'B2+');
    expect(feedback.scores.structure, 9);
    final correction = feedback.corrections.single;
    expect(correction.kind, CorrectionKind.naturalness);
    expect(correction.mistake, 'permits to ships');
    expect(correction.tag, 'false-friends');
    expect(feedback.vocabulary.single.example, 'Suez is a chokepoint.');
    expect(feedback.followUpQuestions, ['Why?']);
    expect(feedback.recurringMistakesSeen, ['prepositions']);
  });

  test('a feedback survives encoding and decoding, through text', () {
    final original = sampleFeedback(tags: ['articles', 'tenses']);

    final copy = decodeFeedback(
      jsonDecode(jsonEncode(encodeFeedback(original))),
    );

    expect(encodeFeedback(copy), encodeFeedback(original));
  });

  test('optional texts may be missing', () {
    final json = _backendJson();
    final correction =
        (json['corrections']! as List).single as Map<String, Object?>;
    correction
      ..remove('mistake')
      ..remove('fix')
      ..remove('tag');
    ((json['vocabulary']! as List).single as Map).remove('example');

    final feedback = decodeFeedback(json);

    expect(feedback.corrections.single.mistake, '');
    expect(feedback.corrections.single.tag, '');
    expect(feedback.vocabulary.single.example, '');
  });

  group('what cannot be shown is refused', () {
    final cases = <String, void Function(Map<String, Object?>)>{
      'not an object': (json) {},
      'a missing headline': (json) => json.remove('headline'),
      'a blank headline': (json) => json['headline'] = '  ',
      'an unknown level': (json) => json['estimatedLevel'] = 'Z9',
      'a score out of range': (json) =>
          (json['scores']! as Map)['grammar'] = 11,
      'a score that is not whole': (json) =>
          (json['scores']! as Map)['grammar'] = 7.5,
      'a date that is not one': (json) => json['createdAt'] = 'yesterday',
      'corrections that are not a list': (json) => json['corrections'] = 'x',
      'a question that is not text': (json) => json['followUpQuestions'] = [1],
    };
    for (final MapEntry(key: name, value: breakIt) in cases.entries) {
      test(name, () {
        final json = _backendJson();
        breakIt(json);
        final Object input = name == 'not an object' ? ['a list'] : json;

        expect(() => decodeFeedback(input), throwsFormatException);
      });
    }
  });

  test('the level reached is measured against C1', () {
    expect(progressTowardsC1('A2'), 0);
    expect(progressTowardsC1('B2'), closeTo(0.6, 1e-9));
    expect(progressTowardsC1('C1'), 1);
    expect(progressTowardsC1('C2'), 1);
    expect(progressTowardsC1('unknown'), 0);
  });
}
