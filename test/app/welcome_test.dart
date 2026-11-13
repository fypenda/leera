import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/plus/plus_page.dart';
import 'package:leera/app/welcome/welcome_page.dart';
import 'package:leera/core/settings/settings.dart';
import 'package:leera/features/english/data/preference_repository_providers.dart';
import 'package:leera/features/english/presentation/english_topic_page.dart';

import '../support/pump_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

Future<T> _read<T>(WidgetTester tester, Stream<T> stream) =>
    runInApp(tester, () => stream.first);

/// From the splash to the level question.
Future<void> _pastTheSplash(WidgetTester tester) async {
  expect(find.text('FLUENCY THROUGH REAL TOPICS'), findsOneWidget);
  // The splash moves on by itself.
  await tester.pump(const Duration(milliseconds: 2300));
  await settle(tester);
  expect(find.textContaining('Real fluency.', findRichText: true), findsOneWidget);
  await _tap(tester, _key('welcome-next'));
}

void main() {
  appTest('the welcome comes first, once, and keeps what was chosen', (
    tester,
  ) async {
    final container = await pumpEnglishApp(
      tester,
      iPhonePortrait,
      welcomed: false,
    );

    expect(find.byType(WelcomePage), findsOneWidget);
    expect(_key('welcome-bubble'), findsOneWidget);
    await _pastTheSplash(tester);

    // A level must be chosen to go on.
    final next = tester.widget<FilledButton>(_key('welcome-next'));
    expect(next.onPressed, isNull);
    await _tap(tester, _key('welcome-level-B2'));
    await _tap(tester, _key('welcome-next'));

    // A goal must be chosen too.
    expect(
      tester.widget<FilledButton>(_key('welcome-next')).onPressed,
      isNull,
    );
    await _tap(tester, _key('welcome-goal-work'));
    await _tap(tester, _key('welcome-next'));

    // The first language is optional; another one can be typed.
    expect(find.text('Skip'), findsOneWidget);
    await _tap(tester, _key('welcome-language-other'));
    await tester.enterText(_key('welcome-language-typed'), '  Pulaar ');
    await settle(tester);
    await _tap(tester, _key('welcome-next'));

    // Themes are optional.
    expect(find.text('Skip for now'), findsOneWidget);
    await _tap(tester, _key('welcome-theme-Science'));
    await _tap(tester, _key('welcome-theme-Africa'));
    await _tap(tester, _key('welcome-next'));

    // The week: Monday to Friday at first; the card follows the days.
    expect(find.text('5 topics a week'), findsOneWidget);
    expect(find.text('3 reviews a week'), findsOneWidget);
    await _tap(tester, _key('rhythm-day-6'));
    expect(find.text('6 topics a week'), findsOneWidget);
    // With no day, there is no week to set.
    for (var day = 1; day <= 6; day++) {
      await _tap(tester, _key('rhythm-day-$day'));
    }
    expect(
      tester.widget<FilledButton>(_key('welcome-next')).onPressed,
      isNull,
    );
    for (final day in [1, 3, 5]) {
      await _tap(tester, _key('rhythm-day-$day'));
    }
    expect(find.text('Set my week'), findsOneWidget);
    await _tap(tester, _key('welcome-next'));

    // Free or Plus, then the free plan.
    expect(_key('welcome-compare'), findsOneWidget);
    expect(find.text('1 a week'), findsOneWidget);
    expect(find.text('3 a day'), findsOneWidget);
    await _tap(tester, _key('welcome-free'));

    // Day 1: what was chosen, and the first topic to roll.
    expect(_key('welcome-day-one'), findsOneWidget);
    expect(find.text('B2 → C1'), findsOneWidget);
    expect(find.text('3 sessions a week'), findsOneWidget);
    expect(find.text('Roll my first topic'), findsOneWidget);
    await _tap(tester, _key('welcome-next'));

    // Today rolls the first topic as it opens.
    expect(find.byType(EnglishTopicPage), findsOneWidget);
    final settings = container.read(settingsRepositoryProvider);
    expect(await _read(tester, settings.watch(SettingKeys.welcome)), 'done');
    expect(
      await _read(tester, settings.watch(SettingKeys.rollOnArrival)),
      '',
    );
    expect(
      await _read(tester, settings.watch(SettingKeys.selfAssessedLevel)),
      'B2',
    );
    expect(await _read(tester, settings.watch(SettingKeys.goal)), 'work');
    expect(
      await _read(tester, settings.watch(SettingKeys.firstLanguage)),
      'Pulaar',
    );
    expect(
      await _read(tester, settings.watch(SettingKeys.weeklyPlan)),
      '20|1,3,5',
    );
    expect(
      await _read(
        tester,
        container.read(themePreferenceRepositoryProvider).watchThemes(),
      ),
      {'Africa', 'Science'},
    );
    expect(tester.takeException(), isNull);
  });

  appTest('the splash moves on with a tap too', (tester) async {
    await pumpEnglishApp(tester, iPhonePortrait, welcomed: false);
    await _tap(tester, _key('welcome-splash'));
    expect(find.textContaining('Real fluency.', findRichText: true), findsOneWidget);
  });

  appTest('going back keeps the choices made', (tester) async {
    await pumpEnglishApp(tester, iPhonePortrait, welcomed: false);

    await _pastTheSplash(tester);
    await _tap(tester, _key('welcome-level-A2'));
    await _tap(tester, _key('welcome-next'));
    await _tap(tester, _key('welcome-back'));

    final next = tester.widget<FilledButton>(_key('welcome-next'));
    expect(next.onPressed, isNotNull);
  });

  appTest('Leera Plus opens from the last question, and comes back to it', (
    tester,
  ) async {
    await pumpEnglishApp(tester, iPhonePortrait, welcomed: false);
    await _pastTheSplash(tester);
    await _tap(tester, _key('welcome-level-B1'));
    await _tap(tester, _key('welcome-next'));
    await _tap(tester, _key('welcome-goal-travel'));
    await _tap(tester, _key('welcome-next'));
    await _tap(tester, _key('welcome-next'));
    await _tap(tester, _key('welcome-next'));
    await _tap(tester, _key('welcome-next'));

    await _tap(tester, _key('welcome-next'));
    expect(find.byType(PlusPage), findsOneWidget);

    await _tap(tester, _key('plus-close'));
    expect(_key('welcome-compare'), findsOneWidget);
  });

  appTest('Today shows the week that was set', (tester) async {
    final container = await pumpEnglishApp(tester, iPhonePortrait);
    await runInApp(
      tester,
      () => container
          .read(settingsRepositoryProvider)
          .write(SettingKeys.weeklyPlan, '30|1,2,3,4,5,6,7'),
    );
    await settle(tester);

    expect(find.text('0 / 7'), findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);
  });
}
