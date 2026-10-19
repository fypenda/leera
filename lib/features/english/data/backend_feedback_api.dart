import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/backend_client.dart';
import '../domain/feedback_api.dart';
import '../domain/feedback_codec.dart';
import '../domain/practice_topic.dart';
import '../domain/restitution_format.dart';
import '../domain/session_feedback.dart';

/// [FeedbackApi] backed by the app's backend (`POST /api/v1/english/feedback`).
class BackendFeedbackApi implements FeedbackApi {
  BackendFeedbackApi(this._client);

  final BackendClient _client;

  @override
  Future<SessionFeedback> requestFeedback({
    required PracticeTopic topic,
    required RestitutionFormat format,
    required String presentation,
    required bool spoken,
    required List<String> recurringMistakes,
  }) async {
    final answer = await _client.postJson('/api/v1/english/feedback', {
      'topicTitle': topic.title,
      'topicPrompt': topic.prompt,
      'formatLabel': format.label,
      'formatConstraint': format.constraint,
      'presentation': presentation,
      'recurringMistakes': recurringMistakes,
      'spoken': spoken,
    });
    try {
      return decodeFeedback(answer);
    } on FormatException catch (e) {
      throw BackendException(BackendFailure.unexpected, e.message);
    }
  }
}

/// Where corrections come from. Tests replace it with a fake.
final feedbackApiProvider = Provider<FeedbackApi>(
  (ref) => BackendFeedbackApi(ref.watch(backendClientProvider)),
);
