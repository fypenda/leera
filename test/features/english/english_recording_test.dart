import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/router.dart';
import 'package:leera/features/english/data/practice_session_repository_provider.dart';
import 'package:leera/features/english/domain/practice_session.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/domain/session_recording.dart';
import 'package:leera/features/english/english_routes.dart';
import 'package:leera/features/english/presentation/english_feedback_page.dart';
import 'package:leera/features/english/presentation/english_page.dart';
import 'package:leera/features/english/presentation/english_topic_page.dart';

import '../../support/fake_audio.dart';
import '../../support/fake_clock.dart';
import '../../support/pump_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

/// A session ready to be presented aloud, with its page open.
Future<PracticeSession> _presenting(
  WidgetTester tester,
  ProviderContainer container, {
  RestitutionFormat format = RestitutionFormat.voiceNote,
}) async {
  final repository = container.read(practiceSessionRepositoryProvider);
  final session = await runInApp(
    tester,
    () => repository.start(topicId: 'jazz', format: format),
  );
  await runInApp(tester, () => repository.startPresenting(session.id));
  container.read(routerProvider).goNamed(
    englishRestitutionRouteName,
    pathParameters: {englishSessionParameter: session.id},
  );
  await settle(tester);
  return session;
}

Future<Map<String, SessionRecording>> _stored(
  WidgetTester tester,
  ProviderContainer container,
) => runInApp(
  tester,
  () => container
      .read(practiceSessionRepositoryProvider)
      .watchRecordings()
      .first,
);

/// As if the take had run to [elapsed].
Future<void> _speak(
  WidgetTester tester,
  FakeVoiceRecorder recorder,
  Duration elapsed,
) async {
  recorder.emit(elapsed);
  await settle(tester);
}

String _recordingTime(WidgetTester tester) => tester
    .widget<Text>(_key('recording-time'))
    .textSpan!
    .toPlainText();

bool _canSend(WidgetTester tester) =>
    tester.widget<FilledButton>(_key('send-for-feedback')).onPressed != null;

