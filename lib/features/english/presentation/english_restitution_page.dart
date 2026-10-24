import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/common/widgets/edge_swipe_back.dart';
import '../application/english_recordings.dart';
import '../data/practice_session_repository_provider.dart';
import '../data/topic_catalog.dart';
import '../domain/practice_session.dart';
import '../domain/restitution_format.dart';
import '../english_routes.dart';
import 'session_chrome.dart';
import 'session_navigation.dart';
import 'voice_recorder_panel.dart';

/// Step 2 of a session: presenting the topic, aloud or in writing, with the
/// notes hidden.
///
/// A written presentation is saved with the session; a spoken one is
/// recorded, and the recording kept with it.
class EnglishRestitutionPage extends StatelessWidget {
  const EnglishRestitutionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return SessionLoader(
      sessionId: sessionId,
      builder: (context, session) =>
          _Presentation(key: ValueKey(session.id), session: session),
    );
  }
}

class _Presentation extends ConsumerStatefulWidget {
  const _Presentation({super.key, required this.session});

  final PracticeSession session;

  @override
  ConsumerState<_Presentation> createState() => _PresentationState();
}

class _PresentationState extends ConsumerState<_Presentation> {
  /// Writing instead of speaking: the drawn format to start with, then the
  /// person's choice with the ✍️ button.
  late var _writing = !widget.session.format.spoken;
  late final _text = TextEditingController(
    text: widget.session.presentation ?? '',
  );
  var _sending = false;

  /// A take is in progress: the presentation is not sent mid-take.
  var _recordingBusy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final session = await ref
          .read(practiceSessionRepositoryProvider)
          .complete(
            widget.session.id,
            presentation: _writing ? _text.text : null,
          );
      if (mounted) openSession(context, session);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Your presentation could not be sent.'),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final topic = topicById(session.topicId);
    final textTheme = Theme.of(context).textTheme;
    final recorded =
        ref.watch(recordingsProvider).value?.containsKey(session.id) ?? false;
    // Speaking needs a recording to send; writing, nothing more.
    final canSend = _writing || (recorded && !_recordingBusy);
    // The design: teal to speak, soft peach to write.
    final background = _writing ? AppColors.accentSoft : AppColors.highlight;
    final eyebrowColor = _writing ? AppColors.accentStrong : AppColors.ink;
    void backToNotes() => context.goNamed(
      englishTopicRouteName,
      pathParameters: {englishSessionParameter: session.id},
    );

    return EdgeSwipeBack(
      onBack: backToNotes,
      child: Scaffold(
        backgroundColor: background,
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
                                label: 'Back to my notes',
                                onTap: backToNotes,
                              ),
                              Expanded(
                                child: StepDots(
                                  current: 1,
                                  color: _writing
                                      ? AppColors.accent
                                      : AppColors.ink,
                                  trackColor: AppColors.surface,
                                ),
                              ),
                              RoundIconButton(
                                key: const ValueKey('switch-format'),
                                icon: _writing
                                    ? Icons.mic_none_rounded
                                    : Icons.edit_outlined,
                                label: _writing
                                    ? 'Switch to speaking'
                                    : 'Switch to writing',
                                // Not mid-take: finish or leave the
                                // recording first.
                                onTap: _recordingBusy
                                    ? null
                                    : () => setState(() => _writing = !_writing),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg + 2),
                          StepEyebrow(
                            icon: _writing
                                ? Icons.edit_outlined
                                : Icons.mic_none_rounded,
                            label: _writing
                                ? 'Step 2 · Write'
                                : 'Step 2 · Speak · '
                                      '${session.format.constraint}',
                            color: eyebrowColor,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            topic.title,
                            style: const TextStyle(
                              fontFamily: displayFontFamily,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -0.3,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm + 2),
                          Text(
                            _writing
                                ? _writingInstruction(session.format)
                                : '${session.format.label}: explain it in '
                                      'English, as you would to a colleague. '
                                      'Your notes are hidden.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg + 4),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg + 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: _writing
                                ? _Writer(
                                    controller: _text,
                                    targetWords: _targetWords(session.format),
                                  )
                                : VoiceRecorderPanel(
                                    session: session,
                                    onBusyChanged: (busy) =>
                                        setState(() => _recordingBusy = busy),
                                  ),
                          ),
                          if (topic.outline.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _Outline(questions: topic.outline),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        BottomActionButton(
                          buttonKey: const ValueKey('send-for-feedback'),
                          label: session.isCompleted
                              ? 'See the feedback'
                              : 'Send for feedback',
                          icon: Icons.send_rounded,
                          onTap: _sending
                              ? null
                              : session.isCompleted
                              ? () => openSession(context, session)
                              : canSend
                              ? _send
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm + 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: AppColors.ink,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _writing || recorded
                                    ? 'AI only steps in now.'
                                    : 'Record your presentation to send it.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

/// What to write, from the format drawn.
String _writingInstruction(RestitutionFormat format) => format.spoken
    ? 'Write it instead, as a short article for a curious reader.'
    : '${format.label}, ${format.constraint}, for a curious reader.';

/// How many words to aim for, when the format says so: "250 to 350 words"
/// aims for 250. Null when it counts in something else, or nothing.
int? _targetWords(RestitutionFormat format) {
  final match = RegExp(
    r'(\d+)(?: to \d+)? words',
  ).firstMatch(format.constraint);
  return match == null ? null : int.parse(match.group(1)!);
}

/// Questions that help structure the presentation.
class _Outline extends StatelessWidget {
  const _Outline({required this.questions});

  final List<String> questions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_outlined, size: 18, color: AppColors.ink),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'To help you structure it',
                style: textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final (index, question) in questions.indexed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${index + 1}. $question',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.text),
              ),
            ),
        ],
      ),
    );
  }
}

/// Writing the presentation, without spellcheck or autocorrect, with a word
/// count.
class _Writer extends StatelessWidget {
  const _Writer({required this.controller, required this.targetWords});

  final TextEditingController controller;

  /// Null when the format sets no number of words.
  final int? targetWords;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final target = targetWords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your text',
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const ValueKey('written-presentation'),
          controller: controller,
          minLines: 9,
          maxLines: 20,
          // So you see your real level.
          autocorrect: false,
          enableSuggestions: false,
          spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.text,
          ),
          decoration: const InputDecoration(
            hintText: 'Write it in English, in your own words.',
            border: InputBorder.none,
            isCollapsed: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final words = controller.text
                .split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    text: '$words',
                    style: const TextStyle(color: AppColors.primary),
                    children: [
                      TextSpan(
                        text: target == null
                            ? (words == 1 ? ' word' : ' words')
                            : ' / $target words',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (target != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (words / target).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: AppColors.accent,
                      backgroundColor: AppColors.surfaceMuted,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Spellcheck and autocorrect are off, so you see your real '
                'level.',
                style: textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
