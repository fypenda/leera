import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/common/widgets/design/emoji_badge.dart';
import '../../../core/common/widgets/design/soft_chip.dart';
import '../../../core/time/clock.dart';
import '../application/english_sessions.dart';
import '../data/practice_session_repository_provider.dart';
import '../data/topic_catalog.dart';
import '../domain/practice_session.dart';
import '../domain/practice_session_repository.dart';
import '../english_routes.dart';
import 'session_frame.dart';
import 'session_navigation.dart';

/// Step 1 of a session: the topic and format drawn at random, the research
/// timer, and notes taken without AI, saved as they are written.
class EnglishTopicPage extends StatelessWidget {
  const EnglishTopicPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return SessionLoader(
      sessionId: sessionId,
      builder: (context, session) => _Research(
        // A new topic starts afresh: notes and timer included.
        key: ValueKey('${session.id}/${session.topicId}'),
        session: session,
      ),
    );
  }
}

class _Research extends ConsumerStatefulWidget {
  const _Research({super.key, required this.session});

  final PracticeSession session;

  @override
  ConsumerState<_Research> createState() => _ResearchState();
}

class _ResearchState extends ConsumerState<_Research> {
  /// How long typing must pause before the notes are saved.
  static const _saveDelay = Duration(milliseconds: 800);

  late final _notes = TextEditingController(text: widget.session.notes);

  /// Read once, so a save can still be made while the page closes.
  late final PracticeSessionRepository _repository;
  Timer? _pendingSave;
  Timer? _ticker;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(practiceSessionRepositoryProvider);
    // The timer is redrawn every second from the session's start, so it is
    // right however long the page was away.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // Notes typed just before leaving are not lost.
    if (_pendingSave?.isActive ?? false) {
      _pendingSave!.cancel();
      unawaited(_save());
    }
    _notes.dispose();
    super.dispose();
  }

  void _notesChanged(String _) {
    _pendingSave?.cancel();
    _pendingSave = Timer(_saveDelay, () => unawaited(_save()));
  }

  Future<void> _save() async {
    final text = _notes.text;
    try {
      await _repository.saveNotes(widget.session.id, text);
    } on Object {
      if (mounted) _say('Your notes could not be saved.');
    }
  }

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _run(Future<void> Function() action, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object {
      if (mounted) _say(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _anotherTopic() => _run(
    () => ref.read(practiceSessionActionsProvider).reroll(widget.session),
    'Another topic could not be drawn.',
  );

  Future<void> _doneResearching() => _run(() async {
    _pendingSave?.cancel();
    await _repository.saveNotes(widget.session.id, _notes.text);
    final session = await _repository.startPresenting(widget.session.id);
    if (mounted) openSession(context, session);
  }, 'The session could not move on.');

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final topic = topicById(session.topicId);
    final sinceStart = ref
        .read(clockProvider)()
        .toUtc()
        .difference(session.startedAt);
    final elapsed = sinceStart.isNegative ? Duration.zero : sinceStart;

    return SessionFrame(
      leaveLabel: '← English',
      onLeave: () => context.goNamed(englishRouteName),
      currentStep: 0,
      action: session.canReroll
          ? SessionTopButton(
              key: const ValueKey('another-topic'),
              label: '🎲 Another topic',
              onTap: _busy ? () {} : _anotherTopic,
            )
          : null,
      start: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopicCard(
            title: topic.title,
            prompt: topic.prompt,
            categories: topic.categories,
            emoji: topic.emoji,
          ),
          const SizedBox(height: AppSpacing.lg + 4),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              _InfoTile(
                leading: EmojiBadge(
                  session.format.emoji,
                  background: AppColors.coralSoft,
                  size: 52,
                ),
                caption: 'Format drawn by the dice ✨',
                value: session.format.summary,
              ),
              _TimerTile(elapsed: elapsed),
            ],
          ),
        ],
      ),
      end: SessionCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '📝 My notes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SoftChip(
                  '🚫🤖 No AI',
                  background: AppColors.primarySoft,
                  foreground: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const ValueKey('research-notes'),
              controller: _notes,
              onChanged: _notesChanged,
              minLines: 8,
              maxLines: 14,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: 'Write down what you find, in English.',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.all(AppSpacing.lg + 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Research away from the app, then come back to present. '
              'Your notes are saved as you write.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg + 4),
            FilledButton(
              key: const ValueKey('done-researching'),
              onPressed: _busy ? null : _doneResearching,
              child: const Text("I'm done, let's present 🚀"),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.title,
    required this.prompt,
    required this.categories,
    required this.emoji,
  });

  final String title;
  final String prompt;
  final List<String> categories;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(minHeight: 320),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -36,
            child: ExcludeSemantics(
              child: Text(emoji, style: const TextStyle(fontSize: 150)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final category in categories)
                      SoftChip(category, background: AppColors.surface),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    title,
                    key: const ValueKey('topic-title'),
                    style: const TextStyle(
                      fontFamily: displayFontFamily,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      letterSpacing: -0.8,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 330),
                  child: Text(
                    prompt,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink,
                      fontSize: 17,
                    ),
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

/// A small white tile, a badge and two lines of text.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.leading,
    required this.caption,
    required this.value,
  });

  final Widget leading;
  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption, style: textTheme.bodySmall),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(fontSize: 17),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerTile extends StatelessWidget {
  const _TimerTile({required this.elapsed});

  /// Time since the research started.
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final over = elapsed >= researchTime;
    final shown = over ? researchTime : elapsed;

    return _InfoTile(
      leading: SizedBox(
        width: 52,
        height: 52,
        child: CircularProgressIndicator(
          value: shown.inSeconds / researchTime.inSeconds,
          strokeWidth: 6,
          strokeCap: StrokeCap.round,
          color: over ? AppColors.accent : AppColors.highlight,
          backgroundColor: AppColors.surfaceMuted,
          semanticsLabel: 'Research time used',
        ),
      ),
      caption: over ? "⏱️ Time's up" : '⏱️ Research',
      value: over
          ? 'Present when ready'
          : '${clock(shown)} / ${clock(researchTime)}',
    );
  }
}

/// A duration as minutes and seconds, "12:40".
String clock(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
