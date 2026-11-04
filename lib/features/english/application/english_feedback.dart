import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings.dart';

import '../data/backend_feedback_api.dart';
import '../data/practice_session_repository_provider.dart';
import '../data/topic_catalog.dart';
import '../domain/feedback_api.dart';
import '../domain/feedback_history.dart';
import '../domain/learner_profile.dart';
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
    ref.watch(settingsRepositoryProvider),
  ),
);

class FeedbackActions {
  FeedbackActions(this._repository, this._api, this._settings);

  final PracticeSessionRepository _repository;
  final FeedbackApi _api;
  final SettingsRepository _settings;

  /// Asks for the correction of [session]'s presentation and keeps it:
  /// what was written, or else the transcript of what was said. The tags of
  /// past recurring mistakes go with it, and what is known of the learner.
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
      learner: await _learner(history),
    );
    await _repository.saveFeedback(session.id, feedback);
    return feedback;
  }

  /// The latest level estimated, or else the one given in the welcome; the
  /// goal and first language given there.
  Future<LearnerProfile> _learner(FeedbackHistory history) async {
    // A setting cleared is stored empty.
    Future<String?> read(String key) async {
      final value = await _settings.watch(key).first;
      return value == null || value.trim().isEmpty ? null : value;
    }

    final estimated = history.level;
    final given = await read(SettingKeys.selfAssessedLevel);
    return LearnerProfile(
      level: estimated ?? given,
      levelSelfAssessed: estimated == null && given != null,
      goal: LearnerGoal.fromName(await read(SettingKeys.goal)),
      firstLanguage: await read(SettingKeys.firstLanguage),
    );
  }
}
