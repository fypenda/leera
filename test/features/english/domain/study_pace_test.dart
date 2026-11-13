import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/time/calendar_date.dart';
import 'package:leera/features/english/domain/study_pace.dart';

void main() {
  // Friday 13 November 2026: its week starts on Monday the 9th.
  final today = CalendarDate(2026, 11, 13);

  test('a week makes a session a day chosen, and a review on most', () {
    const plan = WeeklyPlan(minutes: 20, days: {1, 2, 3, 4, 5});
    expect(plan.sessions, 5);
    expect(plan.reviews, 3);
    expect(const WeeklyPlan(minutes: 10, days: {6}).reviews, 1);
    expect(const WeeklyPlan(minutes: 10, days: {}).reviews, 0);
    expect(WeeklyPlan.standard.practisesOn(today), isTrue);
    expect(
      WeeklyPlan.standard.practisesOn(CalendarDate(2026, 11, 14)),
      isFalse,
    );
  });

  test('a week is named by its days', () {
    expect(WeeklyPlan.standard.daysLabel, 'Mon–Fri');
    expect(
      const WeeklyPlan(minutes: 30, days: {1, 2, 3, 4, 5, 6, 7}).daysLabel,
      'Every day',
    );
    expect(const WeeklyPlan(minutes: 30, days: {7, 6}).daysLabel, 'Weekends');
    expect(const WeeklyPlan(minutes: 30, days: {1, 4, 6}).daysLabel, '3 days');
  });

  test('a week is stored, and read back', () {
    const plan = WeeklyPlan(minutes: 30, days: {6, 1, 3});
    expect(plan.encode(), '30|1,3,6');
    expect(WeeklyPlan.decode(plan.encode()), plan);
    expect(WeeklyPlan.decode(null), isNull);
    expect(WeeklyPlan.decode(''), isNull);
    expect(WeeklyPlan.decode('25|1,2'), isNull);
    expect(WeeklyPlan.decode('20|'), isNull);
    expect(WeeklyPlan.decode('20|0,3,9'), const WeeklyPlan(minutes: 20, days: {3}));
  });

  test('an old pace still gives a week', () {
    expect(
      WeeklyPlan.stored(pace: 'light'),
      const WeeklyPlan(minutes: 10, days: {1, 3, 5}),
    );
    expect(WeeklyPlan.stored(pace: 'regular'), WeeklyPlan.standard);
    expect(WeeklyPlan.stored(plan: '30|6,7', pace: 'regular')?.daysLabel, 'Weekends');
    expect(WeeklyPlan.stored(), isNull);
  });

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
