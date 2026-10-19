import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/time/date_formatting.dart';

void main() {
  test('formats weekday, month, day and year', () {
    expect(formatLongDate(DateTime(2026, 10, 5)), 'Monday, October 5, 2026');
    expect(formatLongDate(DateTime(2027, 1, 31)), 'Sunday, January 31, 2027');
  });
}
