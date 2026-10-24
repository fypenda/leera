import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/common/widgets/load_failure.dart';
import '../../../core/time/date_formatting.dart';
import '../../../core/time/today.dart';
import '../application/english_feedback.dart';
import '../application/english_recordings.dart';
import '../application/english_sessions.dart';
import '../domain/feedback_history.dart';
import '../domain/practice_stats.dart';
import '../domain/progress_summary.dart';
import '../domain/session_feedback.dart';

/// "Progress" in the Leera design: the streak, the estimated level on the
/// way to C1, the average score week by week, what was done, and what to
/// work on.
///
/// Everything is calculated from what is stored on the iPhone.
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  /// Wider than this (an iPad), the page keeps a phone-like column.
  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(practiceStatsProvider);
    final history = ref.watch(feedbackHistoryProvider);
    final recordings = ref.watch(recordingsProvider).value ?? const {};
    final today = ref.watch(todayProvider);

    final Widget body = switch ((stats, history)) {
      (AsyncData(value: final stats), AsyncData(value: final history)) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Title(streak: stats.streak),
            const SizedBox(height: AppSpacing.lg + 2),
            _LevelCard(history: history),
            const SizedBox(height: AppSpacing.lg + 2),
            _ScoreChart(weeks: weeklyScores(history.all, today)),
            const SizedBox(height: AppSpacing.lg + 2),
            _Totals(
              stats: stats,
              spoken: [
                for (final session in stats.completed)
                  ?recordings[session.id]?.duration,
              ].fold(Duration.zero, (total, length) => total + length),
              words: history.vocabulary.length,
            ),
            if (focusArea(history) case final focus?) ...[
              const SizedBox(height: AppSpacing.lg + 2),
              _FocusCard(focus: focus),
            ],
          ],
        ),
      (AsyncError(), _) || (_, AsyncError()) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Title(streak: 0),
          const SizedBox(height: AppSpacing.xl),
          LoadFailure(
            message: 'Your progress could not be loaded.',
            onRetry: () => ref
              ..invalidate(practiceSessionsProvider)
              ..invalidate(feedbacksProvider),
          ),
        ],
      ),
      _ => const _Title(streak: 0),
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Text(
          'Progress',
          style: TextStyle(
            fontFamily: displayFontFamily,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.7,
            color: AppColors.ink,
          ),
        ),
      ),
      if (streak > 0)
        Container(
          key: const ValueKey('progress-streak'),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                size: 16,
                color: AppColors.coralStrong,
              ),
              const SizedBox(width: 6),
              Text(
                streak == 1 ? '1 day' : '$streak days',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.coralStrong,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// The latest estimated level, as a ring on the way to C1.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.history});

  final FeedbackHistory history;

  @override
  Widget build(BuildContext context) {
    final level = history.level;
    final progress = level == null ? 0.0 : progressTowardsC1(level);
    final percent = (progress * 100).round();

    final String headline;
    final String detail;
    if (level == null) {
      headline = 'No level yet';
      detail = 'Your first correction will estimate it.';
    } else if (progress >= 1) {
      headline = 'C1 reached';
      detail = 'Estimated from your latest correction.';
    } else {
      headline = '$percent% of the way to C1';
      detail = 'Estimated from your latest correction.';
    }

    return Container(
      key: const ValueKey('progress-level'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Semantics(
            label: level == null
                ? 'No level yet'
                : 'Level $level, $percent% of the way to C1',
            excludeSemantics: true,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    color: AppColors.highlight,
                    backgroundColor: const Color(0xFF3A4A53),
                  ),
                  Center(
                    child: Text(
                      level ?? '–',
                      style: const TextStyle(
                        fontFamily: displayFontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTIMATED LEVEL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: Color(0xFFBFE9EF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  headline,
                  style: const TextStyle(
                    fontFamily: displayFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: AppColors.background,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD5DCE0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The average score of each of the last eight weeks, as bars.
class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.weeks});

  final List<WeeklyScore> weeks;

  static const double _barArea = 100;

  @override
  Widget build(BuildContext context) {
    final empty = weeks.every((week) => week.average == null);

    return _WhiteCard(
      key: const ValueKey('progress-chart'),
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Average score',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                'Last 8 weeks',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (index, week) in weeks.indexed) ...[
                    if (index > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _Bar(
                        week: week,
                        current: index == weeks.length - 1,
                        area: _barArea,
                      ),
                    ),
                  ],
                ],
              ),
              if (empty)
                const Positioned.fill(
                  bottom: 24,
                  child: Center(
                    child: Text(
                      'Your scores will show here.',
                      key: ValueKey('progress-chart-empty'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.week, required this.current, required this.area});

  final WeeklyScore week;
  final bool current;
  final double area;

  @override
  Widget build(BuildContext context) {
    final average = week.average;
    final label = formatShortDate(week.monday);

    return Semantics(
      label: average == null
          ? 'Week of $label: no correction'
          : 'Week of $label: ${average.toStringAsFixed(1)} out of 10',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: area,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: average == null ? 4 : (average / 10 * area).clamp(4.0, area),
                decoration: BoxDecoration(
                  color: average == null
                      ? AppColors.surfaceMuted.withValues(alpha: 0.5)
                      : current
                      ? AppColors.highlight
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              current ? 'Now' : label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Topics done, time spoken and words kept.
class _Totals extends StatelessWidget {
  const _Totals({
    required this.stats,
    required this.spoken,
    required this.words,
  });

  final PracticeStats stats;
  final Duration spoken;
  final int words;

  @override
  Widget build(BuildContext context) {
    final topics = stats.completed.length;

    return Row(
      children: [
        Expanded(
          child: _Total(
            key: const ValueKey('progress-topics'),
            icon: Icons.public_rounded,
            background: AppColors.primarySoft,
            foreground: AppColors.primary,
            value: '$topics',
            label: topics == 1 ? 'Topic' : 'Topics',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Total(
            key: const ValueKey('progress-spoken'),
            icon: Icons.mic_none_rounded,
            background: AppColors.coralSoft,
            foreground: AppColors.coralStrong,
            value: formatSpokenTime(spoken),
            label: 'Spoken',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Total(
            key: const ValueKey('progress-words'),
            icon: Icons.bookmark_border_rounded,
            background: AppColors.accentSoft,
            foreground: AppColors.accentStrong,
            value: '$words',
            label: words == 1 ? 'Word' : 'Words',
          ),
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    radius: 20,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: foreground),
        ),
        const SizedBox(height: AppSpacing.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: displayFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ),
  );
}

/// The criterion to work on, and the mistake that comes back most.
class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.focus});

  final FocusArea focus;

  static const _icons = {
    'grammar': Icons.text_fields_rounded,
    'vocabulary': Icons.menu_book_outlined,
    'naturalness': Icons.waves_rounded,
    'structure': Icons.layers_outlined,
    'content': Icons.lightbulb_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final mistake = focus.mistake;

    return _WhiteCard(
      key: const ValueKey('progress-focus'),
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.coralSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _icons[focus.criterion] ?? Icons.flag_outlined,
              size: 20,
              color: AppColors.coralStrong,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus area: ${focus.criterion}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  mistake == null
                      ? 'Your lowest score lately, '
                            '${focus.average.toStringAsFixed(1)} on average'
                      : 'Mistake that comes back most: $mistake',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    super.key,
    required this.radius,
    required this.padding,
    required this.child,
  });

  final double radius;
  final EdgeInsets padding;
  final Widget child;

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
