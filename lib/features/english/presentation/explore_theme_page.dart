import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/common/widgets/edge_swipe_back.dart';
import '../application/english_sessions.dart';
import '../data/topic_catalog.dart';
import '../domain/practice_topic.dart';
import '../english_routes.dart';
import 'session_chrome.dart';
import 'session_navigation.dart';
import 'theme_style.dart';

/// The topics of one theme, to choose one and research it.
class ExploreThemePage extends ConsumerWidget {
  const ExploreThemePage({super.key, required this.theme});

  final String theme;

  static const double _maxWidth = 560;

  void _leave(BuildContext context) => context.goNamed(exploreRouteName);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = [
      for (final topic in topicCatalog)
        if (topic.themes.contains(theme)) topic,
    ];
    final done = {
      for (final session
          in ref.watch(practiceStatsProvider).value?.completed ?? const [])
        session.topicId,
    };
    final style = themeStyle(theme);

    return EdgeSwipeBack(
      onBack: () => _leave(context),
      child: Scaffold(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RoundIconButton(
                        key: const ValueKey('theme-back'),
                        icon: Icons.chevron_left_rounded,
                        label: 'Back to Explore',
                        onTap: () => _leave(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: style.background,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            style.icon,
                            size: 24,
                            color: style.foreground,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            theme,
                            style: const TextStyle(
                              fontFamily: displayFontFamily,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              letterSpacing: -0.6,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      topics.isEmpty
                          ? 'No topic in this theme yet.'
                          : '${topics.length == 1 ? '1 topic' : '${topics.length} topics'}'
                                '. Choose one to research it now.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg + 2),
                    for (final topic in topics) ...[
                      _TopicTile(
                        topic: topic,
                        theme: theme,
                        done: done.contains(topic.id),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicTile extends ConsumerWidget {
  const _TopicTile({
    required this.topic,
    required this.theme,
    required this.done,
  });

  final PracticeTopic topic;

  /// The theme shown: its other themes are named on the tile.
  final String theme;
  final bool done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final others = [
      for (final other in topic.themes)
        if (other != theme) other,
    ];

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey('topic-${topic.id}'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          // Above the tab bar, not under it.
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (sheet) => _TopicSheet(topic: topic, parent: context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  if (done) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey('topic-done'),
                      size: 20,
                      color: AppColors.highlight,
                      semanticLabel: 'Done',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                topic.prompt,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              if (others.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final other in others)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: themeStyle(other).background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          other,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: themeStyle(other).foreground,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A topic, with the button to research it now. With a session already in
/// progress, it offers to finish that one first.
class _TopicSheet extends ConsumerWidget {
  const _TopicSheet({required this.topic, required this.parent});

  final PracticeTopic topic;

  /// The page under the sheet, which navigates once the sheet is closed.
  final BuildContext parent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgress = ref.watch(sessionInProgressProvider).value;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              topic.title,
              style: const TextStyle(
                fontFamily: displayFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              topic.prompt,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (inProgress == null)
              BottomActionButton(
                buttonKey: const ValueKey('start-topic'),
                label: 'Research this topic',
                icon: Icons.arrow_forward_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  startSessionOn(parent, ref, topic);
                },
              )
            else ...[
              Text(
                'Finish the session you started first: '
                '${topicById(inProgress.topicId).title}.',
                key: const ValueKey('session-in-progress'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              BottomActionButton(
                buttonKey: const ValueKey('continue-session'),
                label: 'Continue my session',
                icon: Icons.arrow_forward_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  openSession(parent, inProgress);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
