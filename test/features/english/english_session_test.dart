import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/router.dart';
import 'package:leera/core/common/random_source.dart';
import 'package:leera/features/english/data/practice_session_repository_provider.dart';
import 'package:leera/features/english/data/topic_catalog.dart';
import 'package:leera/features/english/domain/practice_session.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/presentation/english_feedback_page.dart';
import 'package:leera/features/english/presentation/english_page.dart';
import 'package:leera/features/english/presentation/english_restitution_page.dart';
import 'package:leera/features/english/presentation/english_topic_page.dart';

import '../../support/navigation.dart';
import '../../support/pump_app.dart';

Future<ProviderContainer> _pumpApp(WidgetTester tester, Size size) =>
    pumpEnglishApp(
      tester,
      size,
      overrides: [randomProvider.overrideWithValue(Random(7))],
    );

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

String _topicTitle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('topic-title'))).data!;

Future<List<PracticeSession>> _stored(
  WidgetTester tester,
  ProviderContainer container,
) => runInApp(
  tester,
  () => container.read(practiceSessionRepositoryProvider).watchSessions().first,
);

/// Lets the notes be saved: typing must pause before they are.
Future<void> _pauseTyping(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await settle(tester);
}

final _writtenField = find.byKey(const ValueKey('written-presentation'));

/// Draws a topic from the home page.
Future<void> _drawTopic(WidgetTester tester) async {
  await openEnglishHome(tester);
  await _tap(tester, find.text('Draw my topic →'));
}

void main() {
  for (final (name, size) in [
    ('iPad', iPadLandscape),
    ('a phone', iPhonePortrait),
  ]) {
    appTest('a whole session runs from the home page on $name', (
      tester,
    ) async {
      final container = await _pumpApp(tester, size);

      await _drawTopic(tester);
      expect(find.byType(EnglishTopicPage), findsOneWidget);
      // A session covers the whole screen.
      expect(find.byType(NavigationBar), findsNothing);
      final title = _topicTitle(tester);
      expect(topicCatalog.map((t) => t.title), contains(title));
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.byKey(const ValueKey('research-notes')),
        'Opened in 1869',
      );
      await _tap(tester, find.byKey(const ValueKey('done-researching')));
      expect(find.byType(EnglishRestitutionPage), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Whatever format was drawn, the presentation can be written.
      if (!tester.any(_writtenField)) {
        await _tap(tester, find.byKey(const ValueKey('switch-format')));
      }
      await tester.enterText(_writtenField, 'The canal opened in 1869.');
      final send = find.byKey(const ValueKey('send-for-feedback'));
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      await tester.tap(send);
      // The backend is out of reach in tests: no correction comes back, and
      // the presentation is kept. (A progress bar animates while it is asked
      // for, so this does not wait for the screen to settle.)
      await pumpUntil(tester, find.byKey(const ValueKey('feedback-failed')));
      expect(find.byType(EnglishFeedbackPage), findsOneWidget);
      expect(find.text('The canal opened in 1869.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final stored = (await _stored(tester, container)).single;
      expect(stored.status, PracticeSessionStatus.completed);
      expect(stored.notes, 'Opened in 1869');
      expect(stored.presentation, 'The canal opened in 1869.');

      await _tap(tester, find.byKey(const ValueKey('feedback-done')));
      expect(find.byType(EnglishPage), findsOneWidget);
      expect(find.byType(PracticeSessionTile), findsOneWidget);
      expect(find.text(title), findsOneWidget);
    });
  }

  appTest('the home page lists a finished session and opens it', (
    tester,
  ) async {
    final container = await _pumpApp(tester, iPadLandscape);

    final session = await runInApp(
      tester,
      () => container
          .read(practiceSessionRepositoryProvider)
          .start(topicId: 'jazz', format: RestitutionFormat.debate),
    );
    await runInApp(
      tester,
      () => container
          .read(practiceSessionRepositoryProvider)
          .complete(session.id),
    );
    await settle(tester);
    await openEnglishHome(tester);

    expect(find.text('How jazz was born in New Orleans'), findsOneWidget);
    await _tap(tester, find.byKey(ValueKey('session-${session.id}')));
    expect(find.byType(EnglishFeedbackPage), findsOneWidget);
  });

  appTest('a session in progress is continued from the home page', (
    tester,
  ) async {
    await _pumpApp(tester, iPadLandscape);
    await _drawTopic(tester);
    final title = _topicTitle(tester);

    await _tap(tester, find.byKey(const ValueKey('session-leave')));
    expect(find.byType(EnglishPage), findsOneWidget);

    await _tap(tester, find.text('Continue my session →'));
    expect(find.byType(EnglishTopicPage), findsOneWidget);
    expect(_topicTitle(tester), title);
  });

  appTest('a swipe from the left edge leaves a session', (tester) async {
    await _pumpApp(tester, iPadLandscape);
    await _drawTopic(tester);
    expect(find.byType(EnglishTopicPage), findsOneWidget);

    await tester.dragFrom(const Offset(4, 400), const Offset(300, 0));
    await settle(tester);

    expect(find.byType(EnglishTopicPage), findsNothing);
    expect(find.byType(EnglishPage), findsOneWidget);
  });

  appTest('notes are saved as they are written', (tester) async {
    final container = await _pumpApp(tester, iPadLandscape);
    await _drawTopic(tester);

    await tester.enterText(
      find.byKey(const ValueKey('research-notes')),
      'Ever Given, 2021',
    );
    await _pauseTyping(tester);

    expect((await _stored(tester, container)).single.notes, 'Ever Given, 2021');

    // And they are there again when the session is reopened.
    await _tap(tester, find.byKey(const ValueKey('session-leave')));
    await _tap(tester, find.text('Continue my session →'));
    expect(find.text('Ever Given, 2021'), findsOneWidget);
  });

  appTest('another topic can be drawn once', (tester) async {
    final container = await _pumpApp(tester, iPadLandscape);
    await _drawTopic(tester);
    final first = _topicTitle(tester);

    await _tap(tester, find.byKey(const ValueKey('another-topic')));

    expect(_topicTitle(tester), isNot(first));
    expect(find.byKey(const ValueKey('another-topic')), findsNothing);
    expect((await _stored(tester, container)).single.rerolled, isTrue);
  });

  appTest('an address with an unknown session says so', (tester) async {
    final container = await _pumpApp(tester, iPadLandscape);

    container.read(routerProvider).go('/session/nobody');
    await settle(tester);

    expect(find.byKey(const ValueKey('session-not-found')), findsOneWidget);
    await _tap(tester, find.text('Back to English'));
    expect(find.byType(EnglishPage), findsOneWidget);
  });

  appTest('with no finished session, the home page says so', (tester) async {
    await _pumpApp(tester, iPadLandscape);

    expect(find.byType(EnglishPage), findsOneWidget);
    expect(find.byKey(const ValueKey('no-finished-sessions')), findsOneWidget);
  });
}
