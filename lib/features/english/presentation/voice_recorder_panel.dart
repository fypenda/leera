import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/app_name.dart';
import '../../../core/audio/audio_playback.dart';
import '../../../core/audio/voice_recorder.dart';
import '../application/english_recordings.dart';
import '../domain/practice_session.dart';
import '../domain/session_recording.dart';

enum _Stage { ready, recording, paused, saving }

/// Recording a spoken presentation: start, pause, finish, listen, record
/// again. The take is kept with the session as soon as it is finished.
///
/// Nothing is recorded until the person taps the microphone, and the system
/// asks for the microphone the first time. Leaving the page mid-take throws
/// the take away; a kept recording stays until a new take replaces it.
class VoiceRecorderPanel extends ConsumerStatefulWidget {
  const VoiceRecorderPanel({
    super.key,
    required this.session,
    required this.onBusyChanged,
  });

  final PracticeSession session;

  /// Told when a take starts (true) and when it is kept or dropped (false),
  /// so the presentation is not sent mid-take.
  final ValueChanged<bool> onBusyChanged;

  @override
  ConsumerState<VoiceRecorderPanel> createState() => _VoiceRecorderPanelState();
}

class _VoiceRecorderPanelState extends ConsumerState<VoiceRecorderPanel> {
  /// How many bars the waveform shows.
  static const _bars = 48;

  var _stage = _Stage.ready;
  var _denied = false;
  var _failed = false;
  var _elapsed = Duration.zero;
  final _levels = <double>[];
  StreamSubscription<RecordingProgress>? _progress;
  RecordingTarget? _target;

  Duration get _targetTime => widget.session.format.targetSpeakingTime;

  /// A take stops by itself at twice its target, so a forgotten recording
  /// does not run on.
  Duration get _cap => _targetTime * 2;

  /// Kept from the last build: `ref` may not be used once disposed.
  late VoiceRecorder _recorder;

  void _setStage(_Stage stage) {
    final wasBusy = _stage != _Stage.ready;
    setState(() => _stage = stage);
    final busy = stage != _Stage.ready;
    if (busy != wasBusy) widget.onBusyChanged(busy);
  }

