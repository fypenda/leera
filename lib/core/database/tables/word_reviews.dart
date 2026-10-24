import 'package:drift/drift.dart';

import '../converters.dart';

/// Where each kept word stands in its review: one row per word reviewed at
/// least once. A word with no row has never been reviewed.
///
/// `expression_key` is the expression trimmed and in lower case, the way
/// words kept are told apart. `box` is the step reached (0 after a miss);
/// `due_on` the local day it should come back.
@DataClassName('WordReviewRow')
class WordReviews extends Table {
  TextColumn get expressionKey => text()();
  IntColumn get box => integer()();
  TextColumn get dueOn => text().map(const CalendarDateConverter())();
  IntColumn get reviewedAt => integer().map(const UtcInstantConverter())();

  @override
  Set<Column> get primaryKey => {expressionKey};

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(expression_key)) > 0)',
    'CHECK (box >= 0)',
  ];
}
