import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../application/english_recordings.dart';
import '../data/practice_session_repository_provider.dart';
import '../data/topic_catalog.dart';
import '../domain/practice_session.dart';
import '../english_routes.dart';
import 'session_frame.dart';
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

    return SessionFrame(
      background: AppColors.highlight,
      leaveLabel: '← My notes',
      onLeave: () => context.goNamed(
        englishTopicRouteName,
        pathParameters: {englishSessionParameter: session.id},
      ),
      currentStep: 1,
      startFlex: 4,
      endFlex: 6,
      start: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _writing
                ? 'WRITTEN PRESENTATION'
                : 'SPOKEN PRESENTATION · '
                      '${session.format.constraint.toUpperCase()}',
            style: textTheme.labelSmall?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            topic.title,
            style: const TextStyle(
              fontFamily: displayFontFamily,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.02,
              letterSpacing: -0.8,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${session.format.emoji} ${session.format.summary}. Explain the '
            'topic in English, as you would to a colleague 💬 Your notes are '
            'hidden.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.ink,
              fontSize: 17,
            ),
          ),
          if (topic.outline.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg + 2),
            SessionCard(
              padding: const EdgeInsets.all(AppSpacing.lg + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🧭 To help you structure it',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final (index, question) in topic.outline.indexed)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        '${index + 1}. $question',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      end: SessionCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_writing)
              _Writer(controller: _text)
            else
              VoiceRecorderPanel(
                session: session,
                onBusyChanged: (busy) => setState(() => _recordingBusy = busy),
              ),
            const SizedBox(height: AppSpacing.xl),
            // Wraps rather than overflows on the narrowest phones.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.lg,
              children: [
                if (_writing)
                  _SmallRoundButton(
                    emoji: '🔁',
                    label: 'Start again',
                    onTap: () => _text.clear(),
                  ),
                _SmallRoundButton(
                  key: const ValueKey('switch-format'),
                  emoji: _writing ? '🎙️' : '✍️',
                  label: _writing ? 'Switch to speaking' : 'Switch to writing',
                  // Not mid-take: finish or leave the recording first.
                  onTap: _recordingBusy
                      ? null
                      : () => setState(() => _writing = !_writing),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              key: const ValueKey('send-for-feedback'),
              onPressed: _sending
                  ? null
                  : session.isCompleted
                  ? () => openSession(context, session)
                  : canSend
                  ? _send
                  : null,
              child: Text(
                session.isCompleted
                    ? 'See the feedback 🧾'
                    : 'Send for feedback 📤',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _writing
                  ? '🤖 The AI only steps in now.'
                  : recorded
                  ? '🤖 Once sent, your recording is turned into text on this '
                        'device, then corrected.'
                  : '🎙️ Record your presentation to send it. It stays on this '
                        'device.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Writing the presentation instead, with a word count.
class _Writer extends StatelessWidget {
  const _Writer({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('✍️ Your presentation', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('written-presentation'),
          controller: controller,
          minLines: 8,
          maxLines: 16,
          decoration: InputDecoration(
            hintText: 'Write it in English, in your own words.',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final words = controller.text
                .split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .length;
            return Text(
              '$words ${words == 1 ? 'word' : 'words'}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            );
          },
        ),
      ],
    );
  }
}

class _SmallRoundButton extends StatelessWidget {
  const _SmallRoundButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: AppColors.background,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        ),
      ),
    );
  }
}