  Future<void> _start() async {
    setState(() {
      _denied = false;
      _failed = false;
    });
    try {
      if (!await _recorder.requestPermission()) {
        if (mounted) setState(() => _denied = true);
        return;
      }
      final target = await ref
          .read(recordingActionsProvider)
          .newTarget(widget.session.id);
      await _recorder.start(target.path);
      if (!mounted) return;
      _target = target;
      _levels.clear();
      _elapsed = Duration.zero;
      _progress = _recorder.progress.listen(_onProgress);
      _setStage(_Stage.recording);
    } on Object catch (error) {
      debugPrint('Recording could not start: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onProgress(RecordingProgress progress) {
    if (!mounted || _stage != _Stage.recording) return;
    setState(() {
      _elapsed = progress.elapsed;
      _levels.add(displayLevel(progress.level));
      if (_levels.length > _bars) _levels.removeAt(0);
    });
    if (progress.elapsed >= _cap) unawaited(_finish());
  }

  Future<void> _pause() async {
    await _recorder.pause();
    if (mounted) _setStage(_Stage.paused);
  }

  Future<void> _resume() async {
    await _recorder.resume();
    if (mounted) _setStage(_Stage.recording);
  }

  Future<void> _finish() async {
    final target = _target;
    if (target == null || _stage == _Stage.saving) return;
    _setStage(_Stage.saving);
    await _progress?.cancel();
    _progress = null;
    try {
      final duration = await _recorder.stop();
      await ref
          .read(recordingActionsProvider)
          .keep(
            widget.session.id,
            fileName: target.fileName,
            duration: duration < const Duration(seconds: 1)
                ? const Duration(seconds: 1)
                : duration,
          );
    } on Object catch (error) {
      debugPrint('The recording could not be kept: $error');
      if (mounted) setState(() => _failed = true);
    } finally {
      _target = null;
      if (mounted) _setStage(_Stage.ready);
    }
  }

  @override
  void dispose() {
    unawaited(_progress?.cancel());
    // Leaving mid-take: the take is not kept.
    if (_stage == _Stage.recording || _stage == _Stage.paused) {
      unawaited(_recorder.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the recorder for as long as this panel is on screen.
    _recorder = ref.watch(voiceRecorderProvider);
    final recording = ref
        .watch(recordingsProvider)
        .value?[widget.session.id];

    final Widget body = switch ((_stage, recording)) {
      (_Stage.ready, final recording?) => _Recorded(
        recording: recording,
        onRecordAgain: widget.session.isCompleted ? null : _start,
      ),
      (_Stage.ready, null) => _Ready(
        target: _targetTime,
        onStart: widget.session.isCompleted ? null : _start,
      ),
      _ => _Recording(
        elapsed: _elapsed,
        target: _targetTime,
        levels: _levels,
        paused: _stage == _Stage.paused,
        saving: _stage == _Stage.saving,
        onPause: _pause,
        onResume: _resume,
        onFinish: _finish,
      ),
    };

    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        if (_denied)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              '$appName may not use the microphone. Allow it in the Settings '
              'app, under $appName › Microphone, or switch to writing ✍️.',
              key: const ValueKey('microphone-denied'),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.coralStrong,
              ),
            ),
          ),
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'The recording did not work. Try again.',
              key: const ValueKey('recording-failed'),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.coralStrong,
              ),
            ),
          ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.target, required this.onStart});

  final Duration target;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text('🎙️ Ready when you are', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Aim for about ${formatRecordingLength(target)}. Take a breath, '
          'then tap to start.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _BigRoundButton(
          key: const ValueKey('start-recording'),
          label: 'Start recording',
          icon: Icons.mic_rounded,
          onTap: onStart,
        ),
      ],
    );
  }
}

