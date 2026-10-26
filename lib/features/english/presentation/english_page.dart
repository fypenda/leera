import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/auth_actions.dart';
import '../../../core/auth/quota.dart';
import '../../../core/auth/session.dart';
import '../../../core/common/widgets/load_failure.dart';
import '../../../core/settings/settings.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_formatting.dart';
import '../../../core/time/today.dart';
import '../application/english_feedback.dart';
import '../application/english_recordings.dart';
import '../application/english_sessions.dart';
import '../data/topic_catalog.dart';
import '../domain/practice_session.dart';
import '../domain/practice_stats.dart';
import '../domain/session_feedback.dart';
import '../domain/session_recording.dart';
import 'daily_challenge_card.dart';
import 'session_navigation.dart';

/// The home page, "Today" in the Leera design: a greeting, the week and its
/// streak, today's challenge, the level and the words kept, and the latest
/// topics.
class EnglishPage extends ConsumerWidget {
  const EnglishPage({super.key});

  /// Wider than this (an iPad), the page keeps a phone-like column.
  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgress = ref.watch(sessionInProgressProvider).value;
    final stats = ref.watch(practiceStatsProvider);
    final history = ref.watch(feedbackHistoryProvider).value;
    final quota = ref.watch(quotaProvider).value;
    final today = ref.watch(todayProvider);
    final hour = ref.watch(clockProvider)().toLocal().hour;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            // Not a ListView: everything is built, short as the page is.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    date: formatLongDate(DateTime(today.year, today.month, today.day)),
                    greeting: _greeting(hour),
                    onOpenAccount: () => context.pushNamed(accountRouteName),
                  ),
                  const SizedBox(height: AppSpacing.xl - 4),
                  switch (stats) {
                    AsyncData(value: final week) => _WeekCard(stats: week),
                    AsyncError() => LoadFailure(
                      message: 'Your sessions could not be loaded.',
                      onRetry: () => ref.invalidate(practiceSessionsProvider),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                  const SizedBox(height: AppSpacing.xl - 4),
                  DailyChallengeCard(
                    continuing: inProgress != null,
                    onStart: () => startOrContinueSession(context, ref),
                  ),
                  if (quota != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        describeQuota(quota),
                        key: const ValueKey('home-quota'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (quota.plan == Plan.free && quota.remaining == 0)
                      Center(
                        child: TextButton(
                          key: const ValueKey('home-open-plus'),
                          onPressed: () => context.pushNamed(plusRouteName),
                          child: const Text('Get Leera Plus'),
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.xl - 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LevelTile(
                          level: history?.level,
                          selfAssessed: ref
                              .watch(selfAssessedLevelProvider)
                              .value,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _WordsTile(words: history?.vocabulary.length ?? 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl - 4),
                  switch (stats) {
                    AsyncData(value: final recent) => RecentTopics(
                      sessions: recent.completed.take(5),
                      today: today,
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _greeting(int hour) => switch (hour) {
    < 12 => 'Good morning',
    < 18 => 'Good afternoon',
    _ => 'Good evening',
  };
}

/// The date, the greeting, and the way to the account.
class _Header extends StatelessWidget {
  const _Header({
    required this.date,
    required this.greeting,
    required this.onOpenAccount,
  });

  final String date;
  final String greeting;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                greeting,
                style: const TextStyle(
                  fontFamily: displayFontFamily,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  height: 1.05,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          button: true,
          label: 'Your account',
          child: Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              key: const ValueKey('open-account'),
              customBorder: const CircleBorder(),
              onTap: onOpenAccount,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The days of this week, practised or not, and the streak.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.stats});

  final PracticeStats stats;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final streak = stats.streak;

    return _Panel(
      key: const ValueKey('week-card'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Your week', style: textTheme.titleMedium)),
              if (streak > 0)
                Row(
                  key: const ValueKey('streak'),
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 18,
                      color: AppColors.coralStrong,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$streak-day streak',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.coralStrong,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (index, day) in stats.thisWeek.indexed)
                _Day(
                  letter: _letters[index],
                  done: stats.practisedOn(day),
                  isToday: day == stats.today,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.letter,
    required this.done,
    required this.isToday,
  });

  final String letter;
  final bool done;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
      color: isToday ? AppColors.text : AppColors.textMuted,
    );

    final Widget mark = switch ((done, isToday)) {
      (true, _) => Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.highlight,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 18, color: AppColors.ink),
      ),
      (false, true) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.coral, width: 2),
        ),
        child: const Icon(
          Icons.radio_button_checked_rounded,
          size: 14,
          color: AppColors.coralStrong,
        ),
      ),
      _ => Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
      ),
    };

    return Semantics(
      label: done ? 'Practised' : (isToday ? 'Today' : 'Not practised'),
      child: Column(
        children: [
          Text(letter, style: label),
          const SizedBox(height: 6),
          mark,
        ],
      ),
    );
  }
}

/// The level of the latest correction, on the way to C1.
class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.selfAssessed});

  /// Null before the first correction.
  final String? level;

  /// The level given in the welcome, shown until then.
  final String? selfAssessed;

  @override
  Widget build(BuildContext context) {
    final level = this.level ?? selfAssessed;
    return _Tile(
      icon: Icons.trending_up_rounded,
      iconColor: AppColors.primary,
      iconBackground: AppColors.primarySoft,
      title: level == null
          ? const Text('Level')
          : Row(
              key: const ValueKey('english-level'),
              children: [const Text('Level '), Text(level)],
            ),
      subtitle: level == null
          ? 'Estimated after your first correction'
          : this.level == null
          ? 'Your estimate · Goal: C1'
          : 'Goal: C1',
      progress: level == null ? 0 : progressTowardsC1(level),
      barColor: AppColors.highlight,
    );
  }
}

