import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_actions.dart';
import '../../core/auth/quota.dart';
import '../../core/auth/session.dart';
import '../../core/settings/settings.dart';
import '../../features/english/application/english_themes.dart';
import '../../features/english/data/preference_repository_providers.dart';
import '../../features/english/domain/learner_profile.dart';
import '../../features/english/domain/study_pace.dart';
import '../../features/english/presentation/session_chrome.dart';
import '../../features/english/presentation/theme_style.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'learner_choices.dart';

/// The welcome, once, before the first topic: how Leera works, the level
/// the person thinks they have, why they learn, their first language and
/// the themes they like.
///
/// The level is shown until a correction estimates it. The level, the goal
/// and the first language go with each correction, so it fits the person.
/// The themes come first in Explore, and with Leera Plus the daily topic is
/// drawn from them. Nothing is stored before the last step: leaving halfway
/// starts over.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  static const _steps = 8;
  static const double _maxWidth = 560;

  var _step = 0;
  String? _level;
  LearnerGoal? _goal;
  String? _language;
  StudyPace? _pace;
  final _themes = <String>{};
  var _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      if (_level case final level?) {
        await settings.write(SettingKeys.selfAssessedLevel, level);
      }
      if (_goal case final goal?) {
        await settings.write(SettingKeys.goal, goal.name);
      }
      if (cleanFirstLanguage(_language) case final language?) {
        await settings.write(SettingKeys.firstLanguage, language);
      }
      if (_pace case final pace?) {
        await settings.write(SettingKeys.studyPace, pace.name);
      }
      if (_themes.isNotEmpty) {
        await ref.read(themePreferenceRepositoryProvider).setThemes(_themes);
      }
      // Last: the app leaves the welcome as soon as this is stored.
      await settings.write(SettingKeys.welcome, 'done');
    } on Object catch (e) {
      debugPrint('Saving the welcome failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That could not be saved. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (Widget body, String action, VoidCallback? onAction) = switch (_step) {
      0 => (const _HowItWorks(), "Let's start", () => setState(() => _step++)),
      1 => (
        _LevelStep(
          level: _level,
          onChanged: (level) => setState(() => _level = level),
        ),
        'Continue',
        _level == null ? null : () => setState(() => _step++),
      ),
      2 => (
        _GoalStep(
          goal: _goal,
          onChanged: (goal) => setState(() => _goal = goal),
        ),
        'Continue',
        _goal == null ? null : () => setState(() => _step++),
      ),
      3 => (
        _LanguageStep(
          language: _language,
          onChanged: (language) => setState(() => _language = language),
        ),
        _language == null ? 'Skip' : 'Continue',
        () => setState(() => _step++),
      ),
      4 => (
        _ThemesStep(
          chosen: _themes,
          onToggle: (theme) => setState(
            () => _themes.contains(theme)
                ? _themes.remove(theme)
                : _themes.add(theme),
          ),
        ),
        _themes.isEmpty ? 'Skip for now' : 'Continue',
        () => setState(() => _step++),
      ),
      5 => (
        _PaceStep(
          pace: _pace,
          onChanged: (pace) => setState(() => _pace = pace),
        ),
        'Continue',
        _pace == null ? null : () => setState(() => _step++),
      ),
      6 => (
        _Plan(
          level: _level,
          goal: _goal,
          language: cleanFirstLanguage(_language),
          pace: _pace,
          themes: _themes,
        ),
        'Continue',
        () => setState(() => _step++),
      ),
      _ => (
        const _FreeOrPlus(),
        'Try Leera Plus free for 7 days',
        _saving ? null : () => context.pushNamed(plusRouteName),
      ),
    };
    // On the last step, the free plan is the second way on.
    final isPlus = switch (ref.watch(quotaProvider).value?.plan) {
      Plan.plus || Plan.dev => true,
      _ => false,
    };
    final Widget? secondary = _step == _steps - 1
        ? TextButton(
            key: const ValueKey('welcome-free'),
            onPressed: _saving ? null : _finish,
            child: Text(isPlus ? 'Continue' : 'Continue with the free plan'),
          )
        : null;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          if (_step > 0)
                            RoundIconButton(
                              key: const ValueKey('welcome-back'),
                              icon: Icons.chevron_left_rounded,
                              label: 'Back',
                              onTap: () => setState(() => _step--),
                            )
                          else
                            const SizedBox(width: 44),
                          Expanded(child: _Progress(step: _step, of: _steps)),
                          const SizedBox(width: 44),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: SingleChildScrollView(
                        key: ValueKey('welcome-step-$_step'),
                        child: body,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BottomActionButton(
                      buttonKey: const ValueKey('welcome-next'),
                      label: action,
                      icon: _step == _steps - 1
                          ? Icons.auto_awesome_rounded
                          : Icons.arrow_forward_rounded,
                      onTap: onAction,
                    ),
                    ?secondary,
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

class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.of});

  final int step;
  final int of;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Step ${step + 1} of $of',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < of; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == step ? 28 : 12,
            height: 6,
            decoration: BoxDecoration(
              color: i <= step ? AppColors.highlight : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        text,
        style: const TextStyle(
          fontFamily: displayFontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -0.6,
          color: AppColors.ink,
        ),
      ),
      if (detail case final detail?) ...[
        const SizedBox(height: AppSpacing.sm + 2),
        Text(
          detail,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ],
  );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    (
      Icons.casino_outlined,
      AppColors.accentSoft,
      AppColors.accentStrong,
      'A topic is drawn for you',
      'Science, history, Africa, business… and a format: a voice note, an '
          'email, a TED intro.',
    ),
    (
      Icons.search_rounded,
      AppColors.primarySoft,
      AppColors.primary,
      'You research it, in English',
      'Read, watch, take notes. No AI at this step: the effort is the '
          'point.',
    ),
    (
      Icons.mic_none_rounded,
      AppColors.coralSoft,
      AppColors.coralStrong,
      'You explain it, then Claude corrects you',
      'Spoken or written. You get your mistakes explained, words to keep '
          'and an estimated level.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/brand/logo.png',
          width: 72,
          height: 72,
          semanticLabel: 'Leera logo',
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const _Title(
        'Welcome to Leera',
        detail: 'Fluency through real topics. Here is how a session goes.',
      ),
      const SizedBox(height: AppSpacing.xl),
      for (final (icon, background, foreground, title, detail) in _steps) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: foreground),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg + 2),
      ],
    ],
  );
}

