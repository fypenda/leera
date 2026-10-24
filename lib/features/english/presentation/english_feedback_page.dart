import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/ai/backend_client.dart';
import '../../../core/auth/auth_actions.dart';
import '../../../core/auth/session.dart';
import '../../../core/audio/transcriber.dart';
import '../../../core/common/widgets/edge_swipe_back.dart';
import '../../../core/common/widgets/load_failure.dart';
import '../application/english_feedback.dart';
import '../application/english_recordings.dart';
import '../application/english_transcriptions.dart';
import '../domain/practice_session.dart';
import '../domain/session_feedback.dart';
import '../english_routes.dart';
import 'session_chrome.dart';
import 'session_navigation.dart';
import 'voice_recorder_panel.dart';

/// Step 3 of a session: the correction of what was written.
///
/// The first time a written presentation is shown here, its correction is
/// asked for and kept; afterwards it is shown from the device. A spoken
/// presentation keeps no text, so there is nothing to correct yet.
class EnglishFeedbackPage extends StatelessWidget {
  const EnglishFeedbackPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return SessionLoader(
      sessionId: sessionId,
      builder: (context, session) => session.isCompleted
          ? _FeedbackForSession(key: ValueKey(session.id), session: session)
          : _NotSentYet(session: session),
    );
  }
}

class _NotSentYet extends StatelessWidget {
  const _NotSentYet({required this.session});

