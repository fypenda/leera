import 'package:english_practice/core/time/calendar_date.dart';
import 'package:english_practice/features/english/domain/practice_session.dart';
import 'package:english_practice/features/english/domain/practice_stats.dart';
import 'package:english_practice/features/english/domain/restitution_format.dart';
import 'package:flutter_test/flutter_test.dart';

/// A session completed at noon, local time, on [day] of October 2026.
PracticeSession _completedOn(int day, {String? id}) {
  final at = DateTime(2026, 10, day, 12).toUtc();
  return PracticeSession(
    id: id ?? 'done-$day',
    topicId: 'suez-canal',
    format: RestitutionFormat.voiceNote,
    status: PracticeSessionStatus.completed,
    startedAt: at,
    updatedAt: at,
    completedAt: at,
  );
}

final _inProgress = PracticeSession(
  id: 'open',
  topicId: 'jazz',
  format: RestitutionFormat.shortEssay,
  status: PracticeSessionStatus.researching,
  startedAt: DateTime.utc(2026, 10, 9),
  updatedAt: DateTime.utc(2026, 10, 9),
);

final _friday = CalendarDate(2026, 10, 9);

void main() {
  test('with no session, nothing is counted', () {
    final stats = PracticeStats(const [], _friday);

    expect(stats.streak, 0);
    expect(stats.completedThisMonth, 0);
    expect(stats.latest, isNull);
    expect(stats.thisWeek.first, CalendarDate(2026, 10, 5));
    expect(stats.thisWeek.last, CalendarDate(2026, 10, 11));
  });

  test('only completed sessions count, the latest first', () {
    final stats = PracticeStats(
      [_completedOn(6), _inProgress, _completedOn(8)],
      _friday,
    );

    expect(stats.completed.map((s) => s.id), ['done-8', 'done-6']);
    expect(stats.latest!.id, 'done-8');
    expect(stats.practisedOn(CalendarDate(2026, 10, 9)), isFalse);
    expect(stats.practisedOn(CalendarDate(2026, 10, 8)), isTrue);
  });

  test('the streak counts consecutive days up to today', () {
    final stats = PracticeStats(
      [_completedOn(5), _completedOn(7), _completedOn(8), _completedOn(9)],
      _friday,
    );
    expect(stats.streak, 3);
  });

  test('a streak that reached yesterday still counts today', () {
    final stats = PracticeStats([_completedOn(7), _completedOn(8)], _friday);
    expect(stats.streak, 2);
  });

  test('a day missed ends the streak', () {
    final stats = PracticeStats([_completedOn(6), _completedOn(7)], _friday);
    expect(stats.streak, 0);
  });

  test('two sessions on one day count as one day', () {
    final stats = PracticeStats(
      [_completedOn(9), _completedOn(9, id: 'again')],
      _friday,
    );
    expect(stats.streak, 1);
    expect(stats.completedThisMonth, 2);
  });

  test('sessions of another month are not counted in this one', () {
    final september = DateTime(2026, 9, 30, 12).toUtc();
    final stats = PracticeStats([
      _completedOn(1),
      PracticeSession(
        id: 'september',
        topicId: 'jazz',
        format: RestitutionFormat.debate,
        status: PracticeSessionStatus.completed,
        startedAt: september,
        updatedAt: september,
        completedAt: september,
      ),
    ], _friday);

    expect(stats.completedThisMonth, 1);
  });
}