void main() {
  for (final (name, size) in [
    ('iPad', iPadLandscape),
    ('a phone', iPhonePortrait),
  ]) {
    appTest('a spoken presentation is recorded, kept and sent, on $name', (
      tester,
    ) async {
      final recorder = FakeVoiceRecorder();
      final player = FakeAudioPlayback();
      final clock = FakeClock(DateTime(2026, 10, 5, 10));
      final container = await pumpEnglishApp(
        tester,
        size,
        clock: clock.call,
        recorder: recorder,
        player: player,
      );
      final session = await _presenting(tester, container);

      // Nothing recorded, nothing to send.
      expect(_key('start-recording'), findsOneWidget);
      expect(_canSend(tester), isFalse);
      expect(recorder.permissionRequests, 0);

      await _tap(tester, _key('start-recording'));
      expect(recorder.permissionRequests, 1);
      expect(recorder.started.single, startsWith('/recordings/${session.id}-'));
      expect(find.text('🔴 Recording'), findsOneWidget);
      expect(_canSend(tester), isFalse);

      await _speak(tester, recorder, const Duration(seconds: 50));
      expect(_recordingTime(tester), '0:50 / 2:00');

      await _tap(tester, _key('pause-recording'));
      expect(recorder.paused, isTrue);
      expect(find.text('⏸️ Paused'), findsOneWidget);
      await _tap(tester, _key('resume-recording'));
      expect(recorder.paused, isFalse);

      await _speak(tester, recorder, const Duration(seconds: 84));
      await _tap(tester, _key('finish-recording'));
      expect(tester.takeException(), isNull);

      final kept = (await _stored(tester, container))[session.id]!;
      expect(kept.duration, const Duration(seconds: 84));
      expect('/recordings/${kept.fileName}', recorder.started.single);
      expect(_key('recording-player'), findsOneWidget);
      expect(find.text('0:00 / 1:24'), findsOneWidget);
      expect(_canSend(tester), isTrue);

      // Listening to it.
      await _tap(tester, _key('play-recording'));
      expect(player.played.single, recorder.started.single);
      player.moveTo(const Duration(seconds: 12));
      await settle(tester);
      expect(find.text('0:12 / 1:24'), findsOneWidget);
      await _tap(tester, _key('play-recording'));
      expect(player.pauses, 1);

      // Sent: heard, then kept for correction (the backend is out of reach
      // in tests).
      await tester.ensureVisible(_key('send-for-feedback'));
      await tester.pumpAndSettle();
      await tester.tap(_key('send-for-feedback'));
      await pumpUntil(tester, _key('feedback-failed'));
      expect(find.byType(EnglishFeedbackPage), findsOneWidget);
      expect(_key('recording-player'), findsOneWidget);
      expect(_key('sent-transcript'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _tap(tester, _key('feedback-done'));
      expect(find.byType(EnglishPage), findsOneWidget);
      expect(find.text('Spoken · 1:24 · Today'), findsOneWidget);
    });
  }

  appTest('recording again replaces the take, and its file', (tester) async {
    final recorder = FakeVoiceRecorder();
    final files = FakeRecordingFiles();
    final clock = FakeClock(DateTime(2026, 10, 5, 10));
    final container = await pumpEnglishApp(
      tester,
      iPadLandscape,
      clock: clock.call,
      recorder: recorder,
      recordingFiles: files,
    );
    final session = await _presenting(tester, container);

    await _tap(tester, _key('start-recording'));
    await _speak(tester, recorder, const Duration(seconds: 30));
    await _tap(tester, _key('finish-recording'));
    final first = (await _stored(tester, container))[session.id]!;

    clock.advance(const Duration(minutes: 1));
    await _tap(tester, _key('record-again'));
    // Until the new take is kept, the first one stays.
    expect(files.deleted, isEmpty);
    await _speak(tester, recorder, const Duration(seconds: 70));
    await _tap(tester, _key('finish-recording'));

    final second = (await _stored(tester, container))[session.id]!;
    expect(second.fileName, isNot(first.fileName));
    expect(second.duration, const Duration(seconds: 70));
    expect(files.deleted, [first.fileName]);
  });

  appTest('a take past its time says so, and stops at twice the time', (
    tester,
  ) async {
    final recorder = FakeVoiceRecorder();
    final container = await pumpEnglishApp(
      tester,
      iPadLandscape,
      recorder: recorder,
    );
    // A TED-style intro aims for 1:30.
    final session = await _presenting(
      tester,
      container,
      format: RestitutionFormat.tedIntro,
    );

    await _tap(tester, _key('start-recording'));
    await _speak(tester, recorder, const Duration(seconds: 95));
    expect(_key('recording-over-time'), findsOneWidget);
    expect(_recordingTime(tester), '1:35 / 1:30');

    await _speak(tester, recorder, const Duration(minutes: 3));
    final kept = (await _stored(tester, container))[session.id]!;
    expect(kept.duration, const Duration(minutes: 3));
    expect(_key('recording-player'), findsOneWidget);
  });

  appTest('without the microphone, nothing is recorded and it says why', (
    tester,
  ) async {
    final recorder = FakeVoiceRecorder(allowed: false);
    final container = await pumpEnglishApp(
      tester,
      iPadLandscape,
      recorder: recorder,
    );
    await _presenting(tester, container);

    await _tap(tester, _key('start-recording'));

    expect(_key('microphone-denied'), findsOneWidget);
    expect(recorder.started, isEmpty);
    expect(await _stored(tester, container), isEmpty);
    // Writing is still possible.
    await _tap(tester, _key('switch-format'));
    expect(_key('written-presentation'), findsOneWidget);
  });

  appTest('leaving mid-take throws the take away', (tester) async {
    final recorder = FakeVoiceRecorder();
    final container = await pumpEnglishApp(
      tester,
      iPadLandscape,
      recorder: recorder,
    );
    await _presenting(tester, container);

    await _tap(tester, _key('start-recording'));
    await _speak(tester, recorder, const Duration(seconds: 20));
    await _tap(tester, find.text('← My notes'));

    expect(find.byType(EnglishTopicPage), findsOneWidget);
    expect(recorder.cancelled, 1);
    expect(await _stored(tester, container), isEmpty);
  });

  test('a recording length reads as minutes and seconds', () {
    expect(formatRecordingLength(const Duration(seconds: 7)), '0:07');
    expect(formatRecordingLength(const Duration(seconds: 84)), '1:24');
    expect(formatRecordingLength(const Duration(minutes: 3)), '3:00');
  });

  test('every spoken format aims for a time, and writing aloud for two '
      'minutes', () {
    for (final format in RestitutionFormat.values) {
      expect(format.speakingTime != null, format.spoken, reason: format.name);
    }
    expect(RestitutionFormat.tedIntro.targetSpeakingTime.inSeconds, 90);
    expect(
      RestitutionFormat.shortEssay.targetSpeakingTime,
      RestitutionFormat.defaultSpeakingTime,
    );
  });
}
