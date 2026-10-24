import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/router.dart';
import 'package:leera/app/account/account_page.dart';
import 'package:leera/core/ai/backend_client.dart';
import 'package:leera/features/english/data/backend_feedback_api.dart';
import 'package:leera/features/english/data/practice_session_repository_provider.dart';
import 'package:leera/features/english/domain/practice_session.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/domain/session_feedback.dart';
import 'package:leera/features/english/english_routes.dart';
import 'package:leera/features/english/presentation/english_feedback_page.dart';

import '../../support/fake_ai.dart';
import '../../support/navigation.dart';
import '../../support/pump_app.dart';

/// Pumps until [target] is on screen. While a correction is on its way a
/// progress bar keeps animating, so pumpAndSettle would never return.
Future<void> _pumpUntil(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 100 && !tester.any(target); attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(target, findsOneWidget);
  await settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

/// Starts the app, signed in, with [api] answering unless said otherwise.
Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  FakeFeedbackApi? api,
  Size size = iPadLandscape,
}) => pumpEnglishApp(
  tester,
  size,
  overrides: [if (api != null) feedbackApiProvider.overrideWithValue(api)],
);

/// A finished session, written unless [presentation] is null.
Future<PracticeSession> _finished(
  WidgetTester tester,
  ProviderContainer container, {
  String? presentation = 'It permits to ships to avoid Africa.',
}) async {
  final repository = container.read(practiceSessionRepositoryProvider);
  final session = await runInApp(
    tester,
    () => repository.start(
      topicId: 'suez-canal',
      format: RestitutionFormat.shortEssay,
    ),
  );
  return runInApp(
    tester,
    () => repository.complete(session.id, presentation: presentation),
  );
}

void _openFeedback(ProviderContainer container, PracticeSession session) {
  container.read(routerProvider).goNamed(
    englishFeedbackRouteName,
    pathParameters: {englishSessionParameter: session.id},
  );
}

Future<Map<String, SessionFeedback>> _storedFeedbacks(
  WidgetTester tester,
  ProviderContainer container,
) => runInApp(
  tester,
  () => container
      .read(practiceSessionRepositoryProvider)
      .watchFeedbacks()
      .first,
);

final _headline = find.byKey(const ValueKey('feedback-headline'));

void main() {
  for (final (name, size) in [
    ('iPad', iPadLandscape),
    ('a phone', iPhonePortrait),
  ]) {
    appTest('a written presentation is corrected and kept, on $name', (
      tester,
    ) async {
      final api = FakeFeedbackApi();
      final container = await _pumpApp(tester, api: api, size: size);
      final session = await _finished(tester, container);

      _openFeedback(container, session);
      await _pumpUntil(tester, _headline);

      expect(find.byType(EnglishFeedbackPage), findsOneWidget);
      expect(find.text('Clear and well built 🎉'), findsOneWidget);
      expect(find.byKey(const ValueKey('estimated-level')), findsOneWidget);
      expect(find.text('chokepoint'), findsWidgets);
      expect(tester.takeException(), isNull);

      final call = api.calls.single;
      expect(call.topic.id, 'suez-canal');
      expect(call.format, RestitutionFormat.shortEssay);
      expect(call.presentation, 'It permits to ships to avoid Africa.');
      expect(call.recurringMistakes, isEmpty);
      expect(
        (await _storedFeedbacks(tester, container))[session.id]!.estimatedLevel,
        'B2+',
      );

      // Opened again, it comes from the device: nothing is asked twice.
      await _tap(tester, find.byKey(const ValueKey('feedback-done')));
      _openFeedback(container, session);
      await settle(tester);
      expect(_headline, findsOneWidget);
      expect(api.calls, hasLength(1));
    });
  }

  appTest('a failed correction says why and can be tried again', (
    tester,
  ) async {
    final api = FakeFeedbackApi(failure: BackendFailure.rateLimited);
    final container = await _pumpApp(tester, api: api);
    final session = await _finished(tester, container);

    _openFeedback(container, session);
    await _pumpUntil(tester, find.byKey(const ValueKey('feedback-failed')));
    expect(
      find.text(describeBackendFailure(BackendFailure.rateLimited)),
      findsOneWidget,
    );
    expect(await _storedFeedbacks(tester, container), isEmpty);

    api.failure = null;
    await tester.tap(find.byKey(const ValueKey('retry-feedback')));
    await _pumpUntil(tester, _headline);

    expect(api.calls, hasLength(2));
    expect(await _storedFeedbacks(tester, container), hasLength(1));
  });

  appTest('mistakes made twice before go with the next presentation', (
    tester,
  ) async {
    final api = FakeFeedbackApi();
    final container = await _pumpApp(tester, api: api);
    final repository = container.read(practiceSessionRepositoryProvider);
    for (final day in [1, 2]) {
      final past = await _finished(tester, container);
      await runInApp(
        tester,
        () => repository.saveFeedback(
          past.id,
          sampleFeedback(
            tags: ['articles', 'tenses-$day'],
            createdAt: DateTime.utc(2026, 10, day),
          ),
        ),
      );
    }
    final session = await _finished(tester, container);

    _openFeedback(container, session);
    await _pumpUntil(tester, _headline);

    expect(api.calls.single.recurringMistakes, ['articles']);
  });

  appTest('a spoken presentation is not sent', (tester) async {
    final api = FakeFeedbackApi();
    final container = await _pumpApp(tester, api: api);
    final session = await _finished(tester, container, presentation: null);

    _openFeedback(container, session);
    await settle(tester);

    expect(find.byKey(const ValueKey('spoken-not-corrected')), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  appTest('a used-up quota says so and leads to the account', (tester) async {
    final api = FakeFeedbackApi(failure: BackendFailure.quotaExceeded);
    final container = await _pumpApp(tester, api: api);
    final session = await _finished(tester, container);

    _openFeedback(container, session);
    await _pumpUntil(tester, find.byKey(const ValueKey('feedback-failed')));
    expect(
      find.text(describeBackendFailure(BackendFailure.quotaExceeded)),
      findsOneWidget,
    );
    // Trying again would only be refused again.
    expect(find.byKey(const ValueKey('retry-feedback')), findsNothing);

    await _tap(tester, find.byKey(const ValueKey('feedback-open-account')));
    expect(find.byType(AccountPage), findsOneWidget);
  });

  appTest('the corrections feed the level shown on the home page', (
    tester,
  ) async {
    final container = await _pumpApp(tester);

    final session = await _finished(tester, container);
    await runInApp(
      tester,
      () => container
          .read(practiceSessionRepositoryProvider)
          .saveFeedback(
            session.id,
            sampleFeedback(
              level: 'C1',
              vocabulary: const [
                VocabularyItem('to weather the storm', 'to get through'),
              ],
            ),
          ),
    );
    await settle(tester);

    await openEnglishHome(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('english-level')),
        matching: find.text('C1'),
      ),
      findsOneWidget,
    );
    expect(find.text('1 correction left this week'), findsOneWidget);
    // The session's mean score, out of 10: (7 + 8 + 6 + 9 + 8) / 5.
    expect(find.text('7.6'), findsOneWidget);
    expect(find.text('1 word'), findsOneWidget);
  });

  appTest('before any correction, the home page says what will come', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.byKey(const ValueKey('english-level')), findsNothing);
    expect(
      find.text('Estimated after your first correction'),
      findsOneWidget,
    );
  });
}
