import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calendar_date.dart';
import 'clock.dart';

/// Today's date on the device's calendar.
///
/// Watch this for anything that depends on the day: it changes at local
/// midnight while the app is open. A single timer is set for the next
/// midnight (nothing ticks in between), and the date is checked again when
/// the app returns to the foreground, since timers do not run while it is
/// suspended.
final todayProvider = Provider.autoDispose<CalendarDate>((ref) {
  final now = ref.watch(clockProvider)().toLocal();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);

  final timer = Timer(nextMidnight.difference(now), ref.invalidateSelf);
  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(() {
    timer.cancel();
    lifecycle.dispose();
  });

  return CalendarDate.ofLocal(now);
});
