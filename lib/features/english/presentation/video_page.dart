import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/common/widgets/edge_swipe_back.dart';
import '../../../core/motion/motion.dart';
import '../../../core/time/today.dart';
import '../application/english_sessions.dart';
import '../application/english_videos.dart';
import '../data/video_lessons.dart';
import '../domain/video_lesson.dart';
import '../english_routes.dart';
import 'session_chrome.dart';
import 'session_navigation.dart';
import 'theme_style.dart';

/// A talk to watch, then retell: the tip to listen with, the way to
/// YouTube, a session to explain it, and once watched, the notes.
class VideoPage extends ConsumerStatefulWidget {
  const VideoPage({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<VideoPage> {
  static const double _maxWidth = 560;

  /// The notes are hidden until the talk is watched: no spoilers.
  var _showNotes = false;

  void _leave() => context.goNamed(exploreRouteName);

  Future<void> _watch(VideoLesson lesson) async {
    Haptics.light();
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await ref.read(openExternalUrlProvider)(lesson.youtubeUrl);
    } on Object catch (e) {
      debugPrint('Opening YouTube failed: $e');
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('YouTube could not be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = videoLessonById(widget.videoId);
    if (lesson == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: TextButton(
              onPressed: _leave,
              child: const Text('This talk is no longer here. Back'),
            ),
          ),
        ),
      );
    }
    final retold = (ref.watch(practiceStatsProvider).value?.completed ?? const [])
        .any((session) => session.topicId == lesson.topic.id);
    final showNotes = _showNotes || retold;
    final style = themeStyle(lesson.topic.themes.first);

    return EdgeSwipeBack(
      onBack: _leave,
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
                  AppSpacing.xxl * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RoundIconButton(
                        key: const ValueKey('video-back'),
                        icon: Icons.chevron_left_rounded,
                        label: 'Back to Explore',
                        onTap: _leave,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    VideoThumbnail(
                      lesson: lesson,
                      onTap: () => _watch(lesson),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontFamily: displayFontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          lesson.speaker,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        _Chip('${lesson.minutes} min'),
                        _Chip(lesson.level),
                        _Chip(
                          lesson.topic.themes.first,
                          background: style.background,
                          foreground: style.foreground,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Step(
                      number: 1,
                      title: 'Watch it',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Note(
                            icon: Icons.hearing_rounded,
                            title: 'Before you watch',
                            text: lesson.listeningTip,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BottomActionButton(
                            buttonKey: const ValueKey('video-watch'),
                            label: 'Watch on YouTube',
                            icon: Icons.play_arrow_rounded,
                            onTap: () => _watch(lesson),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Step(
                      number: 2,
                      title: 'Retell it',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Explain the talk in your own words, spoken or '
                            'written. Claude corrects you, as for a topic.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            key: const ValueKey('video-retell'),
                            onPressed: () =>
                                startSessionOn(context, ref, lesson.topic),
                            icon: const Icon(Icons.mic_none_rounded),
                            label: const Text('Retell this talk'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(
                                color: AppColors.ink,
                                width: 1.5,
                              ),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Step(
                      number: 3,
                      title: 'Check the notes',
                      child: showNotes
                          ? _Notes(lesson: lesson)
                          : _HiddenNotes(
                              onShow: () => setState(() => _showNotes = true),
                            ),
                    ),
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

/// The talk's picture, with a play button; a coloured block without it.
class VideoThumbnail extends ConsumerWidget {
  const VideoThumbnail({
    super.key,
    required this.lesson,
    this.onTap,
    this.radius = 24,
    this.playSize = 64,
  });

  final VideoLesson lesson;
  final VoidCallback? onTap;
  final double radius;
  final double playSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = themeStyle(lesson.topic.themes.first);
    final fallback = ColoredBox(
      color: style.card,
      child: Center(
        child: Icon(style.icon, size: playSize * 0.9, color: style.foreground),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: 'Watch ${lesson.title} on YouTube',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ref.watch(showVideoThumbnailsProvider))
                  Image.network(
                    lesson.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : fallback,
                  )
                else
                  fallback,
                if (onTap != null)
                  Center(
                    child: Container(
                      width: playSize,
                      height: playSize,
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: playSize * 0.55,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.background, this.foreground});

  final String text;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background ?? AppColors.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: foreground ?? AppColors.ink,
      ),
    ),
  );
}

/// A numbered step of the page.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.child});

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.surface,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Text(
            title,
            style: const TextStyle(
              fontFamily: displayFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      child,
    ],
  );
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HiddenNotes extends StatelessWidget {
  const _HiddenNotes({required this.onShow});

  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      key: const ValueKey('video-show-notes'),
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Haptics.selection();
        onShow();
      },
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.lock_open_rounded, color: AppColors.ink),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Watched it? Show the summary, five expressions from the '
                'talk and two sentences to borrow.',
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The notes: the summary, the five expressions, the two sentences.
class _Notes extends ConsumerWidget {
  const _Notes({required this.lesson});

  final VideoLesson lesson;

  static const _heading = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
    color: AppColors.textMuted,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kept = ref.watch(keptVideosProvider).containsKey(lesson.id);

    return RiseIn(
      key: const ValueKey('video-notes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('IN SHORT', style: _heading),
          const SizedBox(height: AppSpacing.sm),
          Text(
            lesson.summary,
            style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('FIVE EXPRESSIONS FROM THE TALK', style: _heading),
          const SizedBox(height: AppSpacing.sm),
          for (final item in lesson.expressions) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.expression,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.meaning,
                    style: const TextStyle(fontSize: 14, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '“${item.example}”',
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            key: const ValueKey('video-keep'),
            onPressed: () {
              Haptics.selection();
              ref
                  .read(videoActionsProvider)
                  .keep(lesson.id, kept: !kept, day: ref.read(todayProvider))
                  .catchError((Object e) {
                    debugPrint('Keeping the expressions failed: $e');
                  });
            },
            icon: Icon(
              kept ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
            ),
            label: Text(
              kept
                  ? 'In your words to review'
                  : 'Keep the five expressions to review',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('TWO SENTENCES TO BORROW', style: _heading),
          const SizedBox(height: AppSpacing.sm),
          for (final (sentence, why) in lesson.phrasings) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“$sentence”',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    why,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
