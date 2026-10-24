import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/time/calendar_date.dart';
import 'package:leera/core/time/date_formatting.dart';

void main() {
  test('formats weekday, month, day and year', () {
    expect(formatLongDate(DateTime(2026, 10, 5)), 'Monday, October 5, 2026');
    expect(formatLongDate(DateTime(2027, 1, 31)), 'Sunday, January 31, 2027');
  });

  test('a day is told relative to today', () {
    final today = CalendarDate(2026, 10, 24); // a Saturday
    expect(formatRelativeDay(today, today), 'Today');
    expect(formatRelativeDay(CalendarDate(2026, 10, 23), today), 'Yesterday');
    expect(formatRelativeDay(CalendarDate(2026, 10, 19), today), 'Monday');
    expect(formatRelativeDay(CalendarDate(2026, 10, 17), today), 'Oct 17');
  });
}
