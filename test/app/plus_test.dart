import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/plus/plus_page.dart';
import 'package:leera/core/purchases/purchases.dart';
import 'package:leera/features/english/presentation/english_page.dart';

import '../support/fake_ai.dart';
import '../support/pump_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

/// A store that sells, and remembers what was bought.
class _Store implements Purchases {
  final bought = <PlusPlan>[];

  @override
  Future<List<PlusOffer>> offers() async => const [
    PlusOffer(plan: PlusPlan.yearly, price: '€39.99/year', freeTrialDays: 7),
    PlusOffer(plan: PlusPlan.monthly, price: '€5.99/month'),
  ];

  @override
  Future<bool> buy(PlusPlan plan) async {
    bought.add(plan);
    return true;
  }

  @override
  Future<bool> restore() async => false;
}

void main() {
  appTest('with no correction left, Today leads to Leera Plus', (
    tester,
  ) async {
    await pumpEnglishApp(
      tester,
      iPhonePortrait,
      backend: FakeBackendClient(quota: testQuota(used: 1)),
    );

    await _tap(tester, _key('home-open-plus'));

    expect(find.byType(PlusPage), findsOneWidget);
    // Until the store is set up, there is no price and nothing to buy.
    expect(find.text('Price set on the App Store · 7-day free trial'),
        findsOneWidget);
    await _tap(tester, _key('plus-subscribe'));
    expect(find.textContaining('not on sale yet'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tap(tester, _key('plus-close'));
    expect(find.byType(EnglishPage), findsOneWidget);
  });

  appTest('a plan is chosen, then bought', (tester) async {
    final store = _Store();
    await pumpEnglishApp(
      tester,
      iPhonePortrait,
      backend: FakeBackendClient(quota: testQuota(used: 1)),
      overrides: [purchasesProvider.overrideWithValue(store)],
    );
    await _tap(tester, _key('home-open-plus'));

    expect(find.text('Start my free week'), findsOneWidget);
    await _tap(tester, _key('plus-plan-monthly'));
    expect(find.text('€5.99/month'), findsOneWidget);
    expect(find.text('Subscribe'), findsOneWidget);

    await _tap(tester, _key('plus-subscribe'));

    expect(store.bought, [PlusPlan.monthly]);
    expect(find.byType(EnglishPage), findsOneWidget);
  });

  appTest('restoring with nothing to restore says so', (tester) async {
    await pumpEnglishApp(
      tester,
      iPhonePortrait,
      backend: FakeBackendClient(quota: testQuota(used: 1)),
      overrides: [purchasesProvider.overrideWithValue(_Store())],
    );
    await _tap(tester, _key('home-open-plus'));

    await _tap(tester, _key('plus-restore'));

    expect(find.text('No Leera Plus found on this Apple ID.'), findsOneWidget);
    expect(find.byType(PlusPage), findsOneWidget);
  });
}
