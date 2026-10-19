import 'package:drift/drift.dart';

import '../time/calendar_date.dart';

/// Stores an instant as microseconds since the Unix epoch, and always reads
/// it back as a UTC [DateTime].
class UtcInstantConverter extends TypeConverter<DateTime, int> {
  const UtcInstantConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMicrosecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.microsecondsSinceEpoch;
}

/// Stores a [CalendarDate] as `YYYY-MM-DD` text.
class CalendarDateConverter extends TypeConverter<CalendarDate, String> {
  const CalendarDateConverter();

  @override
  CalendarDate fromSql(String fromDb) => CalendarDate.parse(fromDb);

  @override
  String toSql(CalendarDate value) => value.toIso8601();
}
