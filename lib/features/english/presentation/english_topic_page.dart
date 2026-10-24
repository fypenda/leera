import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/common/widgets/edge_swipe_back.dart';
import '../../../core/time/clock.dart';
import '../application/english_sessions.dart';
import '../data/practice_session_repository_provider.dart';
import '../data/topic_catalog.dart';
import '../domain/practice_session.dart';
import '../domain/practice_session_repository.dart';
import '../domain/restitution_format.dart';
import '../english_routes.dart';
import 'session_chrome.dart';
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
    void leave() => context.goNamed(englishRouteName);

    return EdgeSwipeBack(
      onBack: leave,
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.md,
                        AppSpacing.xl,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              RoundIconButton(
                                key: const ValueKey('session-leave'),
                                icon: Icons.chevron_left_rounded,
                                label: 'Back to Today',
                                onTap: leave,
                              ),
                              const Expanded(child: StepDots(current: 0)),
                              if (session.canReroll)
                                RoundIconButton(
                                  key: const ValueKey('another-topic'),
                                  icon: Icons.casino_outlined,
                                  label: 'Roll another topic',
                                  onTap: _busy ? null : _anotherTopic,
                                )
                              else
                                const SizedBox(width: 44),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg + 2),
                          const StepEyebrow(
                            icon: Icons.search_rounded,
                            label: 'Step 1 · Research',
                          ),
                          const SizedBox(height: AppSpacing.lg + 2),
                          _TopicCard(
                            title: topic.title,
                            prompt: topic.prompt,
                            categories: topic.categories,
                          ),
                          const SizedBox(height: AppSpacing.lg + 2),
                          _FormatRow(format: session.format),
                          const SizedBox(height: AppSpacing.lg + 2),
                          _NotesCard(
                            controller: _notes,
                            onChanged: _notesChanged,
                          ),
                          const SizedBox(height: AppSpacing.lg + 2),
                          _ResearchTimer(elapsed: elapsed),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: BottomActionButton(
                      key: const ValueKey('done-researching'),
                      label: "I'm ready, let's explain",
                      icon: Icons.arrow_forward_rounded,
                      onTap: _busy ? null : _doneResearching,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The topic drawn: its categories, title and what to find out, on the
/// design's peach card.
class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.title,
    required this.prompt,
    required this.categories,
  });

  final String title;
  final String prompt;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -30,
            bottom: -34,
            child: ExcludeSemantics(
              child: Icon(
                Icons.public_rounded,
                size: 150,
                color: Color(0x2E24323A),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final category in categories)
                      _Chip(label: categoryName(category)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md + 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    title,
                    key: const ValueKey('topic-title'),
                    style: const TextStyle(
                      fontFamily: displayFontFamily,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.6,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md + 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
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

/// A category without its emoji: "🏛️ History" is shown as "History".
String categoryName(String category) {
  final space = category.indexOf(' ');
  return space < 0 ? category : category.substring(space + 1).trim();
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    ),
  );
}

/// The format the dice chose: spoken or written, and how long.
class _FormatRow extends StatelessWidget {
  const _FormatRow({required this.format});

  final RestitutionFormat format;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.coralSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              format.spoken ? Icons.mic_none_rounded : Icons.edit_outlined,
              color: AppColors.coralStrong,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rolled format', style: textTheme.bodySmall),
                Text(
                  format.summary,
                  key: const ValueKey('topic-format'),
                  style: textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.coralSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: AppColors.coralStrong,
                ),
                SizedBox(width: 4),
                Text(
                  'Surprise',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.coralStrong,
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

/// The notes, taken without AI and saved as they are written.
class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.ink),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'My notes',
                  style: textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'AI-free',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md - 2),
          TextField(
            key: const ValueKey('research-notes'),
            controller: controller,
            onChanged: onChanged,
            minLines: 5,
            maxLines: 12,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: 'Write down what you find, in English.',
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Research away from the app, then come back. Your notes are '
            'saved as you write.',
            style: textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// How long the research has taken, out of the time it is given.
class _ResearchTimer extends StatelessWidget {
  const _ResearchTimer({required this.elapsed});

  /// Time since the research started.
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final over = elapsed >= researchTime;
    final shown = over ? researchTime : elapsed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      over ? "Time's up: present when ready" : 'Research time',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text.rich(
                  key: const ValueKey('research-time'),
                  TextSpan(
                    text: clock(shown),
                    children: [
                      TextSpan(
                        text: ' / ${clock(researchTime)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontFamily: displayFontFamily,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              value: shown.inSeconds / researchTime.inSeconds,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              color: over ? AppColors.accent : AppColors.highlight,
              backgroundColor: AppColors.surfaceMuted,
              semanticsLabel: 'Research time used',
            ),
          ),
        ],
      ),
    );
  }
}

/// A duration as minutes and seconds, "12:40".
String clock(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
