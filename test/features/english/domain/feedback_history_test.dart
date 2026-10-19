import 'package:english_practice/core/time/calendar_date.dart';
import 'package:english_practice/features/english/domain/feedback_history.dart';
import 'package:english_practice/features/english/domain/session_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_ai.dart';

void main() {
  test('with no feedback, there is no level, word or recurring mistake', () {
    final history = FeedbackHistory(const []);

    expect(history.latest, isNull);
    expect(history.level, isNull);
    expect(history.recurringMistakes(), isEmpty);
    expect(history.vocabulary, isEmpty);
    expect(history.wordOf(CalendarDate(2026, 10, 5)), isNull);
  });

  test('the level is the latest one, whatever the order given', () {
    final history = FeedbackHistory([
      sampleFeedback(level: 'B2', createdAt: DateTime.utc(2026, 10, 1)),
      sampleFeedback(level: 'C1', createdAt: DateTime.utc(2026, 10, 4)),
      sampleFeedback(level: 'B2+', createdAt: DateTime.utc(2026, 10, 2)),
    ]);

    expect(history.level, 'C1');
    expect(history.all.map((f) => f.estimatedLevel), ['C1', 'B2+', 'B2']);
  });

  test('a mistake is recurring from its second time, the most frequent first',
      () {
    final history = FeedbackHistory([
      sampleFeedback(tags: ['articles', 'tenses', 'other']),
      sampleFeedback(tags: ['articles', 'prepositions', 'other', '']),
      sampleFeedback(tags: ['articles', 'tenses', 'spelling']),
    ]);

    // "other" and blank tags say nothing about a habit.
    expect(history.recurringMistakes(), ['articles', 'tenses']);
    expect(history.recurringMistakes(limit: 1), ['articles']);
  });

  test('each expression is kept once, the latest first', () {
    const newer = VocabularyItem('Chokepoint ', 'newer meaning');
    final history = FeedbackHistory([
      sampleFeedback(
        createdAt: DateTime.utc(2026, 10, 1),
        vocabulary: const [
          VocabularyItem('chokepoint', 'older meaning'),
          VocabularyItem('to bottleneck', 'to slow down'),
        ],
      ),
      sampleFeedback(createdAt: DateTime.utc(2026, 10, 3), vocabulary: [newer]),
    ]);

    expect(history.vocabulary.map((v) => v.meaning), [
      'newer meaning',
      'to slow down',
    ]);
  });

  test('the word of the day changes each day and comes back', () {
    final history = FeedbackHistory([
      sampleFeedback(
        vocabulary: const [
          VocabularyItem('a', 'first'),
          VocabularyItem('b', 'second'),
        ],
      ),
    ]);
    final monday = CalendarDate(2026, 10, 5);

    final word = history.wordOf(monday);
    expect(history.wordOf(monday), same(word));
    expect(history.wordOf(monday.addDays(1)), isNot(same(word)));
    expect(history.wordOf(monday.addDays(2)), same(word));
  });
}
