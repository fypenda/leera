import 'package:drift/drift.dart';

/// The themes the daily topic is drawn from, one row each. No row: every
/// theme.
@DataClassName('PreferredThemeRow')
class PreferredThemes extends Table {
  TextColumn get theme => text()();

  @override
  Set<Column> get primaryKey => {theme};

  @override
  List<String> get customConstraints => ['CHECK (length(trim(theme)) > 0)'];
}
