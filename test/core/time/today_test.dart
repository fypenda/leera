import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/time/calendar_date.dart';
import 'package:leera/core/time/clock.dart';
import 'package:leera/core/time/today.dart';

import '../../support/fake_clock.dart';

/// Watches [todayProvider] on a clock the test controls, and records every
/// date it reports.
({FakeClock clock, List<CalendarDate> seen, ProviderContainer container})
_watchToday(DateTime start) {
  final clock = FakeClock(start);
  final container = ProviderContainer(
    overrides: [clockProvider.overrideWithValue(clock.call)],
  );
  final seen = <CalendarDate>[];
  container.listen(
    todayProvider,
    (previous, next) => seen.add(next),
    fireImmediately: true,
  );
  return (clock: clock, seen: seen, container: container);
}

/// Lets [duration] pass, on the clock and for timers alike.
Future<void> _wait(WidgetTester tester, FakeClock clock, Duration duration) {
  clock.advance(duration);
  return tester.pump(duration);
}

void main() {
  // testWidgets gives these tests a controllable timer; no widget is shown.

  testWidgets('is the local calendar date of the clock', (tester) async {
    final late = _watchToday(DateTime(2026, 10, 5, 23, 59, 30));
    final early = _watchToday(DateTime(2026, 10, 5, 0, 0, 1));

    expect(late.seen, [CalendarDate(2026, 10, 5)]);
    expect(early.seen, [CalendarDate(2026, 10, 5)]);

    late.container.dispose();
    early.container.dispose();
  });

  testWidgets('changes at local midnight, and not a moment before', (
    tester,
  ) async {
    final today = _watchToday(DateTime(2026, 10, 5, 23, 59, 30));

    await _wait(tester, today.clock, const Duration(seconds: 29));
    expect(today.seen, [CalendarDate(2026, 10, 5)]);

    await _wait(tester, today.clock, const Duration(seconds: 1));
    expect(today.seen, [CalendarDate(2026, 10, 5), CalendarDate(2026, 10, 6)]);

    today.container.dispose();
  });

  testWidgets('keeps changing, once a day, with nothing in between', (
    tester,
  ) async {
    final today = _watchToday(DateTime(2026, 12, 30, 12));

    for (var hour = 0; hour < 72; hour++) {
      await _wait(tester, today.clock, const Duration(hours: 1));
    }

    expect(today.seen, [
      CalendarDate(2026, 12, 30),
      CalendarDate(2026, 12, 31),
      CalendarDate(2027, 1, 1),
      CalendarDate(2027, 1, 2),
    ]);

    today.container.dispose();
  });

  testWidgets('catches up when the app returns to the foreground', (
    tester,
  ) async {
    final today = _watchToday(DateTime(2026, 10, 5, 22));

    // The app is suspended for two days: the clock moves, timers do not.
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    today.clock.advance(const Duration(days: 2));
    expect(today.seen, [CalendarDate(2026, 10, 5)]);

    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump(const Duration(milliseconds: 1));

    expect(today.seen, [CalendarDate(2026, 10, 5), CalendarDate(2026, 10, 7)]);

    today.container.dispose();
  });

  testWidgets('leaves no timer behind once nothing is watching', (
    tester,
  ) async {
    final today = _watchToday(DateTime(2026, 10, 5, 12));

    today.container.dispose();

    // The test framework fails this test if a timer is still pending.
    await _wait(tester, today.clock, const Duration(days: 2));
    expect(today.seen, [CalendarDate(2026, 10, 5)]);
  });
}
