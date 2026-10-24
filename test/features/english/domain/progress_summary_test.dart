import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/time/calendar_date.dart';
import 'package:leera/features/english/domain/feedback_history.dart';
import 'package:leera/features/english/domain/progress_summary.dart';

import '../../../support/fake_ai.dart';

void main() {
  // Wednesday 7 October 2026: its week starts on Monday the 5th.
  final today = CalendarDate(2026, 10, 7);

  test('eight weeks of scores, the oldest first, empty weeks included', () {
    final weeks = weeklyScores([
      // This week, twice: the mean of both (both 7.6).
      sampleFeedback(createdAt: DateTime(2026, 10, 5, 9).toUtc()),
      sampleFeedback(createdAt: DateTime(2026, 10, 7, 9).toUtc()),
      // Three weeks before.
      sampleFeedback(createdAt: DateTime(2026, 9, 18, 9).toUtc()),
      // Too old to be shown.
      sampleFeedback(createdAt: DateTime(2026, 8, 1, 9).toUtc()),
    ], today);

    expect(weeks, hasLength(8));
    expect(weeks.first.monday, CalendarDate(2026, 8, 17));
    expect(weeks.last.monday, CalendarDate(2026, 10, 5));
    expect(weeks.last.average, closeTo(7.6, 0.001));
    expect(weeks[4].monday, CalendarDate(2026, 9, 14));
    expect(weeks[4].average, closeTo(7.6, 0.001));
    expect(
      [for (final (i, week) in weeks.indexed) if (i != 4 && i != 7) week.average],
      everyElement(isNull),
    );
  });

  test('no focus area before the first correction', () {
    expect(focusArea(FeedbackHistory(const [])), isNull);
  });

  test('the focus area is the weakest criterion and the commonest mistake', () {
    final focus = focusArea(
      FeedbackHistory([
        sampleFeedback(tags: ['false-friends']),
        sampleFeedback(tags: ['false-friends']),
      ]),
    )!;

    // The sample scores naturalness 6, its lowest.
    expect(focus.criterion, 'naturalness');
    expect(focus.average, 6);
    expect(focus.mistake, 'false friends');
  });

  test('a mistake made once is no focus', () {
    expect(focusArea(FeedbackHistory([sampleFeedback()]))!.mistake, isNull);
  });

  test('time spoken reads in minutes, then hours', () {
    expect(formatSpokenTime(const Duration(seconds: 40)), '0m');
    expect(formatSpokenTime(const Duration(minutes: 41, seconds: 59)), '41m');
    expect(formatSpokenTime(const Duration(minutes: 65)), '1h 05m');
  });
}
