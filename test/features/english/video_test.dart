import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/features/english/data/video_lessons.dart';
import 'package:leera/features/english/presentation/english_topic_page.dart';
import 'package:leera/features/english/presentation/video_page.dart';

import '../../support/pump_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

void main() {
  final lesson = videoLessons.first;

  appTest('a talk opens on YouTube, and its notes wait until watched', (
    tester,
  ) async {
    final opened = <Uri>[];
    await pumpEnglishApp(tester, iPhonePortrait, onOpenUrl: opened.add);

    await _tap(tester, _key('nav-explore'));
    await _tap(tester, _key('video-${lesson.id}'));
    expect(find.byType(VideoPage), findsOneWidget);
    expect(find.text(lesson.listeningTip), findsOneWidget);

    await _tap(tester, _key('video-watch'));
    expect(opened, [Uri.parse('https://www.youtube.com/watch?v=${lesson.youtubeId}')]);

    // No spoilers.
    expect(find.text(lesson.summary), findsNothing);
    await _tap(tester, _key('video-show-notes'));
    expect(find.text(lesson.summary), findsOneWidget);
    expect(find.text(lesson.expressions.first.expression), findsOneWidget);

    // The five expressions go to the words.
    await _tap(tester, _key('video-keep'));
    expect(find.text('In your words to review'), findsOneWidget);
    await _tap(tester, _key('nav-journal'));
    expect(find.text(lesson.expressions.first.expression), findsOneWidget);
    expect(
      find.textContaining("From ${lesson.speaker}'s talk"),
      findsNWidgets(5),
    );
    expect(tester.takeException(), isNull);
  });

  appTest('a talk is retold as a session', (tester) async {
    await pumpEnglishApp(tester, iPhonePortrait);

    await _tap(tester, _key('nav-explore'));
    await _tap(tester, _key('video-${lesson.id}'));
    await _tap(tester, _key('video-retell'));

    expect(find.byType(EnglishTopicPage), findsOneWidget);
    expect(find.text(lesson.topic.title), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
