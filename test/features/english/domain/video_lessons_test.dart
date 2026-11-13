import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/time/calendar_date.dart';
import 'package:leera/features/english/application/english_videos.dart';
import 'package:leera/features/english/data/topic_catalog.dart';
import 'package:leera/features/english/data/video_lessons.dart';

void main() {
  test('each talk has its notes: five expressions, two sentences', () {
    expect(videoLessons, isNotEmpty);
    expect(videoLessons.map((l) => l.id).toSet(), hasLength(videoLessons.length));
    for (final lesson in videoLessons) {
      expect(lesson.youtubeId, matches(RegExp(r'^[A-Za-z0-9_-]{11}$')), reason: lesson.id);
      expect(lesson.expressions, hasLength(5), reason: lesson.id);
      expect(lesson.phrasings, hasLength(2), reason: lesson.id);
      expect(lesson.summary, isNotEmpty, reason: lesson.id);
      expect(lesson.listeningTip, isNotEmpty, reason: lesson.id);
      for (final item in lesson.expressions) {
        expect(item.example, isNotEmpty, reason: '${lesson.id}: ${item.expression}');
      }
      // A retelling's topic is found, but never in the catalog drawn from.
      expect(topicById(lesson.topic.id).title, lesson.topic.title);
      expect(topicCatalog.any((t) => t.id == lesson.topic.id), isFalse);
      expect(lesson.topic.themes, isNotEmpty);
    }
  });

  test('the talks whose expressions were kept are stored, and read back', () {
    final kept = {'grit': CalendarDate(2026, 11, 13)};
    final stored = encodeVideoWords(kept);
    expect(stored, 'grit@2026-11-13');
    expect(parseVideoWords(stored), kept);
    expect(parseVideoWords('garbage,@2026-11-13,x@2026-02-30'), isEmpty);
    expect(parseVideoWords(null), isEmpty);
  });
}
