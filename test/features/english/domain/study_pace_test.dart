import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/time/calendar_date.dart';
import 'package:leera/features/english/domain/study_pace.dart';

void main() {
  // Friday 13 November 2026: its week starts on Monday the 9th.
  final today = CalendarDate(2026, 11, 13);

  test('a pace is read back from its name', () {
    expect(StudyPace.fromName('regular'), StudyPace.regular);
    expect(StudyPace.fromName('lazy'), isNull);
    expect(StudyPace.regular.sessions, 5);
  });

  test('review days are recorded once, and only the last two weeks kept', () {
    final stored = recordReviewDay({
      CalendarDate(2026, 10, 1),
      CalendarDate(2026, 11, 9),
      today,
    }, today);

    expect(stored, '2026-11-09,2026-11-13');
    expect(parseReviewDays(stored), {CalendarDate(2026, 11, 9), today});
  });

  test('unreadable review days are skipped', () {
    expect(parseReviewDays(null), isEmpty);
    expect(parseReviewDays('2026-11-09,garbage,2026-02-30,'), {
      CalendarDate(2026, 11, 9),
    });
  });

  test('only the days of this week count', () {
    expect(
      reviewDaysThisWeek({
        CalendarDate(2026, 11, 8), // last Sunday
        CalendarDate(2026, 11, 9),
        CalendarDate(2026, 11, 12),
      }, today),
      2,
    );
  });
}
