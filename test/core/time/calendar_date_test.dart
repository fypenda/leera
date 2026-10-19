import 'package:english_practice/core/time/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  weekTests();

  test('rejects dates that do not exist', () {
    expect(() => CalendarDate(2026, 2, 30), throwsArgumentError);
    expect(() => CalendarDate(2026, 13, 1), throwsArgumentError);
    expect(() => CalendarDate(2026, 10, 0), throwsArgumentError);
    expect(CalendarDate(2028, 2, 29).day, 29);
  });

  test('takes the local calendar day of an instant', () {
    final lateEvening = DateTime(2026, 10, 5, 23, 59);

    expect(CalendarDate.ofLocal(lateEvening), CalendarDate(2026, 10, 5));
    expect(
      CalendarDate.ofLocal(lateEvening.toUtc()),
      CalendarDate(2026, 10, 5),
    );
  });

  test('counts whole days between dates', () {
    final today = CalendarDate(2026, 10, 5);

    expect(today.daysUntil(today), 0);
    expect(today.daysUntil(CalendarDate(2026, 10, 9)), 4);
    expect(today.daysUntil(CalendarDate(2026, 10, 4)), -1);
    // Across the end of daylight saving time in most of Europe.
    expect(CalendarDate(2026, 10, 24).daysUntil(CalendarDate(2026, 10, 26)), 2);
    expect(CalendarDate(2026, 12, 31).daysUntil(CalendarDate(2027, 1, 1)), 1);
  });

  test('orders and compares by date', () {
    final earlier = CalendarDate(2026, 10, 5);
    final later = CalendarDate(2026, 11, 1);

    expect(earlier.compareTo(later), isNegative);
    expect(later.compareTo(earlier), isPositive);
    expect(earlier, CalendarDate(2026, 10, 5));
    expect(earlier.hashCode, CalendarDate(2026, 10, 5).hashCode);
  });

  test('round-trips through YYYY-MM-DD text', () {
    expect(CalendarDate(2026, 1, 9).toIso8601(), '2026-01-09');
    expect(CalendarDate.parse('2026-01-09'), CalendarDate(2026, 1, 9));
    expect(() => CalendarDate.parse('09/01/2026'), throwsFormatException);
    expect(() => CalendarDate.parse('2026-02-30'), throwsArgumentError);
  });
}

void weekTests() {
  test('knows the day of the week, Monday first', () {
    expect(CalendarDate(2026, 10, 5).weekday, 1);
    expect(CalendarDate(2026, 10, 10).weekday, 6);
    expect(CalendarDate(2026, 10, 11).weekday, 7);
  });

  test('adds and subtracts days across months, years and clock changes', () {
    expect(CalendarDate(2026, 10, 5).addDays(0), CalendarDate(2026, 10, 5));
    expect(CalendarDate(2026, 10, 31).addDays(1), CalendarDate(2026, 11, 1));
    expect(CalendarDate(2027, 1, 1).addDays(-1), CalendarDate(2026, 12, 31));
    expect(CalendarDate(2028, 2, 28).addDays(1), CalendarDate(2028, 2, 29));
    // Across the end of daylight saving time in most of Europe.
    expect(CalendarDate(2026, 10, 24).addDays(2), CalendarDate(2026, 10, 26));
  });

  test('weeks start on Monday and end on Sunday', () {
    final monday = CalendarDate(2026, 10, 5);

    for (var offset = 0; offset < 7; offset++) {
      expect(monday.addDays(offset).startOfWeek, monday);
    }
    expect(monday.addDays(-1).startOfWeek, CalendarDate(2026, 9, 28));
    expect(monday.addDays(7).startOfWeek, CalendarDate(2026, 10, 12));
    // A week that straddles two years.
    expect(CalendarDate(2027, 1, 1).startOfWeek, CalendarDate(2026, 12, 28));
  });
}
