import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common/random_source.dart';
import '../../../core/time/today.dart';
import '../data/practice_session_repository_provider.dart';
import '../data/topic_catalog.dart';
import '../domain/practice_session.dart';
import '../domain/practice_session_repository.dart';
import '../domain/practice_stats.dart';
import '../domain/session_draw.dart';

/// Every practice session, the latest started first. Emits again whenever
/// one changes, so screens always show what is saved.
///
/// A failure is not retried automatically: it stays visible until someone
/// asks to try again, by invalidating this provider.
final practiceSessionsProvider = StreamProvider<List<PracticeSession>>(
  (ref) => ref.watch(practiceSessionRepositoryProvider).watchSessions(),
  retry: (retryCount, error) => null,
);

/// The session in progress, if any: the latest one not completed.
final sessionInProgressProvider = Provider<AsyncValue<PracticeSession?>>(
  (ref) => ref
      .watch(practiceSessionsProvider)
      .whenData(
        (sessions) => sessions.where((s) => !s.isCompleted).firstOrNull,
      ),
);

/// What the sessions add up to today: streak, week, latest correction. It
/// follows the day as well as the sessions.
final practiceStatsProvider = Provider<AsyncValue<PracticeStats>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(practiceSessionsProvider)
      .whenData((sessions) => PracticeStats(sessions, today));
});

/// What a person can do with sessions that needs more than one step: drawing
/// a topic for a new session or for the one reroll.
final practiceSessionActionsProvider = Provider<PracticeSessionActions>(
  (ref) => PracticeSessionActions(
    ref.watch(practiceSessionRepositoryProvider),
    ref.watch(randomProvider),
  ),
);

class PracticeSessionActions {
  PracticeSessionActions(this._repository, this._random);

  final PracticeSessionRepository _repository;
  final Random _random;

  /// Starts a session on a topic and format drawn at random, avoiding the
  /// latest topics.
  Future<PracticeSession> start() async {
    final drawn = drawSession(
      catalog: topicCatalog,
      recentTopicIds: await _recentTopicIds(),
      random: _random,
    );
    return _repository.start(topicId: drawn.topic.id, format: drawn.format);
  }

  /// Draws the session's one other topic, never the one it has now.
  Future<PracticeSession> reroll(PracticeSession session) async {
    final drawn = drawSession(
      catalog: topicCatalog,
      recentTopicIds: await _recentTopicIds(),
      random: _random,
      excluding: session.topicId,
    );
    return _repository.reroll(
      session.id,
      topicId: drawn.topic.id,
      format: drawn.format,
    );
  }

  Future<List<String>> _recentTopicIds() async => [
    for (final session in await _repository.watchSessions().first)
      session.topicId,
  ];
}
