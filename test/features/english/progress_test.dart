import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/features/english/data/practice_session_repository_provider.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/presentation/english_page.dart';
import 'package:leera/features/english/presentation/progress_page.dart';

import '../../support/fake_ai.dart';
import '../../support/navigation.dart';
import '../../support/pump_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await settle(tester);
}

void main() {
  appTest('before any correction, Progress says what will show there', (
    tester,
  ) async {
    await pumpEnglishApp(tester, iPhonePortrait);

    await _tap(tester, _key('nav-progress'));

    expect(find.byType(ProgressPage), findsOneWidget);
    expect(find.text('No level yet'), findsOneWidget);
    expect(_key('progress-chart-empty'), findsOneWidget);
    expect(_key('progress-streak'), findsNothing);
    expect(_key('progress-focus'), findsNothing);
    expect(tester.takeException(), isNull);

    // And back to Today.
    await _tap(tester, _key('nav-today'));
    expect(find.byType(EnglishPage), findsOneWidget);
  });

  appTest('a correction shows on Progress', (tester) async {
    await _pumpWithCorrection(tester, level: 'B2+');

    await _tap(tester, _key('nav-progress'));

    // B2+ is four steps of five on the way to C1.
    expect(find.text('80% of the way to C1'), findsOneWidget);
    expect(find.text('B2+'), findsOneWidget);
    expect(_key('progress-chart-empty'), findsNothing);
    expect(find.text('1 day'), findsOneWidget);
    expect(find.text('Topic'), findsOneWidget);
    expect(find.text('Focus area: naturalness'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  appTest('at the first level, Progress names the next one', (tester) async {
    await _pumpWithCorrection(tester, level: 'A2');

    await _tap(tester, _key('nav-progress'));

    expect(find.text('Next step: B1'), findsOneWidget);
    expect(find.textContaining('0%'), findsNothing);
  });
}

/// Starts the app with one finished session, corrected at [level].
Future<void> _pumpWithCorrection(
  WidgetTester tester, {
  required String level,
}) async {
  final container = await pumpEnglishApp(tester, iPhonePortrait);
  final repository = container.read(practiceSessionRepositoryProvider);
  await runInApp(tester, () async {
    final session = await repository.start(
      topicId: 'suez-canal',
      format: RestitutionFormat.shortEssay,
    );
    await repository.complete(session.id, presentation: 'The canal.');
    await repository.saveFeedback(session.id, sampleFeedback(level: level));
  });
  await openEnglishHome(tester);
}
