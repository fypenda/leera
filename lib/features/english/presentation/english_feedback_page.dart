import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/ai/ai_settings.dart';
import '../../../core/ai/backend_client.dart';
import '../../../core/audio/transcriber.dart';
import '../../../core/common/widgets/design/score_bar.dart';
import '../../../core/common/widgets/load_failure.dart';
import '../application/english_feedback.dart';
import '../application/english_recordings.dart';
import '../application/english_transcriptions.dart';
import '../data/topic_catalog.dart';
import '../domain/practice_session.dart';
import '../domain/session_feedback.dart';
import '../english_routes.dart';
import 'session_frame.dart';
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
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final feedbacks = ref.watch(feedbacksProvider);
    final settings = ref.watch(aiSettingsProvider);
    final recordings = ref.watch(recordingsProvider);
    final recording = recordings.value?[session.id];
    final transcript = recording?.transcript;
    final player = switch (recording) {
      final recording? => RecordingPlayer(recording: recording),
      null => null,
    };

    final Widget body = switch ((feedbacks, settings)) {
      (AsyncError(), _) => LoadFailure(
        message: 'Your corrections could not be loaded.',
        onRetry: () => ref.invalidate(feedbacksProvider),
      ),
      (AsyncData(value: final stored), _) when stored[session.id] != null =>
        _Correction(session: session, feedback: stored[session.id]!),
      // Spoken: the recording must be there, then heard, before anything
      // can be corrected.
      _ when session.presentation == null && !recordings.hasValue =>
        const SizedBox.shrink(),
      _ when session.presentation == null && recording == null =>
        const _Message(
          key: ValueKey('spoken-not-corrected'),
          title: 'Nothing was recorded 🎙️',
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
          title: 'Listening to your recording… 🎧',
          text:
              'It is turned into text on this device whenever it can be, '
              'then corrected like a written one.',
          action: LinearProgressIndicator(),
        );
      }(),
      _ when session.presentation == null && transcript!.trim().isEmpty =>
        _Message(
          key: const ValueKey('nothing-heard'),
          title: 'Nothing could be heard 🤫',
          text:
              'No words were found in this recording, so there is nothing to '
              'correct. Check that the microphone is not covered next time.',
          action: FilledButton(
            key: const ValueKey('retry-transcription'),
            onPressed: _transcribe,
            child: const Text('Listen again'),
          ),
        ),
      (AsyncData(), AsyncData(value: null)) => _Message(
        key: const ValueKey('ai-not-set-up'),
        title: 'Set up AI correction ⚙️',
        text:
            'Your presentation is saved. Connect the app to your backend to '
            'have it corrected: nothing is sent until you do.',
        action: FilledButton(
          onPressed: () => context.pushNamed(aiSettingsRouteName),
          child: const Text('Open the AI settings'),
        ),
      ),
      (AsyncData(), AsyncData()) when _failure != null => _Message(
        key: const ValueKey('feedback-failed'),
        title: 'No correction this time',
        text: describeBackendFailure(_failure!),
        action: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            FilledButton(
              key: const ValueKey('retry-feedback'),
              onPressed: _request,
              child: const Text('Try again'),
            ),
            if (_failure == BackendFailure.unauthorized ||
                _failure == BackendFailure.unreachable)
              OutlinedButton(
                onPressed: () => context.pushNamed(aiSettingsRouteName),
                child: const Text('AI settings'),
              ),
          ],
        ),
      ),
      (AsyncData(), AsyncData()) => () {
        if (!_askedOnce) {
          _askedOnce = true;
          _soon(_request);
        }
        return const _Message(
          key: ValueKey('feedback-loading'),
          title: 'Claude is reading your presentation… 🤖',
          text: 'This takes a few seconds. Stay here, or come back later: '
              'your presentation is saved.',
          action: LinearProgressIndicator(),
        );
      }(),
      _ => const SizedBox.shrink(),
    };

    return SessionFrame(
      leaveLabel: '✕ Close',
      onLeave: () => context.goNamed(englishRouteName),
      currentStep: 2,
      startFlex: 9,
      endFlex: 11,
      start: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body is _Correction ? body.summary(context) : body,
          if (session.presentation case final presentation?) ...[
            const SizedBox(height: AppSpacing.lg + 4),
            _WhatYouWrote(presentation),
          ] else if (player != null) ...[
            const SizedBox(height: AppSpacing.lg + 4),
            _WhatYouSaid(player: player, transcript: transcript),
          ],
          const SizedBox(height: AppSpacing.lg + 4),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              key: const ValueKey('feedback-done'),
              onPressed: () => context.goNamed(englishRouteName),
              child: const Text('✅ Done'),
            ),
          ),
        ],
      ),
      end: body is _Correction ? body : const SizedBox.shrink(),
    );
  }
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
    return SessionCard(
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
    return SessionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('✍️ What you wrote', style: textTheme.titleMedium),
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
    return SessionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🗣️ What you said', style: textTheme.titleMedium),
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

/// A correction received: its summary goes on one side of the page, its
/// details on the other.
class _Correction extends StatelessWidget {
  const _Correction({required this.session, required this.feedback});

  final PracticeSession session;
  final SessionFeedback feedback;

  /// The headline, level, summary and scores.
  Widget summary(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('feedback-summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionCard(
          color: AppColors.highlight,
          padding: const EdgeInsets.all(28),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.headline,
                      key: const ValueKey('feedback-headline'),
                      style: const TextStyle(
                        fontFamily: displayFontFamily,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.6,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      topicById(session.topicId).title,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              _LevelBox(level: feedback.estimatedLevel),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg + 4),
        SessionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                feedback.summary,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('📊 Details', style: textTheme.titleMedium),
              for (final (label, score) in feedback.scores.criteria) ...[
                const SizedBox(height: AppSpacing.lg),
                ScoreBar(label: label, score: score),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('🛠️ To fix', style: textTheme.headlineSmall),
        if (feedback.corrections.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nothing to fix this time. 👏',
            key: const ValueKey('no-corrections'),
            style: textTheme.bodyLarge,
          ),
        ],
        for (final correction in feedback.corrections) ...[
          const SizedBox(height: AppSpacing.lg),
          _CorrectionCard(correction),
        ],
        if (feedback.recurringMistakesSeen.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            '🔁 Back again: ${feedback.recurringMistakesSeen.join(', ')}',
            key: const ValueKey('recurring-seen'),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.coralStrong),
          ),
        ],
        if (feedback.vocabulary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('📚 Words to keep', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final item in feedback.vocabulary) VocabularyCard(item),
            ],
          ),
        ],
        if (feedback.followUpQuestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('🤔 To go further', style: textTheme.headlineSmall),
          for (final question in feedback.followUpQuestions) ...[
            const SizedBox(height: AppSpacing.md),
            Text('• $question', style: textTheme.bodyLarge),
          ],
        ],
      ],
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
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            level,
            style: const TextStyle(
              fontFamily: displayFontFamily,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('estimated', style: Theme.of(context).textTheme.bodySmall),
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
    final textTheme = Theme.of(context).textTheme;
    const base = TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: 16,
      height: 1.45,
      color: AppColors.textMuted,
    );
    final naturalness = correction.kind == CorrectionKind.naturalness;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: base,
              children: [
                TextSpan(text: naturalness ? '🤏 ' : '❌ '),
                ..._highlighted(
                  correction.original,
                  correction.mistake,
                  const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.coral,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            TextSpan(
              style: base.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(text: naturalness ? '🗣️ ' : '✅ '),
                ..._highlighted(
                  correction.corrected,
                  correction.fix,
                  const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('💡 ${correction.explanation}', style: textTheme.bodySmall),
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
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.expression,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.accentStrong,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.meaning,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.text),
          ),
          if (item.example.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('“${item.example}”', style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
