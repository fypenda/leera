import '../../../core/time/calendar_date.dart';
import 'session_feedback.dart';

/// What all the corrections received add up to. Always calculated from the
/// stored feedback, never stored.
class FeedbackHistory {
  FeedbackHistory(Iterable<SessionFeedback> feedbacks)
    : all = feedbacks.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Every feedback, the latest first.
  final List<SessionFeedback> all;

  SessionFeedback? get latest => all.isEmpty ? null : all.first;

  /// The level of the latest correction, or null before the first one.
  String? get level => latest?.estimatedLevel;

  /// The tags of mistakes made at least twice, the most frequent first, at
  /// most [limit]. Sent with the next presentation so the coach can say
  /// when one comes back.
  List<String> recurringMistakes({int limit = 5}) {
    final counts = <String, int>{};
    for (final feedback in all) {
      for (final correction in feedback.corrections) {
        final tag = correction.tag.trim();
        if (tag.isEmpty || tag == 'other') continue;
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final recurring = counts.entries.where((e) => e.value >= 2).toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key),
      );
    return [for (final entry in recurring.take(limit)) entry.key];
  }

  /// Every expression suggested so far, each once, the latest first.
  List<VocabularyItem> get vocabulary {
    final seen = <String>{};
    return [
      for (final feedback in all)
        for (final item in feedback.vocabulary)
          if (seen.add(item.expression.trim().toLowerCase())) item,
    ];
  }

  /// One of the expressions kept, a different one each day, or null before
  /// there are any.
  VocabularyItem? wordOf(CalendarDate day) {
    final words = vocabulary;
    if (words.isEmpty) return null;
    final dayNumber = CalendarDate(1970, 1, 1).daysUntil(day);
    return words[dayNumber % words.length];
  }
}