  final PracticeSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This presentation has not been sent yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => openSession(context, session),
                  child: const Text('Continue the session'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackForSession extends ConsumerStatefulWidget {
  const _FeedbackForSession({super.key, required this.session});

  final PracticeSession session;

  @override
  ConsumerState<_FeedbackForSession> createState() =>
      _FeedbackForSessionState();
}

class _FeedbackForSessionState extends ConsumerState<_FeedbackForSession> {
  var _requesting = false;
  BackendFailure? _failure;

  /// Asked for once by itself; after that, only when the person retries.
  var _askedOnce = false;

  var _transcribing = false;
  TranscriptionFailure? _transcriptionFailure;

  /// Like the correction: transcribed once by itself, then on retry.
  var _transcribedOnce = false;

  Future<void> _transcribe() async {
    if (_transcribing) return;
    setState(() {
      _transcribing = true;
      _transcriptionFailure = null;
    });
    try {
      await ref
          .read(transcriptionActionsProvider)
          .transcribe(widget.session.id);
    } on TranscriptionException catch (e) {
      debugPrint('Transcription failed: $e');
      if (mounted) setState(() => _transcriptionFailure = e.failure);
    } on Object catch (e) {
      debugPrint('Transcription failed: $e');
      if (mounted) {
        setState(() => _transcriptionFailure = TranscriptionFailure.failed);
      }
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  /// Runs [action] once, after this frame.
  void _soon(Future<void> Function() action) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });

  Future<void> _request() async {
    if (_requesting) return;
    setState(() {
      _requesting = true;
      _failure = null;
    });
    try {
      await ref.read(feedbackActionsProvider).requestFor(widget.session);
    } on BackendException catch (e) {
      debugPrint('Feedback request failed: $e');
      if (mounted) setState(() => _failure = e.failure);
    } on Object catch (e) {
      debugPrint('Feedback request failed: $e');
      if (mounted) setState(() => _failure = BackendFailure.unexpected);
    } finally {
      // One correction more, or none: either way the quota shown changes.
      if (mounted) {
        ref.invalidate(quotaProvider);
        setState(() => _requesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final feedbacks = ref.watch(feedbacksProvider);
    final recordings = ref.watch(recordingsProvider);
    final recording = recordings.value?[session.id];
    final transcript = recording?.transcript;
    final player = switch (recording) {
      final recording? => RecordingPlayer(recording: recording),
      null => null,
    };

    final Widget body = switch (feedbacks) {
      AsyncError() => LoadFailure(
        message: 'Your corrections could not be loaded.',
        onRetry: () => ref.invalidate(feedbacksProvider),
      ),
      AsyncData(value: final stored) when stored[session.id] != null =>
        _Correction(session: session, feedback: stored[session.id]!),
      // Spoken: the recording must be there, then heard, before anything
      // can be corrected.
      _ when session.presentation == null && !recordings.hasValue =>
        const SizedBox.shrink(),
      _ when session.presentation == null && recording == null =>
        const _Message(
          key: ValueKey('spoken-not-corrected'),
          title: 'Nothing was recorded',
          text:
              'This presentation was sent without a recording, so there is '
              'nothing to correct. Record or write your next one to get a '
              'correction.',
        ),
      _ when session.presentation == null &&
              transcript == null &&
              _transcriptionFailure != null =>
        _Message(
          key: const ValueKey('transcription-failed'),
          title: 'Your recording is safe, but not yet in words',
          text: describeTranscriptionFailure(_transcriptionFailure!),
          action: FilledButton(
            key: const ValueKey('retry-transcription'),
            onPressed: _transcribe,
            child: const Text('Try again'),
          ),
        ),
      _ when session.presentation == null && transcript == null => () {
        if (!_transcribedOnce) {
          _transcribedOnce = true;
          _soon(_transcribe);
        }
        return const _Message(
          key: ValueKey('transcribing'),
          title: 'Listening to your recording…',
          text:
              'It is turned into text on this device whenever it can be, '
              'then corrected like a written one.',
          action: LinearProgressIndicator(),
        );
      }(),
      _ when session.presentation == null && transcript!.trim().isEmpty =>
        _Message(
          key: const ValueKey('nothing-heard'),
          title: 'Nothing could be heard',
          text:
              'No words were found in this recording, so there is nothing to '
              'correct. Check that the microphone is not covered next time.',
          action: FilledButton(
            key: const ValueKey('retry-transcription'),
            onPressed: _transcribe,
            child: const Text('Listen again'),
          ),
        ),
      AsyncData() when _failure != null => _Message(
        key: const ValueKey('feedback-failed'),
        title: 'No correction this time',
        text: describeBackendFailure(_failure!),
        action: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            if (_failure != BackendFailure.quotaExceeded)
              FilledButton(
                key: const ValueKey('retry-feedback'),
                onPressed: _request,
                child: const Text('Try again'),
              ),
            if (_failure == BackendFailure.quotaExceeded)
              OutlinedButton(
                key: const ValueKey('feedback-open-account'),
                onPressed: () => context.pushNamed(accountRouteName),
                child: const Text('See my account'),
              ),
          ],
        ),
      ),
      AsyncData() => () {
        if (!_askedOnce) {
          _askedOnce = true;
          _soon(_request);
        }
        return const _Message(
          key: ValueKey('feedback-loading'),
          title: 'Claude is reading your presentation…',
          text: 'This takes a few seconds. Stay here, or come back later: '
              'your presentation is saved.',
          action: LinearProgressIndicator(),
        );
      }(),
      _ => const SizedBox.shrink(),
    };

    void close() => context.goNamed(englishRouteName);

    return EdgeSwipeBack(
      onBack: close,
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
                                icon: Icons.close_rounded,
                                label: 'Close',
                                onTap: close,
                              ),
                              const Expanded(child: StepDots(current: 2)),
                              const SizedBox(width: 44),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (body is _Correction) ...[
                            body.header(context),
                            const SizedBox(height: AppSpacing.lg),
                            body,
                          ] else ...[
                            const StepEyebrow(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Step 3 · Feedback',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            body,
                          ],
                          if (session.presentation case final presentation?) ...[
                            const SizedBox(height: AppSpacing.lg + 4),
                            _WhatYouWrote(presentation),
                          ] else if (player != null) ...[
                            const SizedBox(height: AppSpacing.lg + 4),
                            _WhatYouSaid(player: player, transcript: transcript),
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
                      AppSpacing.lg,
                    ),
                    child: BottomActionButton(
                      buttonKey: const ValueKey('feedback-done'),
                      label: 'Done',
                      icon: Icons.check_rounded,
                      onTap: close,
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

/// A white card with the design's radius.
class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg + 4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

/// A section title with its icon: "To fix", "Words to keep".
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.ink),
      const SizedBox(width: AppSpacing.sm),
      Text(
        title,
        style: const TextStyle(
          fontFamily: displayFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
    ],
  );
}

/// A short message card, with an optional action under it.
class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.title,
    required this.text,
    this.action,
  });

  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(text, style: textTheme.bodyMedium),
          if (action case final action?) ...[
            const SizedBox(height: AppSpacing.lg),
            action,
          ],
        ],
      ),
    );
  }
}

class _WhatYouWrote extends StatelessWidget {
  const _WhatYouWrote(this.presentation);

  final String presentation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What you wrote', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            presentation,
            key: const ValueKey('sent-presentation'),
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// A spoken presentation: the recording, and the text heard in it once it
/// has been transcribed.
class _WhatYouSaid extends StatelessWidget {
  const _WhatYouSaid({required this.player, required this.transcript});

