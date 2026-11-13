import 'session_feedback.dart';

/// An expression from a correction, with where it came from: one Claude
/// suggested, or a more natural phrasing of what the person said.
class KeptWord {
  const KeptWord({
    required this.item,
    required this.sessionId,
    required this.keptAt,
    this.phrasing = false,
    this.ofTheDay = false,
  });

  final VocabularyItem item;

  /// True for a more natural phrasing of the person's own words.
  final bool phrasing;

  /// True for an expression of the day, kept from its gift.
  final bool ofTheDay;

  /// The session whose correction suggested it; for an expression of the
  /// day, no session's.
  final String sessionId;
  final DateTime keptAt;

  /// The expression as compared: "Chokepoint " and "chokepoint" are one.
  String get key => normalizeExpression(item.expression);
}

String normalizeExpression(String expression) =>
    expression.trim().toLowerCase();

/// A phrasing longer than this is a sentence, not something to review.
const maxPhrasingLength = 60;

/// What one correction gives to keep: the expressions suggested, then the
/// more natural phrasings of what was said (the words that replace theirs).
List<KeptWord> wordsOf(String sessionId, SessionFeedback feedback) => [
  for (final item in feedback.vocabulary)
    KeptWord(item: item, sessionId: sessionId, keptAt: feedback.createdAt),
  for (final correction in feedback.corrections)
    if (correction.kind == CorrectionKind.naturalness &&
        correction.fix.trim().isNotEmpty &&
        correction.fix.trim().length <= maxPhrasingLength)
      KeptWord(
        item: VocabularyItem(
          correction.fix.trim(),
          correction.mistake.trim().isEmpty
              ? correction.explanation
              : 'Rather than “${correction.mistake.trim()}”. '
                    '${correction.explanation}',
          correction.corrected,
        ),
        sessionId: sessionId,
        keptAt: feedback.createdAt,
        phrasing: true,
      ),
];

/// Every expression and phrasing kept so far, each once (where it came
/// last), the latest first. [feedbacks] maps session ids to corrections;
/// [ofTheDay] are the expressions of the day kept.
List<KeptWord> keptWords(
  Map<String, SessionFeedback> feedbacks, {
  List<KeptWord> ofTheDay = const [],
}) {
  // Each correction's words stay together, in their order.
  final groups = [
    for (final MapEntry(key: sessionId, value: feedback) in feedbacks.entries)
      (feedback.createdAt, wordsOf(sessionId, feedback)),
    for (final word in ofTheDay) (word.keptAt, [word]),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  final seen = <String>{};
  return [
    for (final (_, words) in groups)
      for (final word in words)
        if (seen.add(word.key)) word,
  ];
}

/// The words matching [query] in their expression or meaning, ignoring
/// case. A blank query matches every word.
List<KeptWord> searchWords(List<KeptWord> words, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return words;
  return [
    for (final word in words)
      if (word.item.expression.toLowerCase().contains(needle) ||
          word.item.meaning.toLowerCase().contains(needle))
        word,
  ];
}
