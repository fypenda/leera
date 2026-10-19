import '../../../core/time/calendar_date.dart';
import 'practice_session.dart';

/// What a person's sessions add up to, on a given day. Always calculated
/// from the stored sessions, never stored.
class PracticeStats {
  PracticeStats(Iterable<PracticeSession> sessions, this.today)
    : completed = [
        for (final session in sessions)
          if (session.isCompleted) session,
      ]..sort((a, b) => b.completedAt!.compareTo(a.completedAt!)),
      _days = {
        for (final session in sessions)
          if (session.isCompleted) CalendarDate.ofLocal(session.completedAt!),
      };

  /// Completed sessions, the latest first.
  final List<PracticeSession> completed;
  final CalendarDate today;

  /// The local days with at least one completed session.
  final Set<CalendarDate> _days;

  bool practisedOn(CalendarDate day) => _days.contains(day);

  /// The days of the current week, Monday first.
  List<CalendarDate> get thisWeek => [
    for (var offset = 0; offset < DateTime.daysPerWeek; offset++)
      today.startOfWeek.addDays(offset),
  ];

  /// Consecutive days with a completed session, up to today. A streak that
  /// reached yesterday still counts until today is over.
  int get streak {
    var day = practisedOn(today) ? today : today.addDays(-1);
    var days = 0;
    while (practisedOn(day)) {
      days++;
      day = day.addDays(-1);
    }
    return days;
  }

  /// Completed sessions in the calendar month of [today].
  int get completedThisMonth => completed.where((session) {
    final day = CalendarDate.ofLocal(session.completedAt!);
    return day.year == today.year && day.month == today.month;
  }).length;

  /// The latest completed session, if any.
  PracticeSession? get latest => completed.isEmpty ? null : completed.first;
}
