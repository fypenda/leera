import 'package:leera/core/ai/backend_client.dart';
import 'package:leera/core/auth/apple_sign_in.dart';
import 'package:leera/core/auth/quota.dart';
import 'package:leera/core/auth/session.dart';
import 'package:leera/features/english/domain/feedback_api.dart';
import 'package:leera/features/english/domain/practice_topic.dart';
import 'package:leera/features/english/domain/restitution_format.dart';
import 'package:leera/features/english/domain/session_feedback.dart';

/// A session kept in memory, in place of the Keychain.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this.session]);

  Session? session;

  @override
  Future<Session?> read() async => session;

  @override
  Future<void> write(Session session) async => this.session = session;

  @override
  Future<void> clear() async => session = null;
}

Session testSession() => Session(
  accessToken: 'test-session',
  expiresAt: DateTime.utc(2026, 11, 4),
);

Quota testQuota({Plan plan = Plan.free, int used = 0, int limit = 1}) => Quota(
  plan: plan,
  used: used,
  limit: limit,
  resetsAt: DateTime.utc(2026, 10, 12),
);

/// Sign in with Apple without Apple: gives [token], or null as if the
/// sheet were closed, and remembers the hashed nonces it was given.
class FakeAppleSignIn implements AppleSignIn {
  FakeAppleSignIn({this.token = 'apple-identity-token'});

  String? token;
  final hashedNonces = <String>[];

  @override
  Future<String?> identityToken({required String hashedNonce}) async {
    hashedNonces.add(hashedNonce);
    return token;
  }
}

/// The backend's account calls, answered from memory. Anything else fails
/// as if the backend could not be reached: nothing leaves the device in
/// tests, and a test that wants a correction gives a [FakeFeedbackApi].
class FakeBackendClient extends BackendClient {
  FakeBackendClient({Quota? quota, this.signInFailure})
    : currentQuota = quota ?? testQuota(),
      super(Uri.parse('http://backend.test'), () async => null);

  Quota currentQuota;
  BackendFailure? signInFailure;
  final signIns = <({String identityToken, String nonce})>[];
  final devSignIns = <String>[];
  var deletions = 0;

  @override
  Future<SignedIn> signInWithApple({
    required String identityToken,
    required String nonce,
  }) async {
    signIns.add((identityToken: identityToken, nonce: nonce));
    if (signInFailure case final failure?) throw BackendException(failure);
    return (session: testSession(), quota: currentQuota);
  }

  @override
  Future<SignedIn> devSignIn(String name) async {
    devSignIns.add(name);
    return (session: testSession(), quota: currentQuota);
  }

  @override
  Future<Quota> quota() async => currentQuota;

  @override
  Future<void> deleteAccount() async => deletions++;

  @override
  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  ) async => throw const BackendException(BackendFailure.unreachable);
}

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
