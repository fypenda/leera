import 'package:drift/drift.dart';

import '../converters.dart';

/// What the person said of a word or phrasing kept from a correction: they
/// know it (left out of the review), or want to learn it. A word with no row
/// was never sorted, and is reviewed.
///
/// `expression_key` is the expression trimmed and in lower case, as in
/// `word_reviews`.
@DataClassName('WordTriageRow')
class WordTriage extends Table {
  TextColumn get expressionKey => text()();
  BoolColumn get known => boolean()();
  IntColumn get decidedAt => integer().map(const UtcInstantConverter())();

  @override
  Set<Column> get primaryKey => {expressionKey};

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(expression_key)) > 0)',
  ];
}
