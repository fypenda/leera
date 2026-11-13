import 'dart:math' as math;

import '../../../core/time/calendar_date.dart';

/// The three paces the welcome offered before practice days: still read,
/// to turn a stored pace into a [WeeklyPlan].
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

/// The week the person set: minutes a day, and the days they practise
/// (Monday 1 to Sunday 7, as [DateTime.weekday]). One session on each day,
/// and a review on about two days in three.
class WeeklyPlan {
  const WeeklyPlan({required this.minutes, required this.days});

  /// The minutes offered: 10, 20, or 30 and more.
  static const minuteSteps = [10, 20, 30];

  /// Before the person chose: 20 minutes, Monday to Friday.
  static const standard = WeeklyPlan(minutes: 20, days: {1, 2, 3, 4, 5});

  final int minutes;
  final Set<int> days;

  /// Sessions to finish each week.
  int get sessions => days.length;

  /// Days with a vocabulary review each week.
  int get reviews => days.isEmpty ? 0 : math.max(1, (days.length * 0.6).round());

  bool practisesOn(CalendarDate day) => days.contains(day.weekday);

  WeeklyPlan copyWith({int? minutes, Set<int>? days}) =>
      WeeklyPlan(minutes: minutes ?? this.minutes, days: days ?? this.days);

  /// "Mon–Fri", "Every day", "Weekends", or "3 days".
  String get daysLabel {
    final sorted = days.toList()..sort();
    if (sorted.length == 7) return 'Every day';
    if (sorted.join() == '12345') return 'Mon–Fri';
    if (sorted.join() == '67') return 'Weekends';
    return sorted.length == 1 ? '1 day' : '${sorted.length} days';
  }

  /// As stored: `20|1,2,3,4,5`.
  String encode() => '$minutes|${(days.toList()..sort()).join(',')}';

  /// A stored plan, or null when there is none or it cannot be read.
  static WeeklyPlan? decode(String? stored) {
    final parts = stored?.split('|');
    if (parts == null || parts.length != 2) return null;
    final minutes = int.tryParse(parts[0]);
    final days = {
      for (final day in parts[1].split(','))
        if (int.tryParse(day) case final weekday?
            when weekday >= 1 && weekday <= 7)
          weekday,
    };
    if (minutes == null || !minuteSteps.contains(minutes) || days.isEmpty) {
      return null;
    }
    return WeeklyPlan(minutes: minutes, days: days);
  }

  /// The plan an old pace stands for.
  static WeeklyPlan fromPace(StudyPace pace) => switch (pace) {
    StudyPace.light => const WeeklyPlan(minutes: 10, days: {1, 3, 5}),
    StudyPace.regular => standard,
    StudyPace.intensive => const WeeklyPlan(
      minutes: 30,
      days: {1, 2, 3, 4, 5, 6, 7},
    ),
  };

  /// The plan stored, or else the one an old pace stands for, or null.
  static WeeklyPlan? stored({String? plan, String? pace}) =>
      decode(plan) ??
      switch (StudyPace.fromName(pace)) {
        final old? => fromPace(old),
        null => null,
      };

  @override
  bool operator ==(Object other) =>
      other is WeeklyPlan &&
      other.minutes == minutes &&
      other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
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
