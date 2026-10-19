import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/app.dart';
import 'package:leera/app/router.dart';
import 'package:leera/features/english/english_routes.dart';

import 'pump_app.dart';

/// Goes back to the home page, wherever the app is.
///
/// The app opens on it; this is for coming back to it after a test has
/// changed something behind its back (in the database, say).
Future<void> openEnglishHome(WidgetTester tester) async {
  ProviderScope.containerOf(
    tester.element(find.byType(EnglishApp)),
  ).read(routerProvider).goNamed(englishRouteName);
  await settle(tester);
}
