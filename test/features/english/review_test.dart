import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/plus/plus_page.dart';
import 'package:leera/core/auth/quota.dart';
import 'package:leera/features/english/application/english_reviews.dart';
import 'package:leera/features/english/data/practice_session_repository_provider.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/domain/session_feedback.dart';
import 'package:leera/features/english/presentation/review_page.dart';

import '../../support/fake_ai.dart';
import '../../support/navigation.dart';
import '../../support/pump_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

/// Starts the app on [plan], with two words kept, and opens the Journal.
Future<ProviderContainer> _pumpWithWords(
  WidgetTester tester,
  Plan plan,
) async {
  final container = await pumpEnglishApp(
    tester,
    iPhonePortrait,
    backend: FakeBackendClient(
      quota: testQuota(plan: plan, limit: plan == Plan.free ? 1 : 3),
    ),
  );
  final repository = container.read(practiceSessionRepositoryProvider);
  await runInApp(tester, () async {
    final session = await repository.start(
      topicId: 'suez-canal',
      format: RestitutionFormat.shortEssay,
    );
    await repository.complete(session.id, presentation: 'The canal.');
    await repository.saveFeedback(
      session.id,
      sampleFeedback(
        vocabulary: const [
          VocabularyItem('chokepoint', 'a narrow passage'),
          VocabularyItem('to bottleneck', 'to slow down'),
        ],
      ),
    );
  });
  await openEnglishHome(tester);
  await _tap(tester, _key('nav-journal'));
  return container;
}

void main() {
  appTest('on the free plan, the review leads to Leera Plus', (tester) async {
    await _pumpWithWords(tester, Plan.free);

    expect(find.text('With Leera Plus'), findsOneWidget);
    await _tap(tester, _key('journal-review'));

    expect(find.byType(PlusPage), findsOneWidget);
  });

  appTest('a round: a word known, a word missed and seen again', (
    tester,
  ) async {
    final container = await _pumpWithWords(tester, Plan.plus);
    expect(find.text('2 words to review today'), findsOneWidget);

    await _tap(tester, _key('journal-review'));
    expect(find.byType(ReviewPage), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(_key('review-meaning'), findsNothing);

    // The latest kept first: "chokepoint", known.
    await _tap(tester, _key('review-reveal'));
    expect(find.text('a narrow passage'), findsOneWidget);
    await _tap(tester, _key('review-knew'));

    // "to bottleneck", missed: it comes back at the end of the round.
    expect(find.text('2 / 2'), findsOneWidget);
    await _tap(tester, _key('review-reveal'));
    await _tap(tester, _key('review-again'));
    expect(find.text('3 / 3'), findsOneWidget);
    expect(_key('review-card-to bottleneck'), findsOneWidget);
    await _tap(tester, _key('review-reveal'));
    await _tap(tester, _key('review-knew'));

    expect(_key('review-finished'), findsOneWidget);
    expect(find.textContaining('2 words reviewed, 1 known'), findsOneWidget);

    // Both are stored: the missed one is back tomorrow, not in 3 days.
    final reviews = await runInApp(
      tester,
      () => container.read(wordReviewsProvider.future),
    );
    expect(reviews['chokepoint']!.box, 1);
    expect(reviews['to bottleneck']!.box, 0);

    await _tap(tester, _key('review-done'));
    expect(find.text('All caught up for today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
