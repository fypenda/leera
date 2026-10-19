/// A day on the calendar, with no time of day and no time zone.
///
/// Used for dates the user thinks of as "a day", such as a deadline. The
/// 5th of October stays the 5th of October wherever the device travels.
class CalendarDate implements Comparable<CalendarDate> {
  /// Throws an [ArgumentError] if the date does not exist (e.g. 30 February).
  CalendarDate(this.year, this.month, this.day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError('$year-$month-$day is not a calendar date.');
    }
  }

  /// The calendar date of [instant] in the device's local time zone.
  factory CalendarDate.ofLocal(DateTime instant) {
    final local = instant.toLocal();
    return CalendarDate(local.year, local.month, local.day);
  }

  /// Parses the `YYYY-MM-DD` form produced by [toIso8601].
  factory CalendarDate.parse(String text) {
    final match = _isoPattern.firstMatch(text);
    if (match == null) {
      throw FormatException('Expected a date as YYYY-MM-DD.', text);
    }
    return CalendarDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// Whole days from this date to [other]: positive when [other] is later.
  int daysUntil(CalendarDate other) {
    // Counted in UTC so daylight-saving changes cannot add or lose a day.
    return other._utcMidnight.difference(_utcMidnight).inDays;
  }

  DateTime get _utcMidnight => DateTime.utc(year, month, day);

  /// The day of the week, from 1 for Monday to 7 for Sunday.
  int get weekday => _utcMidnight.weekday;

  /// The date [days] after this one, or before it when [days] is negative.
  CalendarDate addDays(int days) {
    // Calendar arithmetic in UTC, so daylight saving cannot skip or repeat
    // a day.
    final moved = DateTime.utc(year, month, day + days);
    return CalendarDate(moved.year, moved.month, moved.day);
  }

  /// The Monday of this date's week. Weeks run from Monday to Sunday.
  CalendarDate get startOfWeek => addDays(1 - weekday);

  String toIso8601() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(CalendarDate other) => -daysUntil(other);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso8601();
}
