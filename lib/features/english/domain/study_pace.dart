import '../../../core/time/calendar_date.dart';

/// How much time the person gives Leera, and the week it makes.
enum StudyPace {
  light(10, sessions: 3, reviews: 2),
  regular(20, sessions: 5, reviews: 3),
  intensive(30, sessions: 7, reviews: 5);

  const StudyPace(
    this.minutesADay, {
    required this.sessions,
    required this.reviews,
  });

  final int minutesADay;

  /// Sessions to finish each week.
  final int sessions;

  /// Days with a vocabulary review each week.
  final int reviews;

  String get label => switch (this) {
    light => '$minutesADay minutes a day',
    regular => '$minutesADay minutes a day',
    intensive => '$minutesADay minutes or more',
  };

  String get detail => switch (this) {
    light => 'A topic every other day',
    regular => 'A topic most days',
    intensive => 'A topic every day, and more',
  };

  static StudyPace? fromName(String? name) {
    for (final pace in values) {
      if (pace.name == name) return pace;
    }
    return null;
  }
}

/// The days a review round was finished, as stored: `YYYY-MM-DD`, comma
/// separated. Unreadable entries are skipped.
Set<CalendarDate> parseReviewDays(String? stored) => {
  for (final part in (stored ?? '').split(','))
    if (part.trim().isNotEmpty)
      if (_tryParse(part.trim()) case final day?) day,
};

CalendarDate? _tryParse(String text) {
  try {
    return CalendarDate.parse(text);
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}

/// [days] with [today] added, keeping only the last 14 days: enough for
/// this week and the last.
String recordReviewDay(Set<CalendarDate> days, CalendarDate today) {
  final kept = {
    for (final day in {...days, today})
      if (day.daysUntil(today) >= 0 && day.daysUntil(today) < 14) day,
  }.toList()..sort((a, b) => a.daysUntil(b));
  return [for (final day in kept) day.toIso8601()].join(',');
}

/// How many of [days] fall in the week of [today] (Monday to Sunday).
int reviewDaysThisWeek(Set<CalendarDate> days, CalendarDate today) {
  final monday = today.startOfWeek;
  return days.where((day) {
    final offset = monday.daysUntil(day);
    return offset >= 0 && offset < DateTime.daysPerWeek;
  }).length;
}
