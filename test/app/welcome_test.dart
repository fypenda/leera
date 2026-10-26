import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/welcome/welcome_page.dart';
import 'package:leera/core/settings/settings.dart';
import 'package:leera/features/english/data/preference_repository_providers.dart';
import 'package:leera/features/english/presentation/english_page.dart';

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
    expect(find.text('Welcome to Leera'), findsOneWidget);
    await _tap(tester, _key('welcome-next'));

    // A level must be chosen to go on.
    final next = tester.widget<FilledButton>(_key('welcome-next'));
    expect(next.onPressed, isNull);
    await _tap(tester, _key('welcome-level-B2'));
    await _tap(tester, _key('welcome-next'));

    // Themes are optional.
    expect(find.text('Skip for now'), findsOneWidget);
    await _tap(tester, _key('welcome-theme-Science'));
    await _tap(tester, _key('welcome-theme-Africa'));
    await _tap(tester, _key('welcome-next'));

    expect(find.text('Starting at B2, aiming for C1'), findsOneWidget);
    expect(find.text('Your themes: Africa, Science'), findsOneWidget);
    await _tap(tester, _key('welcome-next'));

    expect(find.byType(EnglishPage), findsOneWidget);
    expect(find.text('Your estimate · Goal: C1'), findsOneWidget);
    final settings = container.read(settingsRepositoryProvider);
    expect(await _read(tester, settings.watch(SettingKeys.welcome)), 'done');
    expect(
      await _read(tester, settings.watch(SettingKeys.selfAssessedLevel)),
      'B2',
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

  appTest('going back keeps the choices made', (tester) async {
    await pumpEnglishApp(tester, iPhonePortrait, welcomed: false);

    await _tap(tester, _key('welcome-next'));
    await _tap(tester, _key('welcome-level-A2'));
    await _tap(tester, _key('welcome-next'));
    await _tap(tester, _key('welcome-back'));

    final next = tester.widget<FilledButton>(_key('welcome-next'));
    expect(next.onPressed, isNotNull);
  });
}