class _Recording extends StatelessWidget {
  const _Recording({
    required this.elapsed,
    required this.target,
    required this.levels,
    required this.paused,
    required this.saving,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final Duration elapsed;
  final Duration target;
  final List<double> levels;
  final bool paused;
  final bool saving;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final over = elapsed > target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                paused ? '⏸️ Paused' : '🔴 Recording',
                key: const ValueKey('recording-status'),
                style: textTheme.titleMedium,
              ),
            ),
            // Shrinks rather than overflows on the narrowest phones.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text.rich(
                  key: const ValueKey('recording-time'),
                  TextSpan(
                    text: formatRecordingLength(elapsed),
                    style: const TextStyle(
                      fontFamily: displayFontFamily,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                    children: [
                      TextSpan(
                        text: ' / ${formatRecordingLength(target)}',
                        style: textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        ExcludeSemantics(
          child: SizedBox(
            height: 120,
            child: Row(
              children: [
                for (
                  var index = 0;
                  index < _VoiceRecorderPanelState._bars;
                  index++
                )
                  Expanded(
                    child: Center(
                      child: FractionallySizedBox(
                        heightFactor: math.max(0.06, _levelAt(index)),
                        child: Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: _levelAt(index) > 0
                                ? AppColors.coral
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: math.min(
              1,
              elapsed.inMilliseconds / target.inMilliseconds,
            ),
            minHeight: 6,
            color: over ? AppColors.accent : AppColors.coral,
            backgroundColor: AppColors.surfaceMuted,
          ),
        ),
        if (over) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '⏱️ Time is up: wrap up when you are ready.',
            key: const ValueKey('recording-over-time'),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.lg,
          children: [
            if (paused)
              _BigRoundButton(
                key: const ValueKey('resume-recording'),
                label: 'Resume',
                icon: Icons.mic_rounded,
                onTap: saving ? null : onResume,
              )
            else
              _BigRoundButton(
                key: const ValueKey('pause-recording'),
                label: 'Pause',
                icon: Icons.pause_rounded,
                onTap: saving ? null : onPause,
              ),
            FilledButton(
              key: const ValueKey('finish-recording'),
              onPressed: saving ? null : onFinish,
              child: const Text('✅ Done'),
            ),
          ],
        ),
      ],
    );
  }

  /// The level of the bar at [index], the latest on the right; 0 before
  /// anything was heard.
  double _levelAt(int index) {
    final offset = _VoiceRecorderPanelState._bars - levels.length;
    return index < offset ? 0 : levels[index - offset];
  }
}

class _Recorded extends StatelessWidget {
  const _Recorded({required this.recording, required this.onRecordAgain});

  final SessionRecording recording;
  final VoidCallback? onRecordAgain;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('🎧 Your recording', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        RecordingPlayer(recording: recording),
        if (onRecordAgain case final recordAgain?) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              key: const ValueKey('record-again'),
              onPressed: recordAgain,
              child: const Text('🔁 Record again'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Listening to a kept recording: play or pause, and how far along it is.
class RecordingPlayer extends ConsumerStatefulWidget {
  const RecordingPlayer({super.key, required this.recording});

  final SessionRecording recording;

  @override
  ConsumerState<RecordingPlayer> createState() => _RecordingPlayerState();
}

class _RecordingPlayerState extends ConsumerState<RecordingPlayer> {
  var _playing = false;
  var _position = Duration.zero;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// Kept from the last build: `ref` may not be used once disposed.
  late AudioPlayback _player;

  void _listen() {
    if (_subscriptions.isNotEmpty) return;
    _subscriptions
      ..add(
        _player.position.listen((position) {
          if (mounted) setState(() => _position = position);
        }),
      )
      ..add(
        _player.playing.listen((playing) {
          if (!mounted) return;
          setState(() {
            _playing = playing;
            // Finished: back to the start for the next listen.
            if (!playing && _position >= widget.recording.duration) {
              _position = Duration.zero;
            }
          });
        }),
      );
  }

  Future<void> _toggle() async {
    _listen();
    try {
      if (_playing) {
        await _player.pause();
      } else {
        final path = await ref
            .read(recordingActionsProvider)
            .pathOf(widget.recording);
        await _player.play(path);
      }
    } on Object catch (error) {
      debugPrint('The recording could not be played: $error');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('The recording could not be played.'),
            ),
          );
      }
    }
  }

  @override
  void didUpdateWidget(RecordingPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new take: start from its beginning.
    if (oldWidget.recording.fileName != widget.recording.fileName) {
      unawaited(_player.stop());
      _position = Duration.zero;
      _playing = false;
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the player for as long as this is on screen.
    _player = ref.watch(audioPlaybackProvider);
    final textTheme = Theme.of(context).textTheme;
    final length = widget.recording.duration;

    return Container(
      key: const ValueKey('recording-player'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          IconButton.filled(
            key: const ValueKey('play-recording'),
            tooltip: _playing ? 'Pause' : 'Listen',
            onPressed: _toggle,
            icon: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: length.inMilliseconds == 0
                    ? 0
                    : math.min(
                        1,
                        _position.inMilliseconds / length.inMilliseconds,
                      ),
                minHeight: 6,
                backgroundColor: AppColors.surfaceMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${formatRecordingLength(_position)} / '
            '${formatRecordingLength(length)}',
            key: const ValueKey('recording-length'),
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// The large round button of the recorder.
class _BigRoundButton extends StatelessWidget {
  const _BigRoundButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: onTap == null ? AppColors.surfaceMuted : AppColors.coral,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.coralSoft, width: 6),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 108,
              height: 108,
              child: Icon(icon, size: 40, color: AppColors.surface),
            ),
          ),
        ),
      ),
    );
  }
}
