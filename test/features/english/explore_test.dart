import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/plus/plus_page.dart';
import 'package:leera/core/auth/quota.dart';
import 'package:leera/features/english/data/practice_session_repository_provider.dart';
import 'package:leera/features/english/data/preference_repository_providers.dart';
import 'package:leera/features/english/data/topic_catalog.dart';
import 'package:leera/features/english/domain/practice_session.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/presentation/english_topic_page.dart';
import 'package:leera/features/english/presentation/explore_page.dart';
import 'package:leera/features/english/presentation/explore_theme_page.dart';

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

Future<List<PracticeSession>> _stored(
  WidgetTester tester,
  ProviderContainer container,
) => runInApp(
  tester,
  () => container.read(practiceSessionRepositoryProvider).watchSessions().first,
);

Future<ProviderContainer> _pump(WidgetTester tester, Plan plan) =>
    pumpEnglishApp(
      tester,
      iPhonePortrait,
      backend: FakeBackendClient(
        quota: testQuota(plan: plan, limit: plan == Plan.free ? 1 : 3),
      ),
    );

void main() {
  appTest('a topic chosen in a theme starts a session on it', (tester) async {
    final container = await _pump(tester, Plan.free);

    await _tap(tester, _key('nav-explore'));
    expect(find.byType(ExplorePage), findsOneWidget);
    await _tap(tester, _key('theme-Health'));
    expect(find.byType(ExploreThemePage), findsOneWidget);
    expect(_key('topic-vaccines'), findsOneWidget);

    await _tap(tester, _key('topic-vaccines'));
    await _tap(tester, _key('start-topic'));

    expect(find.byType(EnglishTopicPage), findsOneWidget);
    expect((await _stored(tester, container)).single.topicId, 'vaccines');
    expect(tester.takeException(), isNull);
  });

  appTest('with a session in progress, Explore offers to finish it', (
    tester,
  ) async {
    final container = await _pump(tester, Plan.free);
    await runInApp(
      tester,
      () => container
          .read(practiceSessionRepositoryProvider)
          .start(
            topicId: 'suez-canal',
            format: RestitutionFormat.shortEssay,
          ),
    );
    await openEnglishHome(tester);

    await _tap(tester, _key('nav-explore'));
    await _tap(tester, _key('theme-Health'));
    await _tap(tester, _key('topic-vaccines'));

    expect(_key('start-topic'), findsNothing);
    expect(_key('session-in-progress'), findsOneWidget);
    await _tap(tester, _key('continue-session'));
    expect((await _stored(tester, container)).single.topicId, 'suez-canal');
  });

  appTest('on the free plan, the daily themes lead to Leera Plus', (
    tester,
  ) async {
    await _pump(tester, Plan.free);
    await _tap(tester, _key('nav-explore'));

    expect(find.text('Choose its themes with Leera Plus'), findsOneWidget);
    await _tap(tester, _key('daily-themes'));
    expect(find.byType(PlusPage), findsOneWidget);
  });

  appTest('with Plus, the daily topic comes from the themes chosen', (
    tester,
  ) async {
    final container = await _pump(tester, Plan.plus);
    await _tap(tester, _key('nav-explore'));
    expect(find.text('Drawn from every theme'), findsOneWidget);

    await _tap(tester, _key('daily-themes'));
    await _tap(tester, _key('pick-Philosophy'));
    await _tap(tester, _key('save-themes'));

    expect(find.text('Drawn from Philosophy'), findsOneWidget);
    expect(
      await runInApp(
        tester,
        () => container
            .read(themePreferenceRepositoryProvider)
            .watchThemes()
            .first,
      ),
      {'Philosophy'},
    );

    // The daily topic, from Today: a philosophy topic.
    await _tap(tester, _key('nav-today'));
    await _tap(tester, find.text('Roll my topic →'));
    final topic = topicById((await _stored(tester, container)).single.topicId);
    expect(topic.themes, contains('Philosophy'));
  });
}
