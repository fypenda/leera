import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leera/features/english/data/topic_catalog.dart';
import 'package:leera/features/english/domain/practice_topic.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/domain/session_draw.dart';

PracticeTopic _topic(String id) => PracticeTopic(
  id: id,
  title: id,
  prompt: '',
  categories: const [],
  emoji: '📝',
  outline: const [],
);

void main() {
  final catalog = [for (final id in ['a', 'b', 'c', 'd']) _topic(id)];

  test('never draws a recent topic while others are left', () {
    final random = Random(1);
    for (var i = 0; i < 200; i++) {
      final drawn = drawSession(
        catalog: catalog,
        recentTopicIds: const ['a', 'b', 'c'],
        random: random,
      );
      expect(drawn.topic.id, 'd');
    }
  });

  test('only the latest topics count as recent', () {
    final many = [for (var i = 0; i < 30; i++) _topic('t$i')];
    final recent = [for (var i = 0; i < 30; i++) 't$i'];
    final drawn = <String>{};
    final random = Random(2);
    for (var i = 0; i < 500; i++) {
      drawn.add(
        drawSession(
          catalog: many,
          recentTopicIds: recent,
          random: random,
        ).topic.id,
      );
    }

    expect(drawn, isNot(contains('t0')));
    expect(drawn, contains('t$recentTopicsAvoided'));
  });

  test('a reroll never draws the topic it replaces', () {
    final random = Random(3);
    for (var i = 0; i < 200; i++) {
      final drawn = drawSession(
        catalog: catalog,
        recentTopicIds: const ['a', 'b', 'c', 'd'],
        random: random,
        excluding: 'b',
      );
      expect(drawn.topic.id, isNot('b'));
    }
  });

  test('when every topic is recent, any but the excluded one may come', () {
    final drawn = drawSession(
      catalog: catalog,
      recentTopicIds: const ['a', 'b', 'c', 'd'],
      random: Random(4),
    );
    expect(catalog, contains(drawn.topic));
  });

  test('speaking comes more often than writing, and both come', () {
    final random = Random(5);
    var spoken = 0;
    const draws = 2000;
    for (var i = 0; i < draws; i++) {
      final format = drawSession(
        catalog: catalog,
        recentTopicIds: const [],
        random: random,
      ).format;
      if (format.spoken) spoken++;
    }

    expect(spoken / draws, closeTo(spokenChance, 0.05));
  });

  test('every format can be drawn', () {
    final random = Random(6);
    final seen = <RestitutionFormat>{};
    for (var i = 0; i < 1000; i++) {
      seen.add(
        drawSession(
          catalog: catalog,
          recentTopicIds: const [],
          random: random,
        ).format,
      );
    }
    expect(seen, RestitutionFormat.values.toSet());
  });

  test('refuses an empty catalog', () {
    expect(
      () => drawSession(
        catalog: const [],
        recentTopicIds: const [],
        random: Random(),
      ),
      throwsArgumentError,
    );
  });

  group('the bundled catalog', () {
    test('has topics with unique, stable-looking ids', () {
      final ids = [for (final topic in topicCatalog) topic.id];
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')));
      }
      expect(topicCatalog.length, greaterThan(recentTopicsAvoided));
    });

    test('every topic has a title, a prompt and an outline', () {
      for (final topic in topicCatalog) {
        expect(topic.title.trim(), isNotEmpty, reason: topic.id);
        expect(topic.prompt.trim(), isNotEmpty, reason: topic.id);
        expect(topic.outline, isNotEmpty, reason: topic.id);
        expect(topic.categories, isNotEmpty, reason: topic.id);
      }
    });

    test('a topic no longer in the catalog is still shown', () {
      expect(topicById('suez-canal').title, contains('Suez'));
      expect(topicById('gone').title, 'A topic no longer in the list');
    });
  });
}
