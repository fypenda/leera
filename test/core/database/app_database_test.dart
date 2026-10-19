import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:english_practice/core/database/app_database.dart';
import 'package:english_practice/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// These tests are about the database itself rather than any table of the
// app, so they write to a scratch table created with raw SQL. It exists only in the test's own database and is not
// part of the app schema.

Future<void> _createScratchTable(AppDatabase db) =>
    db.customStatement('CREATE TABLE scratch (note TEXT NOT NULL)');

Future<void> _insertNote(AppDatabase db, String note) =>
    db.customStatement('INSERT INTO scratch (note) VALUES (?)', [note]);

Future<List<String>> _readNotes(AppDatabase db) async {
  final rows = await db.customSelect('SELECT note FROM scratch').get();
  return [for (final row in rows) row.read<String>('note')];
}

Future<int> _pragma(AppDatabase db, String name) async {
  final row = await db.customSelect('PRAGMA $name').getSingle();
  return row.data.values.single as int;
}

void main() {
  // Several tests deliberately hold more than one AppDatabase at a time, each
  // on its own connection. Drift's warning is about sharing one connection.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('in-memory database', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('is created at schema version 1 with foreign keys enforced', () async {
      expect(db.schemaVersion, 1);
      expect(await _pragma(db, 'user_version'), 1);
      expect(await _pragma(db, 'foreign_keys'), 1);
    });

    test('reads back what was written', () async {
      await _createScratchTable(db);
      await _insertNote(db, 'first');
      await _insertNote(db, 'second');

      expect(await _readNotes(db), ['first', 'second']);
    });

    test('is isolated from other in-memory databases', () async {
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);

      await _createScratchTable(db);
      await _insertNote(db, 'only here');
      await _createScratchTable(other);

      expect(await _readNotes(other), isEmpty);
    });
  });

  group('file-backed database', () {
    late Directory directory;
    late File file;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('app_db_test_');
      file = File('${directory.path}/app.sqlite');
    });
    tearDown(() => directory.delete(recursive: true));

    test('keeps its data after being closed and reopened', () async {
      final first = AppDatabase(NativeDatabase(file));
      await _createScratchTable(first);
      await _insertNote(first, 'still here');
      await first.close();

      expect(file.existsSync(), isTrue);

      final reopened = AppDatabase(NativeDatabase(file));
      addTearDown(reopened.close);

      expect(await _readNotes(reopened), ['still here']);
      expect(await _pragma(reopened, 'user_version'), 1);
    });

    test(
      'refuses an unknown schema version and leaves the data alone',
      () async {
        final current = AppDatabase(NativeDatabase(file));
        await _createScratchTable(current);
        await _insertNote(current, 'kept');
        await current.close();

        // Pretend a newer build of the app wrote this file.
        final fromTheFuture = AppDatabase(
          NativeDatabase(
            file,
            setup: (raw) => raw.execute('PRAGMA user_version = 2'),
          ),
        );
        addTearDown(fromTheFuture.close);
        await expectLater(_readNotes(fromTheFuture), throwsStateError);

        // Look at the file below Drift: version and rows are as they were left.
        late int version;
        late List<Object?> notes;
        final inspected = AppDatabase(
          NativeDatabase(
            file,
            setup: (raw) {
              version =
                  raw.select('PRAGMA user_version').single.values.single as int;
              notes = [
                for (final row in raw.select('SELECT note FROM scratch'))
                  row['note'],
              ];
            },
          ),
        );
        addTearDown(inspected.close);
        await expectLater(_readNotes(inspected), throwsStateError);

        expect(version, 2);
        expect(notes, ['kept']);
      },
    );
  });

  group('appDatabaseProvider', () {
    ProviderContainer containerWith(QueryExecutor connection) =>
        ProviderContainer(
          overrides: [databaseConnectionProvider.overrideWithValue(connection)],
        );

    test('provides one working database per container', () async {
      final container = containerWith(NativeDatabase.memory());
      addTearDown(container.dispose);

      final db = container.read(appDatabaseProvider);
      await _createScratchTable(db);
      await _insertNote(db, 'through the provider');

      expect(container.read(appDatabaseProvider), same(db));
      expect(await _readNotes(db), ['through the provider']);
    });

    test('closes the database when the container is disposed', () async {
      final container = containerWith(NativeDatabase.memory());
      final db = container.read(appDatabaseProvider);
      await _pragma(db, 'user_version');

      container.dispose();
      await pumpEventQueue();

      // Drift rejects any use of a database that has been closed.
      await expectLater(_pragma(db, 'user_version'), throwsStateError);
    });
  });
}
