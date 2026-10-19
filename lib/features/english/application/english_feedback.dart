import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backend_feedback_api.dart';
import '../data/practice_session_repository_provider.dart';
import '../data/topic_catalog.dart';
import '../domain/feedback_api.dart';
import '../domain/feedback_history.dart';
import '../domain/practice_session.dart';
import '../domain/practice_session_repository.dart';
import '../domain/session_feedback.dart';

/// Every correction received, by session id. Emits again whenever one is
/// saved.
///
/// A failure is not retried automatically: it stays visible until someone
/// asks to try again, by invalidating this provider.
final feedbacksProvider = StreamProvider<Map<String, SessionFeedback>>(
  (ref) => ref.watch(practiceSessionRepositoryProvider).watchFeedbacks(),
  retry: (retryCount, error) => null,
);

/// What the corrections add up to: level, recurring mistakes, vocabulary.
final feedbackHistoryProvider = Provider<AsyncValue<FeedbackHistory>>(
  (ref) => ref
      .watch(feedbacksProvider)
      .whenData((feedbacks) => FeedbackHistory(feedbacks.values)),
);

final feedbackActionsProvider = Provider<FeedbackActions>(
  (ref) => FeedbackActions(
    ref.watch(practiceSessionRepositoryProvider),
    ref.watch(feedbackApiProvider),
  ),
);

class FeedbackActions {
  FeedbackActions(this._repository, this._api);

  final PracticeSessionRepository _repository;
  final FeedbackApi _api;

  /// Asks for the correction of [session]'s presentation and keeps it:
  /// what was written, or else the transcript of what was said. The tags of
  /// past recurring mistakes go with it.
  ///
  /// Throws a `BackendException` if no correction comes back, and a
  /// [StateError] if there is no text to correct.
  Future<SessionFeedback> requestFor(PracticeSession session) async {
    final written = session.presentation;
    final transcript = written == null
        ? (await _repository.watchRecordings().first)[session.id]?.transcript
        : null;
    final presentation = written ?? transcript;
    if (!session.isCompleted ||
        presentation == null ||
        presentation.trim().isEmpty) {
      throw StateError('Only a sent presentation with text can be corrected.');
    }
    final history = FeedbackHistory(
      (await _repository.watchFeedbacks().first).values,
    );
    final feedback = await _api.requestFeedback(
      topic: topicById(session.topicId),
      format: session.format,
      presentation: presentation,
      spoken: written == null,
      recurringMistakes: history.recurringMistakes(),
    );
    await _repository.saveFeedback(session.id, feedback);
    return feedback;
  }
}