/// How many expressions the corrections have suggested.
class _WordsTile extends StatelessWidget {
  const _WordsTile({required this.words});

  final int words;

  /// What the bar fills towards.
  static const _goal = 100;

  @override
  Widget build(BuildContext context) => _Tile(
    icon: Icons.bookmark_border_rounded,
    iconColor: AppColors.accentStrong,
    iconBackground: AppColors.accentSoft,
    title: Text(words == 1 ? '1 word' : '$words words'),
    subtitle: 'Saved vocabulary',
    progress: (words / _goal).clamp(0.0, 1.0),
    barColor: AppColors.accent,
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.barColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Widget title;
  final String subtitle;
  final double progress;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _Panel(
      radius: 22,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.md - 2),
          DefaultTextStyle.merge(
            style: textTheme.titleMedium?.copyWith(fontSize: 15),
            child: title,
          ),
          Text(subtitle, style: textTheme.bodySmall?.copyWith(fontSize: 13)),
          const SizedBox(height: AppSpacing.md - 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: barColor,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The latest finished sessions, each opening its correction, or a word
/// saying there are none yet.
class RecentTopics extends ConsumerWidget {
  const RecentTopics({super.key, required this.sessions, required this.today});

  final Iterable<PracticeSession> sessions;
  final CalendarDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final feedbacks = ref.watch(feedbacksProvider).value ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recent topics',
          style: textTheme.headlineSmall?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        if (sessions.isEmpty)
          _Panel(
            radius: 18,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Your finished sessions will appear here.',
              key: const ValueKey('no-finished-sessions'),
              style: textTheme.bodyMedium,
            ),
          ),
        for (final session in sessions) ...[
          PracticeSessionTile(
            session: session,
            today: today,
            score: feedbacks[session.id]?.scores.average,
            onOpen: () => openSession(context, session),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
        ],
      ],
    );
  }
}

/// A finished session: its topic, how it was presented, when, and its
/// score once corrected.
class PracticeSessionTile extends ConsumerWidget {
  const PracticeSessionTile({
    super.key,
    required this.session,
    required this.today,
    required this.onOpen,
    this.score,
  });

  final PracticeSession session;
  final CalendarDate today;
  final VoidCallback onOpen;

  /// The correction's mean score, out of 10; null before it is corrected.
  final double? score;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final finished = session.completedAt;
    final recording = ref.watch(recordingsProvider).value?[session.id];
    final spoken = session.presentation == null;
    final score = this.score;

    return Material(
      key: ValueKey('session-${session.id}'),
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: spoken ? AppColors.coralSoft : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  spoken ? Icons.mic_none_rounded : Icons.edit_outlined,
                  size: 20,
                  color: spoken ? AppColors.coralStrong : AppColors.accentStrong,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topicById(session.topicId).title,
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        spoken ? 'Spoken' : 'Written',
                        if (recording != null)
                          formatRecordingLength(recording.duration),
                        if (finished != null)
                          formatRelativeDay(CalendarDate.ofLocal(finished), today),
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (score != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: displayFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A white, rounded panel, as the design's cards.
class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}
