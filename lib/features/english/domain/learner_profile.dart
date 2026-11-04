/// Why someone learns English. Sent with each correction, so it fits them.
enum LearnerGoal {
  work('For work', 'Meetings, emails, presentations'),
  studies('For my studies', 'Lectures, essays, academic English'),
  exam('For an exam', 'IELTS, TOEFL, Cambridge…'),
  travel('To travel', 'Getting around, meeting people'),
  everyday('For myself', 'Films, books, everyday life');

  const LearnerGoal(this.label, this.detail);

  final String label;
  final String detail;

  static LearnerGoal? fromName(String? name) {
    for (final goal in values) {
      if (goal.name == name) return goal;
    }
    return null;
  }
}

/// The first languages offered in the welcome; any other can be typed.
const commonFirstLanguages = [
  'French',
  'Spanish',
  'Portuguese',
  'Arabic',
  'Wolof',
  'Swahili',
  'Hindi',
  'Chinese',
  'Japanese',
  'Korean',
  'German',
  'Italian',
  'Russian',
  'Turkish',
];

/// A first language as the backend takes it: letters, spaces, apostrophes
/// and hyphens, 40 at most; null when there is none worth sending.
String? cleanFirstLanguage(String? language) {
  final trimmed = language?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed == null || trimmed.isEmpty || trimmed.length > 40) return null;
  return RegExp(r"^[\p{L} '-]+$", unicode: true).hasMatch(trimmed)
      ? trimmed
      : null;
}

/// What a correction is tuned to. Every part is optional.
class LearnerProfile {
  const LearnerProfile({
    this.level,
    this.levelSelfAssessed = false,
    this.goal,
    this.firstLanguage,
  });

  /// The latest level estimated, or else the one the person gave.
  final String? level;

  /// True while [level] is the person's own estimate.
  final bool levelSelfAssessed;
  final LearnerGoal? goal;
  final String? firstLanguage;

  /// The `learner` object of a feedback request: only what is known.
  Map<String, Object?> toJson() => {
    if (level != null) 'level': level,
    if (level != null) 'levelSelfAssessed': levelSelfAssessed,
    if (goal != null) 'goal': goal!.name,
    if (cleanFirstLanguage(firstLanguage) case final language?)
      'firstLanguage': language,
  };
}
