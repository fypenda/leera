import '../../../core/time/calendar_date.dart';
import 'feedback_history.dart';
import 'session_feedback.dart';

/// One week of the score chart: its Monday, and the mean of the corrections
/// received that week, or null when there were none.
typedef WeeklyScore = ({CalendarDate monday, double? average});

/// The criterion to work on: the lowest on average over the latest
/// corrections, and the mistake that comes back most, if one does.
typedef FocusArea = ({String criterion, double average, String? mistake});

/// The mean score of each of the [weeks] weeks up to the one of [today],
/// the oldest first. Weeks start on Monday, in local time.
List<WeeklyScore> weeklyScores(
  Iterable<SessionFeedback> feedbacks,
  CalendarDate today, {
  int weeks = 8,
}) {
  final firstMonday = today.startOfWeek.addDays(-7 * (weeks - 1));
  final sums = List<double>.filled(weeks, 0);
  final counts = List<int>.filled(weeks, 0);
  for (final feedback in feedbacks) {
    final days = firstMonday.daysUntil(CalendarDate.ofLocal(feedback.createdAt));
    if (days < 0) continue;
    final week = days ~/ 7;
    if (week >= weeks) continue;
    sums[week] += feedback.scores.average;
    counts[week]++;
  }
  return [
    for (var week = 0; week < weeks; week++)
      (
        monday: firstMonday.addDays(7 * week),
        average: counts[week] == 0 ? null : sums[week] / counts[week],
      ),
  ];
}

/// The weakest criterion over the [latest] corrections, or null before the
/// first one. Ties go to the first in display order.
FocusArea? focusArea(FeedbackHistory history, {int latest = 5}) {
  final recent = history.all.take(latest).toList();
  if (recent.isEmpty) return null;

  double mean(int Function(FeedbackScores scores) score) =>
      recent.map((f) => score(f.scores)).reduce((a, b) => a + b) /
      recent.length;

  final criteria = [
    ('grammar', mean((s) => s.grammar)),
    ('vocabulary', mean((s) => s.vocabulary)),
    ('naturalness', mean((s) => s.naturalness)),
    ('structure', mean((s) => s.structure)),
    ('content', mean((s) => s.content)),
  ];
  var weakest = criteria.first;
  for (final criterion in criteria.skip(1)) {
    if (criterion.$2 < weakest.$2) weakest = criterion;
  }
  final mistakes = history.recurringMistakes(limit: 1);
  return (
    criterion: weakest.$1,
    average: weakest.$2,
    mistake: mistakes.isEmpty ? null : mistakes.first.replaceAll('-', ' '),
  );
}

/// "41m", "1h 05m"; under a minute, "0m".
String formatSpokenTime(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 60) return '${minutes}m';
  return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
}
