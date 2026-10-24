/// The CEFR levels a correction can estimate, lowest first.
const cefrLevels = ['A2', 'B1', 'B1+', 'B2', 'B2+', 'C1', 'C1+', 'C2'];

/// How far [level] is on the way to C1, from 0 to 1. The goal is C1, so C1
/// and above are 1.
double progressTowardsC1(String level) {
  final index = cefrLevels.indexOf(level);
  final c1 = cefrLevels.indexOf('C1');
  if (index < 0) return 0;
  return (index / c1).clamp(0.0, 1.0);
}

/// The correction of one written presentation, as the backend returned it.
///
/// A feedback that exists is valid: the constructor rejects what the app
/// could not show with an [ArgumentError].
class SessionFeedback {
  SessionFeedback({
    required this.promptVersion,
    required this.model,
    required this.createdAt,
    required this.estimatedLevel,
    required this.headline,
    required this.summary,
    required this.scores,
    required this.corrections,
    required this.vocabulary,
    required this.followUpQuestions,
    required this.recurringMistakesSeen,
  }) {
    if (!cefrLevels.contains(estimatedLevel)) {
      throw ArgumentError.value(estimatedLevel, 'estimatedLevel');
    }
    if (headline.trim().isEmpty) {
      throw ArgumentError.value(headline, 'headline', 'Must not be blank.');
    }
    if (!createdAt.isUtc) {
      throw ArgumentError.value(createdAt, 'createdAt', 'Must be UTC.');
    }
  }

  /// The prompt that produced it, such as "feedback-v1".
  final String promptVersion;
  final String model;
  final DateTime createdAt;

  /// One of [cefrLevels].
  final String estimatedLevel;
  final String headline;
  final String summary;
  final FeedbackScores scores;
  final List<Correction> corrections;
  final List<VocabularyItem> vocabulary;
  final List<String> followUpQuestions;

  /// Tags of past mistakes that came back this time.
  final List<String> recurringMistakesSeen;
}

/// Each criterion, from 0 to 10.
class FeedbackScores {
  FeedbackScores({
    required this.grammar,
    required this.vocabulary,
    required this.naturalness,
    required this.structure,
    required this.content,
  }) {
    for (final (name, score) in criteria) {
      if (score < 0 || score > 10) {
        throw ArgumentError.value(score, name, 'Must be between 0 and 10.');
      }
    }
  }

  final int grammar;
  final int vocabulary;
  final int naturalness;
  final int structure;
  final int content;

  /// The five scores' mean, out of 10.
  double get average =>
      (grammar + vocabulary + naturalness + structure + content) / 5;

  /// Each criterion with its label, in display order.
  List<(String, int)> get criteria => [
    ('✏️ Grammar', grammar),
    ('📖 Vocabulary', vocabulary),
    ('🌊 Naturalness', naturalness),
    ('🧱 Structure', structure),
    ('🎯 Content', content),
  ];
}

enum CorrectionKind {
  /// A mistake.
  grammar,

  /// Correct, but not what a native speaker would say.
  naturalness,
}

/// A sentence as written, and as it should be.
class Correction {
  const Correction({
    required this.kind,
    required this.original,
    required this.corrected,
    required this.mistake,
    required this.fix,
    required this.explanation,
    required this.tag,
  });

  final CorrectionKind kind;
  final String original;
  final String corrected;

  /// The wrong words, as they appear in [original]. May be empty or not
  /// found, in which case nothing is highlighted.
  final String mistake;

  /// The words that replace them, as they appear in [corrected].
  final String fix;
  final String explanation;

  /// The kind of mistake, such as "prepositions".
  final String tag;
}

/// An expression worth keeping, with its meaning and an example.
class VocabularyItem {
  const VocabularyItem(this.expression, this.meaning, [this.example = '']);

  final String expression;
  final String meaning;
  final String example;
}
