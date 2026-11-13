import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/settings/settings.dart';
import 'package:leera/features/english/data/idiom_bank.dart';

import '../../support/pump_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

void main() {
  appTest("today's expression waits for the day's work", (tester) async {
    await pumpEnglishApp(tester, iPhonePortrait);

    await tester.ensureVisible(_key('idiom-gift'));
    expect(_key('idiom-gift-locked'), findsOneWidget);
    await _tap(tester, _key('idiom-gift'));
    // Nothing opens.
    expect(_key('gift-card'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  appTest('a review done today opens the gift, and the expression is kept', (
    tester,
  ) async {
    final container = await pumpEnglishApp(tester, iPhonePortrait);
    final settings = container.read(settingsRepositoryProvider);
    // The test clock says 5 October 2026.
    await runInApp(
      tester,
      () => settings.write(SettingKeys.reviewDays, '2026-10-05'),
    );
    await settle(tester);

    expect(_key('idiom-gift-ready'), findsOneWidget);
    await _tap(tester, _key('idiom-gift'));

    final first = idiomBank.first;
    expect(_key('gift-card'), findsOneWidget);
    expect(find.text(first.expression), findsOneWidget);
    await _tap(tester, _key('gift-keep'));

    // Back on Today, opened and kept.
    expect(_key('idiom-opened'), findsOneWidget);
    expect(find.text('In your words to review'), findsOneWidget);
    expect(
      await runInApp(
        tester,
        () => settings.watch(SettingKeys.idiomGifts).first,
      ),
      '2026-10-05:${first.id}:1',
    );

    // It is among the words in the journal.
    await _tap(tester, _key('nav-journal'));
    expect(find.text(first.expression), findsOneWidget);
    expect(find.textContaining('Expression of the day'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
