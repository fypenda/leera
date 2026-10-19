import 'practice_topic.dart';
import 'restitution_format.dart';
import 'session_feedback.dart';

/// Asks for the correction of a presentation: written, or the transcript of
/// a spoken one ([spoken]).
///
/// Only what the correction needs is sent: the topic, the format, the text
/// and the tags of recurring mistakes. Never the notes, never an identifier,
/// never audio.
abstract interface class FeedbackApi {
  /// Throws a `BackendException` saying why when no correction comes back.
  Future<SessionFeedback> requestFeedback({
    required PracticeTopic topic,
    required RestitutionFormat format,
    required String presentation,
    required bool spoken,
    required List<String> recurringMistakes,
  });
}
