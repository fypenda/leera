import 'package:elora/app/router.dart';
import 'package:elora/core/audio/transcriber.dart';
import 'package:elora/features/english/data/backend_feedback_api.dart';
import 'package:elora/features/english/data/practice_session_repository_provider.dart';
import 'package:elora/features/english/domain/practice_session.dart';
import 'package:elora/features/english/domain/restitution_format.dart';
import 'package:elora/features/english/english_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ai.dart';
import '../../support/fake_audio.dart';
import '../../support/pump_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// A spoken session, recorded and sent, then its feedback page opened.
Future<PracticeSession> _sentSpoken(
  WidgetTester tester,
  ProviderContainer container, {
  bool recorded = true,
}) async {
  final repository = container.read(practiceSessionRepositoryProvider);
  final session = await runInApp(
    tester,
    () => repository.start(
      topicId: 'suez-canal',
      format: RestitutionFormat.voiceNote,
    ),
  );
  if (recorded) {
    await runInApp(
      tester,
      () => repository.saveRecording(
        session.id,
        fileName: 'take.m4a',
        duration: const Duration(seconds: 84),
      ),
    );
  }
  await runInApp(tester, () => repository.complete(session.id));
  container.read(routerProvider).goNamed(
    englishFeedbackRouteName,
    pathParameters: {englishSessionParameter: session.id},
  );
  return session;
}

Future<String?> _storedTranscript(
  WidgetTester tester,
  ProviderContainer container,
  PracticeSession session,
) async => (await runInApp(
  tester,
  () => container
      .read(practiceSessionRepositoryProvider)
      .watchRecordings()
      .first,
))[session.id]?.transcript;

void main() {
  appTest('a spoken presentation is heard, then corrected as speech', (
    tester,
  ) async {
    final transcriber = FakeTranscriber();
    final api = FakeFeedbackApi();
    final container = await pumpEnglishApp(
      tester,
      iPadLandscape,
      transcriber: transcriber,
      aiSettings: InMemoryAiSettingsStore(testAiSettings()),
      overrides: [feedbackApiProvider.overrideWithValue(api)],
    );
    final session = await _sentSpoken(tester, container);

    await pumpUntil(tester, _key('feedback-headline'));

    expect(transcriber.transcribed, ['/recordings/take.m4a']);
    expect(
      await _storedTranscript(tester, container, session),
      transcriber.text,
    );
    final call = api.calls.single;
    expect(call.presentation, transcriber.text);
    expect(call.spoken, isTrue);
    expect(call.format, RestitutionFormat.voiceNote);
    expect(find.text(transcriber.text), findsOneWidget);
    expect(_key('recording-player'), findsOneWidget);

    // Opened again: nothing is heard or asked twice.
    await tester.tap(_key('feedback-done'));
    await settle(tester);
    container.read(routerProvider).goNamed(
      englishFeedbackRouteName,
      pathParameters: {englishSessionParameter: session.id},
    );
    await settle(tester);
    expect(_key('feedback-headline'), findsOneWidget);
    expect(transcriber.transcribed, hasLength(1));
    expect(api.calls, hasLength(1));
  });

  appTest('without speech recognition, it says why and can try again', (
    tester,
  ) async {
    final transcriber = FakeTranscriber(allowed: false);
    final container = await pumpEnglishApp(
      tester,
      iPadLandscape,
      transcriber: transcriber,
    );
    final session = await _sentSpoken(tester, container);

    await pumpUntil(tester, _key('transcription-failed'));
    expect(
      find.text(describeTranscriptionFailure(TranscriptionFailure.notAllowed)),
      findsOneWidget,
    );
    expect(transcriber.transcribed, isEmpty);
    expect(await _storedTranscript(tester, container, session), isNull);
    // The recording is still there to listen to.
    expect(_key('recording-player'), findsOneWidget);

    transcriber.allowed = true;
    await tester.tap(_key('retry-transcription'));
    // No AI set up: the transcript is kept, and correction waits for it.
    await pumpUntil(tester, _key('ai-not-set-up'));
    expect(
      await _storedTranscript(tester, container, session),
      transcriber.text,
    );
    expect(_key('sent-transcript'), findsOneWidget);
  });

  appTest('a recording where nothing is heard is not sent for correction', (
    tester,
  ) async {
    final api = FakeFeedbackApi();
    final container = await pumpEnglishApp(
      tester,
      iPadLandscape,
      transcriber: FakeTranscriber(text: ''),
      aiSettings: InMemoryAiSettingsStore(testAiSettings()),
      overrides: [feedbackApiProvider.overrideWithValue(api)],
    );
    final session = await _sentSpoken(tester, container);

    await pumpUntil(tester, _key('nothing-heard'));

    expect(await _storedTranscript(tester, container, session), '');
    expect(api.calls, isEmpty);
  });

  appTest('a failed transcription keeps the recording and says so', (
    tester,
  ) async {
    final container = await pumpEnglishApp(
      tester,
      iPadLandscape,
      transcriber: FakeTranscriber(failure: TranscriptionFailure.unavailable),
    );
    await _sentSpoken(tester, container);

    await pumpUntil(tester, _key('transcription-failed'));
    expect(
      find.text(describeTranscriptionFailure(TranscriptionFailure.unavailable)),
      findsOneWidget,
    );
  });

  appTest('a spoken presentation sent without a recording says so', (
    tester,
  ) async {
    final transcriber = FakeTranscriber();
    final container = await pumpEnglishApp(
      tester,
      iPadLandscape,
      transcriber: transcriber,
    );
    await _sentSpoken(tester, container, recorded: false);
    await settle(tester);

    expect(_key('spoken-not-corrected'), findsOneWidget);
    expect(transcriber.transcribed, isEmpty);
  });
}
