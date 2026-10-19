import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:vocara/app/app.dart';
import 'package:vocara/core/ai/ai_settings.dart';
import 'package:vocara/core/audio/audio_playback.dart';
import 'package:vocara/core/audio/recording_files.dart';
import 'package:vocara/core/audio/transcriber.dart';
import 'package:vocara/core/audio/voice_recorder.dart';
import 'package:vocara/core/database/database_provider.dart';
import 'package:vocara/core/time/clock.dart';

import 'fake_ai.dart';
import 'fake_audio.dart';

const iPadLandscape = Size(1194, 834);
const iPadMiniPortrait = Size(744, 1133);
const iPhonePortrait = Size(390, 844);

/// Starts the whole app in a window of [size], on Monday 5 October 2026.
///
/// The app gets an empty in-memory database unless [connection] is given,
/// and no AI settings unless [aiSettings] holds some.
Future<ProviderContainer> pumpEnglishApp(
  WidgetTester tester,
  Size size, {
  QueryExecutor? connection,
  Clock? clock,
  AiSettingsStore? aiSettings,
  VoiceRecorder? recorder,
  AudioPlayback? player,
  RecordingFiles? recordingFiles,
  Transcriber? transcriber,
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  // The widget tree owns the providers, as in the real app, so everything
  // (database, timers) is released when the app leaves the screen.
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        clockProvider.overrideWithValue(clock ?? () => DateTime(2026, 10, 5)),
        databaseConnectionProvider.overrideWithValue(
          connection ?? NativeDatabase.memory(),
        ),
        // No AI is set up unless a test says so: nothing leaves the device.
        aiSettingsStoreProvider.overrideWithValue(
          aiSettings ?? InMemoryAiSettingsStore(),
        ),
        // No microphone, speaker or disk: fakes the test can drive.
        voiceRecorderProvider.overrideWithValue(
          recorder ?? FakeVoiceRecorder(),
        ),
        audioPlaybackProvider.overrideWithValue(player ?? FakeAudioPlayback()),
        recordingFilesProvider.overrideWithValue(
          recordingFiles ?? FakeRecordingFiles(),
        ),
        transcriberProvider.overrideWithValue(
          transcriber ?? FakeTranscriber(),
        ),
        ...overrides,
      ],
      child: const EnglishApp(),
    ),
  );
  await settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(EnglishApp)));
}

/// Lets database work finish and the screen catch up with it.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// Removes the app from the screen, as when it is terminated.
Future<void> closeEnglishApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await settle(tester);
}

/// A widget test that closes the app before it ends.
///
/// Use this for tests that open the database: closing it releases a timer
/// that the test framework would otherwise report as left pending.
void appTest(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    await body(tester);
    await closeEnglishApp(tester);
  });
}

/// Runs [work] (typically a database read or write) alongside the app and
/// returns its result.
///
/// The app runs in the test's simulated time, where nothing progresses
/// unless the test pumps. Awaiting [work] directly would wait forever, and
/// running it inside tester.runAsync can deadlock against the app's own
/// queries; so this keeps pumping until the work is done.
Future<T> runInApp<T>(WidgetTester tester, Future<T> Function() work) async {
  late T result;
  Object? error;
  StackTrace? stackTrace;
  var done = false;
  work().then(
    (value) {
      result = value;
      done = true;
    },
    onError: (Object e, StackTrace s) {
      error = e;
      stackTrace = s;
      done = true;
    },
  );
  for (var attempt = 0; attempt < 100 && !done; attempt++) {
    await tester.pump(const Duration(milliseconds: 1));
    // Database streams also need a turn of the real event loop. Nothing is
    // awaited inside runAsync except that turn, so it cannot deadlock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  if (!done) fail('The work did not finish.');
  if (error != null) Error.throwWithStackTrace(error!, stackTrace!);
  return result;
}

/// Pumps until [target] is on screen, then lets the app settle.
///
/// For screens that animate while they wait (a progress bar while a
/// correction or a transcription is on its way), where pumpAndSettle would
/// never return.
Future<void> pumpUntil(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 100 && !tester.any(target); attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(target, findsOneWidget);
  await settle(tester);
}
