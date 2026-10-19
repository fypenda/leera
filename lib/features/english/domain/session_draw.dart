import 'dart:math';

import 'practice_topic.dart';
import 'restitution_format.dart';

/// How many of the latest topics a draw avoids, so the same subject does not
/// come back too soon.
const recentTopicsAvoided = 10;

/// The chance that a draw asks for a spoken presentation rather than a
/// written one. Speaking is favoured: writing can be polished, speaking
/// shows what has become automatic.
const spokenChance = 0.6;

/// A topic and a format, drawn at random from [catalog].
///
/// Topics among [recentTopicIds] (the latest first; only the first
/// [recentTopicsAvoided] count) and [excluding] are left out. If that would
/// leave nothing, only [excluding] is left out, and if even that leaves
/// nothing, any topic may come.
({PracticeTopic topic, RestitutionFormat format}) drawSession({
  required List<PracticeTopic> catalog,
  required Iterable<String> recentTopicIds,
  required Random random,
  String? excluding,
}) {
  if (catalog.isEmpty) throw ArgumentError('There is no topic to draw.');

  final recent = recentTopicIds.take(recentTopicsAvoided).toSet();
  var candidates = [
    for (final topic in catalog)
      if (!recent.contains(topic.id) && topic.id != excluding) topic,
  ];
  if (candidates.isEmpty) {
    candidates = [
      for (final topic in catalog)
        if (topic.id != excluding) topic,
    ];
  }
  if (candidates.isEmpty) candidates = catalog;

  final topic = candidates[random.nextInt(candidates.length)];
  final spoken = random.nextDouble() < spokenChance;
  final formats = [
    for (final format in RestitutionFormat.values)
      if (format.spoken == spoken) format,
  ];
  return (topic: topic, format: formats[random.nextInt(formats.length)]);
}
