import 'practice_topic.dart';
import 'session_feedback.dart';

/// A talk on YouTube, chosen by hand, with notes to watch it with: a tip
/// before listening, then once watched a summary, five expressions heard
/// in it and two sentences said the way a native speaker says them.
///
/// The notes were written from the talk's transcript; every expression's
/// example and every sentence is quoted from it.
class VideoLesson {
  const VideoLesson({
    required this.id,
    required this.youtubeId,
    required this.title,
    required this.speaker,
    required this.minutes,
    required this.level,
    required this.category,
    required this.summary,
    required this.listeningTip,
    required this.expressions,
    required this.phrasings,
  });

  final String id;

  /// The video's id on YouTube: youtube.com/watch?v=<this>.
  final String youtubeId;
  final String title;
  final String speaker;

  /// About how long it lasts.
  final int minutes;

  /// The level it suits best, from B1 to C1.
  final String level;

  /// Its theme, with its emoji, as the topics have ("🧠 Psychology").
  final String category;

  /// What the talk says, in four or five sentences.
  final String summary;

  /// What to listen for, before watching.
  final String listeningTip;

  /// Five expressions heard in the talk: the meaning is ours, the example
  /// is the speaker's sentence.
  final List<VocabularyItem> expressions;

  /// Two sentences from the talk, and what makes each sound natural.
  final List<(String sentence, String why)> phrasings;

  Uri get youtubeUrl => Uri.https('www.youtube.com', '/watch', {'v': youtubeId});

  /// The video's picture, from YouTube.
  String get thumbnailUrl => 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';

  /// The topic of a session retelling it.
  PracticeTopic get topic => PracticeTopic(
    id: topicIdOf(id),
    title: 'Retell “$title”',
    prompt:
        "Watch $speaker's talk, then explain its main idea in your own "
        'words, with an example from it.',
    categories: [category],
    emoji: '🎬',
    outline: const [
      'What is the speaker’s main idea?',
      'Which example or story supports it best?',
      'Do you agree? Why, or why not?',
    ],
  );

  /// The topic id of a session on the lesson [id].
  static String topicIdOf(String id) => 'video-$id';
}
