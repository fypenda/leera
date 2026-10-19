import 'package:elora/features/english/domain/practice_session.dart';
import 'package:elora/features/english/domain/restitution_format.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime.utc(2026, 10, 5, 9);
final _later = DateTime.utc(2026, 10, 5, 9, 30);

PracticeSession _researching() => PracticeSession(
  id: 'session-1',
  topicId: 'suez-canal',
  format: RestitutionFormat.voiceNote,
  status: PracticeSessionStatus.researching,
  startedAt: _start,
  updatedAt: _start,
);

void main() {
  group('a session', () {
    test('starts researching, with no notes and its reroll unused', () {
      final session = _researching();

      expect(session.notes, '');
      expect(session.presentation, isNull);
      expect(session.rerolled, isFalse);
      expect(session.canReroll, isTrue);
      expect(session.isCompleted, isFalse);
    });

    test('refuses inconsistent state', () {
      PracticeSession make({
        String id = 's',
        String topicId = 'suez-canal',
        PracticeSessionStatus status = PracticeSessionStatus.researching,
        String? presentation,
        DateTime? startedAt,
        DateTime? completedAt,
      }) => PracticeSession(
        id: id,
        topicId: topicId,
        format: RestitutionFormat.shortEssay,
        status: status,
        presentation: presentation,
        startedAt: startedAt ?? _start,
        updatedAt: _start,
        completedAt: completedAt,
      );

      expect(() => make(id: ''), throwsArgumentError);
      expect(() => make(topicId: '  '), throwsArgumentError);
      expect(() => make(presentation: '  '), throwsArgumentError);
      expect(
        () => make(startedAt: DateTime(2026, 10, 5)),
        throwsArgumentError,
        reason: 'not UTC',
      );
      expect(
        () => make(status: PracticeSessionStatus.completed),
        throwsArgumentError,
      );
      expect(() => make(completedAt: _later), throwsArgumentError);
    });
  });

  group('notes', () {
    test('are replaced, and an unchanged text changes nothing', () {
      final session = _researching();

      final noted = session.withNotes('Opened in 1869', _later);
      expect(noted.notes, 'Opened in 1869');
      expect(noted.updatedAt, _later);
      expect(identical(noted.withNotes('Opened in 1869', _later), noted), isTrue);
    });

    test('can no longer change once the session is completed', () {
      final done = _researching().completedWith(null, _later);

      expect(() => done.withNotes('Too late', _later), throwsStateError);
    });
  });

  group('the reroll', () {
    test('changes topic and format once, and starts the research again', () {
      final session = _researching().withNotes('Some notes', _start);

      final rerolled = session.rerolledTo(
        'vaccines',
        RestitutionFormat.keyFacts,
        _later,
      );

      expect(rerolled.topicId, 'vaccines');
      expect(rerolled.format, RestitutionFormat.keyFacts);
      expect(rerolled.notes, '');
      expect(rerolled.startedAt, _later);
      expect(rerolled.rerolled, isTrue);
      expect(rerolled.canReroll, isFalse);
      expect(
        () => rerolled.rerolledTo('jazz', RestitutionFormat.debate, _later),
        throwsStateError,
      );
    });

    test('is not possible once the presentation has begun', () {
      final presenting = _researching().startPresenting(_later);

      expect(presenting.canReroll, isFalse);
      expect(
        () => presenting.rerolledTo('jazz', RestitutionFormat.debate, _later),
        throwsStateError,
      );
    });
  });

  group('the steps', () {
    test('go from researching to presenting to completed', () {
      final presenting = _researching().startPresenting(_later);
      expect(presenting.status, PracticeSessionStatus.presenting);
      expect(identical(presenting.startPresenting(_later), presenting), isTrue);

      final done = presenting.completedWith('It opened in 1869.', _later);
      expect(done.status, PracticeSessionStatus.completed);
      expect(done.completedAt, _later);
      expect(done.presentation, 'It opened in 1869.');
      expect(() => done.startPresenting(_later), throwsStateError);
      expect(() => done.completedWith(null, _later), throwsStateError);
    });

    test('a blank or spoken presentation keeps no text', () {
      expect(
        _researching().completedWith(null, _later).presentation,
        isNull,
      );
      expect(
        _researching().completedWith('   ', _later).presentation,
        isNull,
      );
    });
  });
}
