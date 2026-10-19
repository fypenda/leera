import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:elora/core/database/app_database.dart';
import 'package:elora/features/english/data/drift_practice_session_repository.dart';
import 'package:elora/features/english/domain/practice_session.dart';
import 'package:elora/features/english/domain/practice_session_repository.dart';
import 'package:elora/features/english/domain/restitution_format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_ai.dart';
import '../../../support/fake_clock.dart';

final _start = DateTime(2026, 10, 5, 10);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeClock clock;
  late AppDatabase db;
  late PracticeSessionRepository repository;
  var nextId = 0;

  PracticeSessionRepository repositoryOn(AppDatabase database) =>
      DriftPracticeSessionRepository(
        database,
        clock: clock.call,
        newId: () => 'session-${++nextId}',
      );

  setUp(() {
    nextId = 0;
    clock = FakeClock(_start);
    db = AppDatabase(NativeDatabase.memory());
    repository = repositoryOn(db);
  });
  tearDown(() => db.close());

  test('a new session is stored researching, from now', () async {
    final session = await repository.start(
      topicId: 'suez-canal',
      format: RestitutionFormat.voiceNote,
    );

    final stored = (await repository.getSession(session.id))!;
    expect(stored.topicId, 'suez-canal');
    expect(stored.format, RestitutionFormat.voiceNote);
    expect(stored.status, PracticeSessionStatus.researching);
    expect(stored.notes, '');
    expect(stored.rerolled, isFalse);
    expect(stored.startedAt, _start.toUtc());
    expect(stored.startedAt.isUtc, isTrue);
    expect(stored.completedAt, isNull);
  });

  test('a whole session is kept, step by step', () async {
    final session = await repository.start(
      topicId: 'suez-canal',
      format: RestitutionFormat.shortEssay,
    );

    clock.advance(const Duration(minutes: 5));
    await repository.saveNotes(session.id, 'Opened in 1869');
    clock.advance(const Duration(minutes: 15));
    await repository.startPresenting(session.id);
    clock.advance(const Duration(minutes: 10));
    await repository.complete(
      session.id,
      presentation: 'The canal opened in 1869.',
    );

    final stored = (await repository.getSession(session.id))!;
    expect(stored.notes, 'Opened in 1869');
    expect(stored.status, PracticeSessionStatus.completed);
    expect(stored.presentation, 'The canal opened in 1869.');
    expect(stored.completedAt, _start.add(const Duration(minutes: 30)).toUtc());
  });

  test('the reroll is stored, and refused a second time', () async {
    final session = await repository.start(
      topicId: 'suez-canal',
      format: RestitutionFormat.voiceNote,
    );

    await repository.reroll(
      session.id,
      topicId: 'jazz',
      format: RestitutionFormat.keyFacts,
    );
    final stored = (await repository.getSession(session.id))!;
    expect(stored.topicId, 'jazz');
    expect(stored.format, RestitutionFormat.keyFacts);
    expect(stored.rerolled, isTrue);

    await expectLater(
      repository.reroll(
        session.id,
        topicId: 'vaccines',
        format: RestitutionFormat.debate,
      ),
      throwsStateError,
    );
    expect((await repository.getSession(session.id))!.topicId, 'jazz');
  });

  test('sessions are listed the latest started first', () async {
    await repository.start(topicId: 'a', format: RestitutionFormat.debate);
    clock.advance(const Duration(days: 1));
    await repository.start(topicId: 'b', format: RestitutionFormat.debate);

    final sessions = await repository.watchSessions().first;
    expect(sessions.map((s) => s.topicId), ['b', 'a']);
  });

  test('those watching a session see each change', () async {
    final session = await repository.start(
      topicId: 'suez-canal',
      format: RestitutionFormat.voiceNote,
    );
    final seen = <PracticeSessionStatus?>[];
    final subscription = repository
        .watchSession(session.id)
        .listen((s) => seen.add(s?.status));
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await repository.startPresenting(session.id);
    await pumpEventQueue();
    await repository.complete(session.id);
    await pumpEventQueue();

    expect(seen, [
      PracticeSessionStatus.researching,
      PracticeSessionStatus.presenting,
      PracticeSessionStatus.completed,
    ]);
  });

  test('a session that does not exist is reported', () async {
    expect(await repository.getSession('nobody'), isNull);
    await expectLater(
      repository.saveNotes('nobody', 'x'),
      throwsA(isA<PracticeSessionNotFoundException>()),
    );
    await expectLater(
      repository.complete('nobody'),
      throwsA(isA<PracticeSessionNotFoundException>()),
    );
  });

  test('a completed session refuses further changes', () async {
    final session = await repository.start(
      topicId: 'suez-canal',
      format: RestitutionFormat.voiceNote,
    );
    await repository.complete(session.id);

    await expectLater(repository.saveNotes(session.id, 'x'), throwsStateError);
    await expectLater(repository.complete(session.id), throwsStateError);
  });

  test('sessions survive closing and reopening the database', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sessions_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    final session = await repositoryOn(
      first,
    ).start(topicId: 'jazz', format: RestitutionFormat.tedIntro);
    await repositoryOn(first).saveNotes(session.id, 'Congo Square');
    await first.close();

    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    final stored = (await repositoryOn(reopened).getSession(session.id))!;
    expect(stored.notes, 'Congo Square');
    expect(stored.format, RestitutionFormat.tedIntro);
  });
  group('feedback', () {
    test('a completed session keeps its correction', () async {
      final session = await repository.start(
        topicId: 'suez-canal',
        format: RestitutionFormat.shortEssay,
      );
      await repository.complete(session.id, presentation: 'It permits to ships');
      expect(await repository.watchFeedbacks().first, isEmpty);

      await repository.saveFeedback(session.id, sampleFeedback());

      final stored = (await repository.watchFeedbacks().first)[session.id]!;
      expect(stored.estimatedLevel, 'B2+');
      expect(stored.headline, 'Clear and well built 🎉');
      expect(stored.corrections.single.fix, 'allows ships');
      expect(stored.vocabulary.single.expression, 'chokepoint');
      expect(stored.createdAt, DateTime.utc(2026, 10, 5, 10));
    });

    test('a new correction replaces the previous one', () async {
      final session = await repository.start(
        topicId: 'jazz',
        format: RestitutionFormat.shortEssay,
      );
      await repository.complete(session.id, presentation: 'Jazz was born');
      await repository.saveFeedback(session.id, sampleFeedback(level: 'B2'));
      await repository.saveFeedback(session.id, sampleFeedback(level: 'C1'));

      final all = await repository.watchFeedbacks().first;
      expect(all, hasLength(1));
      expect(all[session.id]!.estimatedLevel, 'C1');
    });

    test('only a completed session can be corrected', () async {
      final session = await repository.start(
        topicId: 'jazz',
        format: RestitutionFormat.shortEssay,
      );

      await expectLater(
        repository.saveFeedback(session.id, sampleFeedback()),
        throwsStateError,
      );
      await expectLater(
        repository.saveFeedback('nobody', sampleFeedback()),
        throwsA(isA<PracticeSessionNotFoundException>()),
      );
      expect(await repository.watchFeedbacks().first, isEmpty);
    });

    test('the corrections are watched as they arrive', () async {
      final session = await repository.start(
        topicId: 'jazz',
        format: RestitutionFormat.shortEssay,
      );
      await repository.complete(session.id, presentation: 'Jazz was born');

      final seen = repository
          .watchFeedbacks()
          .map((all) => all.length)
          .take(2)
          .toList();
      await pumpEventQueue();
      await repository.saveFeedback(session.id, sampleFeedback());

      expect(await seen, [0, 1]);
    });
  });
  group('recordings', () {
    test('a take is kept with the session, and replaced by the next', () async {
      final session = await repository.start(
        topicId: 'jazz',
        format: RestitutionFormat.voiceNote,
      );
      expect(await repository.watchRecordings().first, isEmpty);

      final none = await repository.saveRecording(
        session.id,
        fileName: 'take-1.m4a',
        duration: const Duration(seconds: 84),
      );
      expect(none, isNull);
      final first = (await repository.watchRecordings().first)[session.id]!;
      expect(first.fileName, 'take-1.m4a');
      expect(first.duration, const Duration(seconds: 84));
      expect(first.recordedAt, _start.toUtc());

      final replaced = await repository.saveRecording(
        session.id,
        fileName: 'take-2.m4a',
        duration: const Duration(seconds: 90),
      );
      expect(replaced!.fileName, 'take-1.m4a');
      final all = await repository.watchRecordings().first;
      expect(all, hasLength(1));
      expect(all[session.id]!.fileName, 'take-2.m4a');
    });

    test('a sent presentation is not recorded again', () async {
      final session = await repository.start(
        topicId: 'jazz',
        format: RestitutionFormat.voiceNote,
      );
      await repository.complete(session.id);

      await expectLater(
        repository.saveRecording(
          session.id,
          fileName: 'late.m4a',
          duration: const Duration(seconds: 3),
        ),
        throwsStateError,
      );
      await expectLater(
        repository.saveRecording(
          'nobody',
          fileName: 'x.m4a',
          duration: const Duration(seconds: 3),
        ),
        throwsA(isA<PracticeSessionNotFoundException>()),
      );
      expect(await repository.watchRecordings().first, isEmpty);
    });

    test('a transcript is kept, and cleared by a new take', () async {
      final session = await repository.start(
        topicId: 'jazz',
        format: RestitutionFormat.voiceNote,
      );
      await expectLater(
        repository.saveTranscript(session.id, 'nothing to read'),
        throwsStateError,
      );
      await repository.saveRecording(
        session.id,
        fileName: 'take-1.m4a',
        duration: const Duration(seconds: 30),
      );
      expect(
        (await repository.watchRecordings().first)[session.id]!.transcript,
        isNull,
      );

      await repository.saveTranscript(session.id, 'Jazz was born.');
      expect(
        (await repository.watchRecordings().first)[session.id]!.transcript,
        'Jazz was born.',
      );

      await repository.saveRecording(
        session.id,
        fileName: 'take-2.m4a',
        duration: const Duration(seconds: 40),
      );
      expect(
        (await repository.watchRecordings().first)[session.id]!.transcript,
        isNull,
      );

      // A sent recording can still be transcribed.
      await repository.complete(session.id);
      await repository.saveTranscript(session.id, '');
      expect(
        (await repository.watchRecordings().first)[session.id]!.transcript,
        '',
      );
    });

    test('only a file name and a real length are kept', () async {
      final session = await repository.start(
        topicId: 'jazz',
        format: RestitutionFormat.voiceNote,
      );

      await expectLater(
        repository.saveRecording(
          session.id,
          fileName: '/tmp/take.m4a',
          duration: const Duration(seconds: 3),
        ),
        throwsArgumentError,
      );
      await expectLater(
        repository.saveRecording(
          session.id,
          fileName: 'take.m4a',
          duration: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });
}
