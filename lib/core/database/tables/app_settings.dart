import 'package:drift/drift.dart';

/// Small settings of the app on this device, by key: whether the welcome
/// was done, the level the person gave. See `lib/core/settings/`.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  List<String> get customConstraints => ['CHECK (length(trim(key)) > 0)'];
}
