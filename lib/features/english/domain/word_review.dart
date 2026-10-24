import '../../../core/time/calendar_date.dart';
import 'kept_words.dart';

/// Days until a word comes back, for each box: a word known moves up a
/// box, a word missed goes back to the first.
const reviewIntervals = [1, 3, 7, 14, 30, 60];

/// Where a kept word stands in its review.
class WordReview {
  WordReview({
    required this.key,
    required this.box,
    required this.dueOn,
    required this.reviewedAt,
  }) {
    if (key.trim().isEmpty) throw ArgumentError.value(key, 'key');
    if (box < 0 || box >= reviewIntervals.length) {
      throw ArgumentError.value(box, 'box');
    }
    if (!reviewedAt.isUtc) {
      throw ArgumentError.value(reviewedAt, 'reviewedAt', 'Must be UTC.');
    }
  }

  /// The word, as [KeptWord.key].
  final String key;
  final int box;
  final CalendarDate dueOn;
  final DateTime reviewedAt;

  bool isDueOn(CalendarDate day) => dueOn.daysUntil(day) >= 0;

  /// The review after an answer on [today]. [previous] is null for a word
  /// never reviewed: known straight away, it skips the first box.
  static WordReview answer({
    required String key,
    required WordReview? previous,
    required bool knew,
    required CalendarDate today,
    required DateTime now,
  }) {
    final box = !knew
        ? 0
        : previous == null
        ? 1
        : (previous.box + 1).clamp(0, reviewIntervals.length - 1);
    return WordReview(
      key: key,
      box: box,
      dueOn: today.addDays(reviewIntervals[box]),
      reviewedAt: now.toUtc(),
    );
  }
}

/// The words to review on [today], at most [limit]: those already reviewed
/// and due, the longest overdue first, then words never reviewed, the
/// latest kept first.
List<KeptWord> reviewQueue(
  List<KeptWord> words,
  Map<String, WordReview> reviews,
  CalendarDate today, {
  int limit = 20,
}) {
  final due = [
    for (final word in words)
      if (reviews[word.key] case final review? when review.isDueOn(today)) word,
  ]..sort((a, b) => reviews[a.key]!.dueOn.daysUntil(reviews[b.key]!.dueOn));
  final fresh = [
    for (final word in words)
      if (!reviews.containsKey(word.key)) word,
  ];
  return [...due, ...fresh].take(limit).toList();
}
