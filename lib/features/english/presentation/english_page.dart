import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/auth_actions.dart';
import '../../../core/auth/quota.dart';
import '../../../core/auth/session.dart';
import '../../../core/common/widgets/design/emoji_badge.dart';
import '../../../core/common/widgets/design/soft_chip.dart';
import '../../../core/common/widgets/load_failure.dart';
import '../../../core/common/widgets/page_scaffold.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_formatting.dart';
import '../application/english_feedback.dart';
import '../application/english_recordings.dart';
import '../application/english_sessions.dart';
import '../data/topic_catalog.dart';
import '../domain/practice_session.dart';
import '../domain/session_feedback.dart';
import '../domain/session_recording.dart';
import 'daily_challenge_card.dart';
import 'session_navigation.dart';

/// The home page: today's challenge, the level reached and the
/// finished sessions.
class EnglishPage extends ConsumerWidget {
  const EnglishPage({super.key});

  static const double _wideWidth = 820;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgress = ref.watch(sessionInProgressProvider).value;
    final stats = ref.watch(practiceStatsProvider);
    final level = ref.watch(feedbackHistoryProvider).value?.level;
    final quota = ref.watch(quotaProvider).value;

    final challenge = DailyChallengeCard(
      continuing: inProgress != null,
      onStart: () => startOrContinueSession(context, ref),
    );
    final levelCard = _LevelCard(
      level: level,
      quota: quota,
      onOpenAccount: () => context.pushNamed(accountRouteName),
    );
    final sessions = stats.when(
      data: (stats) => FinishedSessions(sessions: stats.completed.take(5)),
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => LoadFailure(
        message: 'Your sessions could not be loaded.',
        onRetry: () => ref.invalidate(practiceSessionsProvider),
      ),
    );

    return PageScaffold(
      section: 'English',
      title: 'English 🇬🇧',
      subtitle: 'Research a topic, present it, get corrected, keep the words.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _wideWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                challenge,
                const SizedBox(height: AppSpacing.lg + 4),
                levelCard,
                const SizedBox(height: AppSpacing.lg + 4),
                sessions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: challenge),
              const SizedBox(width: AppSpacing.lg + 6),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    levelCard,
                    const SizedBox(height: AppSpacing.lg + 6),
                    sessions,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The level of the latest correction, on the way to C1, and the state of
/// AI correction.
class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.quota,
    required this.onOpenAccount,
  });

  /// Null before the first correction.
  final String? level;

  /// Null until it has been asked for.
  final Quota? quota;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final level = this.level;
    final quota = this.quota;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const EmojiBadge('🗣️', background: AppColors.primarySoft),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your level', style: textTheme.titleMedium),
                      Text(
                        level == null
                            ? 'Estimated after your first correction'
                            : 'Aiming for C1',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (level != null)
                  SoftChip(
                    level,
                    key: const ValueKey('english-level'),
                    background: AppColors.primarySoft,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LinearProgressIndicator(
              value: level == null ? 0 : progressTowardsC1(level),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              key: const ValueKey('open-account'),
              onPressed: onOpenAccount,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
              ),
              child: Text(
                quota == null
                    ? '👤 Your account'
                    : '👤 ${describeQuota(quota)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The finished sessions, each opening its feedback, or a word saying there
/// are none yet.
class FinishedSessions extends StatelessWidget {
  const FinishedSessions({
    super.key,
    required this.sessions,
    this.title = '🧾 Latest sessions',
  });

  final Iterable<PracticeSession> sessions;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: textTheme.titleMedium),
            if (sessions.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your finished sessions will appear here.',
                key: const ValueKey('no-finished-sessions'),
                style: textTheme.bodyMedium,
              ),
            ],
            for (final session in sessions) ...[
              const SizedBox(height: AppSpacing.md),
              PracticeSessionTile(
                session: session,
                onOpen: () => openSession(context, session),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A session: its topic, format and when it was finished.
class PracticeSessionTile extends ConsumerWidget {
  const PracticeSessionTile({
    super.key,
    required this.session,
    required this.onOpen,
  });

  final PracticeSession session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final finished = session.completedAt;
    final recording = ref.watch(recordingsProvider).value?[session.id];

    return Material(
      key: ValueKey('session-${session.id}'),
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppRadii.md + 2),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadii.md + 2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              EmojiBadge(
                session.format.emoji,
                background: AppColors.surface,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topicById(session.topicId).title,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        session.format.label,
                        if (finished != null)
                          formatCalendarDate(CalendarDate.ofLocal(finished)),
                        if (session.presentation != null) 'written',
                        if (recording != null)
                          '🎙️ ${formatRecordingLength(recording.duration)}',
                      ].join(' · '),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
