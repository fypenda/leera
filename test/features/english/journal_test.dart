import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/features/english/data/practice_session_repository_provider.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/domain/session_feedback.dart';
import 'package:leera/features/english/presentation/english_feedback_page.dart';
import 'package:leera/features/english/presentation/journal_page.dart';

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

void main() {
  appTest('before any correction, the journal says what will gather', (
    tester,
  ) async {
    await pumpEnglishApp(tester, iPhonePortrait);

    await _tap(tester, _key('nav-journal'));

    expect(find.byType(JournalPage), findsOneWidget);
    expect(_key('journal-no-words'), findsOneWidget);
    await _tap(tester, _key('journal-sessions'));
    expect(_key('journal-no-sessions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  appTest('the words kept can be searched, and open their correction', (
    tester,
  ) async {
    final container = await pumpEnglishApp(tester, iPhonePortrait);
    final repository = container.read(practiceSessionRepositoryProvider);
    await runInApp(tester, () async {
      final session = await repository.start(
        topicId: 'suez-canal',
        format: RestitutionFormat.shortEssay,
      );
      await repository.complete(session.id, presentation: 'The canal.');
      await repository.saveFeedback(
        session.id,
        sampleFeedback(
          vocabulary: const [
            VocabularyItem('chokepoint', 'a narrow passage', 'Suez is one.'),
            VocabularyItem('to bottleneck', 'to slow down'),
          ],
        ),
      );
    });
    await openEnglishHome(tester);

    await _tap(tester, _key('nav-journal'));

    expect(find.text('Words · 2'), findsOneWidget);
    expect(find.text('Sessions · 1'), findsOneWidget);
    expect(_key('word-chokepoint'), findsOneWidget);
    expect(_key('word-to bottleneck'), findsOneWidget);

    await tester.enterText(_key('journal-search'), 'slow');
    await settle(tester);
    expect(_key('word-chokepoint'), findsNothing);
    expect(_key('word-to bottleneck'), findsOneWidget);

    await tester.enterText(_key('journal-search'), 'zebra');
    await settle(tester);
    expect(_key('journal-no-match'), findsOneWidget);

    await tester.enterText(_key('journal-search'), '');
    await settle(tester);
    await _tap(tester, _key('word-chokepoint'));
    expect(find.byType(EnglishFeedbackPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
