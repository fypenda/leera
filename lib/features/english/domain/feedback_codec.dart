import 'session_feedback.dart';

// Reads and writes a SessionFeedback as the JSON the backend sends.
//
// The same JSON is stored on the device, so these names are a contract with
// stored data as well as with the backend: unknown fields are ignored, so a
// backend may add some, but none of these may be renamed.

/// Builds a feedback from the backend's JSON. Throws a [FormatException],
/// naming the field, if it is not a usable feedback.
SessionFeedback decodeFeedback(Object? json) {
  final map = _map(json, 'feedback');
  final scores = _map(map['scores'], 'scores');
  try {
    return SessionFeedback(
      promptVersion: _string(map, 'promptVersion'),
      model: _string(map, 'model'),
      createdAt: _instant(map, 'createdAt'),
      estimatedLevel: _string(map, 'estimatedLevel'),
      headline: _string(map, 'headline'),
      summary: _string(map, 'summary'),
      scores: FeedbackScores(
        grammar: _int(scores, 'grammar'),
        vocabulary: _int(scores, 'vocabulary'),
        naturalness: _int(scores, 'naturalness'),
        structure: _int(scores, 'structure'),
        content: _int(scores, 'content'),
      ),
      corrections: [
        for (final item in _list(map, 'corrections'))
          _correction(_map(item, 'correction')),
      ],
      vocabulary: [
        for (final item in _list(map, 'vocabulary'))
          _vocabulary(_map(item, 'vocabulary item')),
      ],
      followUpQuestions: _strings(map, 'followUpQuestions'),
      recurringMistakesSeen: _strings(map, 'recurringMistakesSeen'),
    );
  } on ArgumentError catch (e) {
    throw FormatException('The feedback breaks a rule: ${e.name ?? e.message}.');
  }
}

/// The JSON of [feedback], as [decodeFeedback] reads it.
Map<String, Object?> encodeFeedback(SessionFeedback feedback) => {
  'promptVersion': feedback.promptVersion,
  'model': feedback.model,
  'createdAt': feedback.createdAt.toIso8601String(),
  'estimatedLevel': feedback.estimatedLevel,
  'headline': feedback.headline,
  'summary': feedback.summary,
  'scores': {
    'grammar': feedback.scores.grammar,
    'vocabulary': feedback.scores.vocabulary,
    'naturalness': feedback.scores.naturalness,
    'structure': feedback.scores.structure,
    'content': feedback.scores.content,
  },
  'corrections': [
    for (final c in feedback.corrections)
      {
        'kind': c.kind.name,
        'original': c.original,
        'corrected': c.corrected,
        'mistake': c.mistake,
        'fix': c.fix,
        'explanation': c.explanation,
        'tag': c.tag,
      },
  ],
  'vocabulary': [
    for (final v in feedback.vocabulary)
      {'expression': v.expression, 'meaning': v.meaning, 'example': v.example},
  ],
  'followUpQuestions': feedback.followUpQuestions,
  'recurringMistakesSeen': feedback.recurringMistakesSeen,
};

Correction _correction(Map<String, Object?> map) => Correction(
  kind: switch (_string(map, 'kind')) {
    'naturalness' => CorrectionKind.naturalness,
    _ => CorrectionKind.grammar,
  },
  original: _string(map, 'original'),
  corrected: _string(map, 'corrected'),
  mistake: _optionalString(map, 'mistake'),
  fix: _optionalString(map, 'fix'),
  explanation: _string(map, 'explanation'),
  tag: _optionalString(map, 'tag'),
);

VocabularyItem _vocabulary(Map<String, Object?> map) => VocabularyItem(
  _string(map, 'expression'),
  _string(map, 'meaning'),
  _optionalString(map, 'example'),
);

Map<String, Object?> _map(Object? value, String what) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  throw FormatException('The $what is not an object.');
}

String _string(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is String) return value;
  throw FormatException('"$field" is missing or is not text.');
}

String _optionalString(Map<String, Object?> map, String field) {
  final value = map[field];
  return value is String ? value : '';
}

int _int(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is int) return value;
  throw FormatException('"$field" is missing or is not a whole number.');
}

List<Object?> _list(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is List) return value;
  throw FormatException('"$field" is missing or is not a list.');
}

List<String> _strings(Map<String, Object?> map, String field) {
  final items = _list(map, field);
  if (items.any((item) => item is! String)) {
    throw FormatException('"$field" holds an item that is not text.');
  }
  return items.cast<String>().toList();
}

DateTime _instant(Map<String, Object?> map, String field) {
  final instant = DateTime.tryParse(_string(map, field));
  if (instant == null) throw FormatException('"$field" is not a date.');
  return instant.toUtc();
}
