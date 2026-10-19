/// How a topic is presented once researched: spoken or written, with its
/// constraint. The format is drawn at random, like the topic.
enum RestitutionFormat {
  voiceNote(
    '🎙️',
    'Speaking',
    '2 min',
    spoken: true,
    speakingTime: Duration(minutes: 2),
  ),
  explainToAChild(
    '🧒',
    'Explain to a 10-year-old',
    '2 min',
    spoken: true,
    speakingTime: Duration(minutes: 2),
  ),
  tedIntro(
    '🎤',
    'TED-style intro',
    '1 min 30',
    spoken: true,
    speakingTime: Duration(minutes: 1, seconds: 30),
  ),
  debate(
    '⚖️',
    'For and against',
    '3 min',
    spoken: true,
    speakingTime: Duration(minutes: 3),
  ),
  shortEssay('✍️', 'Short essay', '250 to 350 words', spoken: false),
  keyFacts('📌', 'Five key facts', '5 sentences', spoken: false),
  expertEmail('📧', 'Email to an expert', '150 words', spoken: false);

  const RestitutionFormat(
    this.emoji,
    this.label,
    this.constraint, {
    required this.spoken,
    this.speakingTime,
  });

  /// How long to speak when a written format is presented aloud instead.
  static const defaultSpeakingTime = Duration(minutes: 2);

  final String emoji;
  final String label;

  /// Its length, in time or in words.
  final String constraint;

  /// Recorded aloud rather than written.
  final bool spoken;

  /// How long a spoken format aims for; null for a written one.
  final Duration? speakingTime;

  /// How long to aim for when speaking, whatever the format.
  Duration get targetSpeakingTime => speakingTime ?? defaultSpeakingTime;

  /// "Speaking · 2 min".
  String get summary => '$label · $constraint';
}
