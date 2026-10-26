/// A subject to research in English, then present.
///
/// Topics are reference data bundled with the app: a session stores only a
/// topic's [id], which must therefore never change.
class PracticeTopic {
  const PracticeTopic({
    required this.id,
    required this.title,
    required this.prompt,
    required this.categories,
    required this.emoji,
    required this.outline,
  });

  /// Stable identifier, stored with each session.
  final String id;

  /// The subject, in English.
  final String title;

  /// What to find out, in one or two sentences.
  final String prompt;

  /// Its categories, each with its emoji.
  final List<String> categories;

  /// The large illustration on the topic card.
  final String emoji;

  /// Questions that help structure the presentation.
  final List<String> outline;

  /// Its themes: the categories without their emoji ("History").
  List<String> get themes => [for (final c in categories) themeName(c)];
}

/// A category without its emoji: "🏛️ History" is the theme "History".
String themeName(String category) {
  final space = category.indexOf(' ');
  return space < 0 ? category : category.substring(space + 1).trim();
}
