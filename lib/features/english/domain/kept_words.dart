import 'session_feedback.dart';

/// An expression suggested by a correction, with where it came from.
class KeptWord {
  const KeptWord({
    required this.item,
    required this.sessionId,
    required this.keptAt,
  });

  final VocabularyItem item;

  /// The session whose correction suggested it.
  final String sessionId;
  final DateTime keptAt;

  /// The expression as compared: "Chokepoint " and "chokepoint" are one.
  String get key => normalizeExpression(item.expression);
}

String normalizeExpression(String expression) =>
    expression.trim().toLowerCase();

/// Every expression suggested so far, each once (where it was suggested
/// last), the latest first. [feedbacks] maps session ids to corrections.
List<KeptWord> keptWords(Map<String, SessionFeedback> feedbacks) {
  final entries = feedbacks.entries.toList()
    ..sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));
  final seen = <String>{};
  return [
    for (final MapEntry(key: sessionId, value: feedback) in entries)
      for (final item in feedback.vocabulary)
        if (seen.add(normalizeExpression(item.expression)))
          KeptWord(item: item, sessionId: sessionId, keptAt: feedback.createdAt),
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
