import 'calendar_date.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Formats a calendar date as e.g. "October 5, 2026", or with [weekday] as
/// "Monday, October 5, 2026".
String formatCalendarDate(CalendarDate date, {bool weekday = false}) {
  final text = '${_months[date.month - 1]} ${date.day}, ${date.year}';
  if (!weekday) return text;
  // Only the day of the week is read, so the time zone used is irrelevant.
  final dayOfWeek = DateTime.utc(date.year, date.month, date.day).weekday;
  return '${_weekdays[dayOfWeek - 1]}, $text';
}

/// Formats [date] as e.g. "Monday, October 5, 2026".
String formatLongDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, '
    '${_months[date.month - 1]} ${date.day}, ${date.year}';

/// Formats a calendar date briefly, as e.g. "Oct 5".
String formatShortDate(CalendarDate date) =>
    '${_months[date.month - 1].substring(0, 3)} ${date.day}';

/// A day as seen from [today]: "Today", "Yesterday", the day of the week
/// within the last week ("Friday"), or else a short date ("Oct 5").
String formatRelativeDay(CalendarDate day, CalendarDate today) {
  final daysAgo = day.daysUntil(today);
  if (daysAgo == 0) return 'Today';
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo > 1 && daysAgo < 7) return _weekdays[day.weekday - 1];
  return formatShortDate(day);
}
