import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/auth/quota.dart';
import 'package:leera/features/english/application/english_reviews.dart';
import 'package:leera/features/english/data/practice_session_repository_provider.dart';
import 'package:leera/features/english/domain/practice_session.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/domain/session_feedback.dart';
import 'package:leera/features/english/english_routes.dart';
import 'package:leera/app/router.dart';

import '../../support/fake_ai.dart';
import '../../support/pump_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

void main() {
  appTest('the words of a correction are sorted, and only those to learn '
      'are reviewed', (tester) async {
    final container = await pumpEnglishApp(
      tester,
      iPhonePortrait,
      backend: FakeBackendClient(quota: testQuota(plan: Plan.plus, limit: 3)),
    );
    final repository = container.read(practiceSessionRepositoryProvider);
    late PracticeSession session;
    await runInApp(tester, () async {
      session = await repository.start(
        topicId: 'suez-canal',
        format: RestitutionFormat.shortEssay,
      );
      session = await repository.complete(session.id, presentation: 'Text.');
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
    container.read(routerProvider).goNamed(
      englishFeedbackRouteName,
      pathParameters: {englishSessionParameter: session.id},
    );
    await settle(tester);

    expect(_key('review-cards'), findsOneWidget);
    await _tap(tester, _key('know-chokepoint'));
    await _tap(tester, _key('learn-to bottleneck'));

    final triage = await runInApp(
      tester,
      () => container.read(wordTriageProvider.future),
    );
    expect(triage, {'chokepoint': true, 'to bottleneck': false});
    expect(find.textContaining('All sorted'), findsOneWidget);

    // The Journal now has one word to review, not two.
    await _tap(tester, _key('feedback-done'));
    await _tap(tester, _key('nav-journal'));
    expect(find.text('1 word to review today'), findsOneWidget);

    // A word can be sorted again from the Journal.
    await _tap(tester, _key('learn-chokepoint'));
    expect(find.text('2 words to review today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