  final Widget player;
  final String? transcript;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What you said', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          player,
          if (transcript case final transcript? when transcript.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              transcript,
              key: const ValueKey('sent-transcript'),
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Transcribed automatically: punctuation and spelling come from '
              'the transcription, not from you.',
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// A correction received: the headline and level, then the scores, what to
/// fix, the words to keep and where to go further.
class _Correction extends StatelessWidget {
  const _Correction({required this.session, required this.feedback});

  final PracticeSession session;
  final SessionFeedback feedback;

  /// The step, the headline and the estimated level, at the top of the page.
  Widget header(BuildContext context) => Row(
    key: const ValueKey('feedback-summary'),
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StepEyebrow(
              icon: Icons.auto_awesome_rounded,
              label: 'Step 3 · Feedback',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              feedback.headline,
              key: const ValueKey('feedback-headline'),
              style: const TextStyle(
                fontFamily: displayFontFamily,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -0.6,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      _LevelBox(level: feedback.estimatedLevel),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scores = feedback.scores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          feedback.summary,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Card(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            children: [
              for (final (index, (icon, label, score)) in [
                (Icons.text_fields_rounded, 'Grammar', scores.grammar),
                (Icons.menu_book_outlined, 'Vocabulary', scores.vocabulary),
                (Icons.waves_rounded, 'Naturalness', scores.naturalness),
                (Icons.layers_outlined, 'Structure', scores.structure),
                (Icons.lightbulb_outline_rounded, 'Content', scores.content),
              ].indexed) ...[
                if (index > 0) const SizedBox(height: AppSpacing.md),
                _ScoreRow(icon: icon, label: label, score: score),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl - 4),
        const _SectionTitle(icon: Icons.edit_outlined, title: 'To fix'),
        if (feedback.corrections.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            'Nothing to fix this time. Well done!',
            key: const ValueKey('no-corrections'),
            style: textTheme.bodyMedium,
          ),
        ],
        for (final correction in feedback.corrections) ...[
          const SizedBox(height: AppSpacing.sm + 2),
          _CorrectionCard(correction),
        ],
        if (feedback.recurringMistakesSeen.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            key: const ValueKey('recurring-seen'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.replay_rounded,
                size: 16,
                color: AppColors.coralStrong,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Back again: ${feedback.recurringMistakesSeen.join(', ')}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.coralStrong,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (feedback.vocabulary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl - 4),
          const _SectionTitle(
            icon: Icons.bookmark_border_rounded,
            title: 'Words to keep',
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          for (final item in feedback.vocabulary) ...[
            VocabularyCard(item),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (feedback.followUpQuestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl - 4),
          const _SectionTitle(
            icon: Icons.explore_outlined,
            title: 'To go further',
          ),
          for (final question in feedback.followUpQuestions) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              question,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.text),
            ),
          ],
        ],
      ],
    );
  }
}

/// One score out of 10: teal from 7, coral below.
class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.icon,
    required this.label,
    required this.score,
  });

  final IconData icon;
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    const text = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    );

    return Semantics(
      label: '$label: $score out of 10',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: text)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 10,
                minHeight: 8,
                color: score >= 7 ? AppColors.highlight : AppColors.coral,
                backgroundColor: AppColors.surfaceMuted,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$score',
              textAlign: TextAlign.end,
              style: text.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBox extends StatelessWidget {
  const _LevelBox({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('estimated-level'),
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.highlight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            level,
            style: const TextStyle(
              fontFamily: displayFontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
              color: AppColors.ink,
            ),
          ),
          const Text(
            'estimated',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard(this.correction);

  final Correction correction;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: 14,
      height: 1.45,
      color: AppColors.textMuted,
    );

    Widget line(IconData icon, Color color, Widget text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: text),
      ],
    );

    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(
            Icons.close_rounded,
            AppColors.coralStrong,
            Text.rich(
              TextSpan(
                style: base,
                children: _highlighted(
                  correction.original,
                  correction.mistake,
                  const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.coral,
                    decorationThickness: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          line(
            Icons.check_rounded,
            AppColors.primary,
            Text.rich(
              TextSpan(
                style: base.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
                children: _highlighted(
                  correction.corrected,
                  correction.fix,
                  const TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          line(
            Icons.lightbulb_outline_rounded,
            AppColors.textMuted,
            Text(
              correction.explanation,
              style: base.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// [text] with the first [part] of it in [style]; all plain if [part] is
/// empty or not in it.
List<TextSpan> _highlighted(String text, String part, TextStyle style) {
  final at = part.isEmpty ? -1 : text.indexOf(part);
  if (at < 0) return [TextSpan(text: text)];
  return [
    TextSpan(text: text.substring(0, at)),
    TextSpan(text: part, style: style),
    TextSpan(text: text.substring(at + part.length)),
  ];
}

/// An expression to keep, with its meaning and example.
class VocabularyCard extends StatelessWidget {
  const VocabularyCard(this.item, {super.key});

  final VocabularyItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.expression,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 15,
              color: AppColors.accentStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.meaning,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.text),
          ),
          if (item.example.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '“${item.example}”',
              style: textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