class _LevelStep extends StatelessWidget {
  const _LevelStep({required this.level, required this.onChanged});

  final String? level;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Title(
        'Where is your English today?',
        detail:
            'Your own estimate. Your first correction will give you '
            "Claude's.",
      ),
      const SizedBox(height: AppSpacing.xl),
      LevelChoices(level: level, onChanged: onChanged),
    ],
  );
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.goal, required this.onChanged});

  final LearnerGoal? goal;
  final ValueChanged<LearnerGoal> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Title(
        'Why are you learning English?',
        detail: 'Claude fits its corrections to it: the words, the tone.',
      ),
      const SizedBox(height: AppSpacing.xl),
      GoalChoices(goal: goal, onChanged: onChanged),
    ],
  );
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({required this.language, required this.onChanged});

  final String? language;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Title(
        'What is your first language?',
        detail:
            'So Claude can spot the traps it sets in English, such as false '
            'friends. Optional.',
      ),
      const SizedBox(height: AppSpacing.xl),
      FirstLanguageChoices(language: language, onChanged: onChanged),
    ],
  );
}

class _ThemesStep extends ConsumerWidget {
  const _ThemesStep({required this.chosen, required this.onToggle});

  final Set<String> chosen;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = ref.watch(catalogThemesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title(
          'What do you like to read about?',
          detail:
              'Your themes come first in Explore. With Leera Plus, your '
              'daily topic is drawn from them. You can change them later.',
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (theme, _) in themes)
              FilterChip(
                key: ValueKey('welcome-theme-$theme'),
                label: Text(theme),
                avatar: Icon(themeStyle(theme).icon, size: 18),
                selected: chosen.contains(theme),
                showCheckmark: false,
                selectedColor: AppColors.primarySoft,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: chosen.contains(theme)
                      ? AppColors.primary
                      : AppColors.surfaceMuted,
                ),
                shape: const StadiumBorder(),
                onSelected: (_) => onToggle(theme),
              ),
          ],
        ),
      ],
    );
  }
}

class _PaceStep extends StatelessWidget {
  const _PaceStep({required this.pace, required this.onChanged});

