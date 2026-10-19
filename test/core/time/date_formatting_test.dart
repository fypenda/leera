import 'package:english_practice/core/time/date_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats weekday, month, day and year', () {
    expect(formatLongDate(DateTime(2026, 10, 5)), 'Monday, October 5, 2026');
    expect(formatLongDate(DateTime(2027, 1, 31)), 'Sunday, January 31, 2027');
  });
}
