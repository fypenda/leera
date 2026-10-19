import 'package:english_practice/core/ai/ai_settings.dart';
import 'package:english_practice/core/ai/backend_client.dart';
import 'package:english_practice/features/english/domain/feedback_api.dart';
import 'package:english_practice/features/english/domain/practice_topic.dart';
import 'package:english_practice/features/english/domain/restitution_format.dart';
import 'package:english_practice/features/english/domain/session_feedback.dart';

/// AI settings kept in memory, in place of the Keychain.
class InMemoryAiSettingsStore implements AiSettingsStore {
  InMemoryAiSettingsStore([this.settings]);

  AiSettings? settings;

  @override
  Future<AiSettings?> read() async => settings;

  @override
  Future<void> write(AiSettings settings) async => this.settings = settings;

  @override
  Future<void> clear() async => settings = null;
}

AiSettings testAiSettings() =>
    AiSettings(baseUrl: 'http://localhost:8080', appToken: 'test-token');

/// What a [FakeFeedbackApi] was asked.
typedef FeedbackCall = ({
  PracticeTopic topic,
  RestitutionFormat format,
  String presentation,
  bool spoken,
  List<String> recurringMistakes,
});

/// Answers with [answer], or fails with [failure], and remembers each call.
class FakeFeedbackApi implements FeedbackApi {
  FakeFeedbackApi({SessionFeedback? answer, this.failure})
    : answer = answer ?? sampleFeedback();

  SessionFeedback answer;
  BackendFailure? failure;
  final calls = <FeedbackCall>[];

  @override
  Future<SessionFeedback> requestFeedback({
    required PracticeTopic topic,
    required RestitutionFormat format,
    required String presentation,
    required bool spoken,
    required List<String> recurringMistakes,
  }) async {
    calls.add((
      topic: topic,
      format: format,
      presentation: presentation,
      spoken: spoken,
      recurringMistakes: recurringMistakes,
    ));
    if (failure case final failure?) throw BackendException(failure);
    return answer;
  }
}

SessionFeedback sampleFeedback({
  String level = 'B2+',
  List<String> tags = const ['false-friends'],
  List<VocabularyItem> vocabulary = const [
    VocabularyItem('chokepoint', 'a narrow passage', 'Suez is a chokepoint.'),
  ],
  DateTime? createdAt,
}) => SessionFeedback(
  promptVersion: 'feedback-v1',
  model: 'claude-test',
  createdAt: createdAt ?? DateTime.utc(2026, 10, 5, 10),
  estimatedLevel: level,
  headline: 'Clear and well built 🎉',
  summary: 'Good structure. Watch your prepositions.',
  scores: FeedbackScores(
    grammar: 7,
    vocabulary: 8,
    naturalness: 6,
    structure: 9,
    content: 8,
  ),
  corrections: [
    for (final tag in tags)
      Correction(
        kind: CorrectionKind.grammar,
        original: 'It permits to ships to avoid Africa',
        corrected: 'It allows ships to avoid Africa',
        mistake: 'permits to ships',
        fix: 'allows ships',
        explanation: '"Permit to" is a calque from French.',
        tag: tag,
      ),
  ],
  vocabulary: vocabulary,
  followUpQuestions: const ['What would a long closure do to prices?'],
  recurringMistakesSeen: const [],
);