  final StudyPace? pace;
  final ValueChanged<StudyPace> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Title(
        'How much time can you give?',
        detail:
            'Be honest: a little every day beats a lot once a week. You can '
            'change it later.',
      ),
      const SizedBox(height: AppSpacing.xl),
      PaceChoices(pace: pace, onChanged: onChanged),
    ],
  );
}

/// The plan the answers make: a week to keep, and what is known of the
/// person.
class _Plan extends StatelessWidget {
  const _Plan({
    required this.level,
    required this.goal,
    required this.language,
    required this.pace,
    required this.themes,
  });

  final String? level;
  final LearnerGoal? goal;
  final String? language;
  final StudyPace? pace;
  final Set<String> themes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Title(
        'Your plan',
        detail:
            'A rhythm to keep each week. Today shows where you stand, and '
            'Claude fits each correction to you.',
      ),
      const SizedBox(height: AppSpacing.xl),
      if (pace case final pace?)
        Container(
          key: const ValueKey('welcome-plan'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EACH WEEK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: Color(0xFFBFE9EF),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PlanFigure(
                figure: '${pace.sessions}',
                text: pace.sessions == 7
                    ? 'sessions: a topic a day'
                    : 'sessions: research, explain, get corrected',
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _PlanFigure(
                figure: '${pace.reviews}',
                text: 'review days for your words',
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _PlanFigure(
                figure: '${pace.minutesADay}′',
                text: 'a day, more or less',
              ),
            ],
          ),
        ),
      const SizedBox(height: AppSpacing.lg),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Line(
              icon: Icons.trending_up_rounded,
              text: 'Starting at $level, aiming for C1',
            ),
            if (goal case final goal?) ...[
              const SizedBox(height: AppSpacing.md),
              _Line(icon: Icons.flag_outlined, text: goal.label),
            ],
            if (language case final language?) ...[
              const SizedBox(height: AppSpacing.md),
              _Line(
                icon: Icons.translate_rounded,
                text: 'Corrections that know $language',
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _Line(
              icon: Icons.explore_outlined,
              text: themes.isEmpty
                  ? 'Every theme, for now'
                  : 'Your themes: ${(themes.toList()..sort()).join(', ')}',
            ),
          ],
        ),
      ),
    ],
  );
}

class _PlanFigure extends StatelessWidget {
  const _PlanFigure({required this.figure, required this.text});

  final String figure;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      SizedBox(
        width: 48,
        child: Text(
          figure,
          style: const TextStyle(
            fontFamily: displayFontFamily,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.highlight,
          ),
        ),
      ),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.background,
          ),
        ),
      ),
    ],
  );
}

/// What the free plan gives, and what Leera Plus adds.
class _FreeOrPlus extends StatelessWidget {
  const _FreeOrPlus();

  static const _rows = [
    ('Topics, research and Explore', 'yes', 'yes'),
    ('Corrections by Claude', '1 a week', '3 a day'),
    ('Journal and progress', 'yes', 'yes'),
    ('Vocabulary review', 'no', 'yes'),
    ('Daily topic from your themes', 'no', 'yes'),
  ];

  Widget _cell(String value, {required bool plus}) => switch (value) {
    'yes' => Icon(
      Icons.check_circle_rounded,
      size: 20,
      color: plus ? AppColors.primary : AppColors.textMuted,
      semanticLabel: 'Included',
    ),
    'no' => const Icon(
      Icons.remove_rounded,
      size: 20,
      color: AppColors.surfaceMuted,
      semanticLabel: 'Not included',
    ),
    _ => Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: plus ? AppColors.primary : AppColors.textMuted,
      ),
    ),
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Title(
        'Free, or Plus?',
        detail:
            'Start free and upgrade when you want. Plus is free for 7 days, '
            'then billed by the App Store; cancel anytime in Settings.',
      ),
      const SizedBox(height: AppSpacing.xl),
      Container(
        key: const ValueKey('welcome-compare'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(child: SizedBox.shrink()),
                SizedBox(
                  width: 64,
                  child: Text(
                    'Free',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    'Plus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            for (final (feature, free, plus) in _rows) ...[
              const Divider(height: 1, color: AppColors.surfaceMuted),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Center(child: _cell(free, plus: false)),
                    ),
                    SizedBox(
                      width: 64,
                      child: Center(child: _cell(plus, plus: true)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
    ],
  );
}
