import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings.dart';
import '../../features/english/application/english_themes.dart';
import '../../features/english/data/preference_repository_providers.dart';
import '../../features/english/presentation/session_chrome.dart';
import '../../features/english/presentation/theme_style.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// The welcome, once, before the first topic: how Leera works, the level
/// the person thinks they have, and the themes they like.
///
/// The level is shown until a correction estimates it. The themes come
/// first in Explore, and with Leera Plus the daily topic is drawn from them.
/// Nothing is stored before the last step: leaving halfway starts over.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

/// The levels offered, with how each feels from the inside.
const _levels = [
  ('A2', 'I get by in simple conversations'),
  ('B1', 'I handle everyday situations'),
  ('B2', 'I can discuss most topics'),
  ('C1', 'I am fluent, and polishing'),
];

class _WelcomePageState extends ConsumerState<WelcomePage> {
  static const _steps = 4;
  static const double _maxWidth = 560;

  var _step = 0;
  String? _level;
  final _themes = <String>{};
  var _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      if (_level case final level?) {
        await settings.write(SettingKeys.selfAssessedLevel, level);
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
      _ => (
        _Ready(level: _level, themes: _themes),
        "Let's go",
        _saving ? null : _finish,
      ),
    };

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
                      icon: Icons.arrow_forward_rounded,
                      onTap: onAction,
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
      for (final (value, description) in _levels) ...[
        Semantics(
          inMutuallyExclusiveGroup: true,
          checked: value == level,
          button: true,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: value == level ? AppColors.ink : AppColors.surfaceMuted,
                width: value == level ? 2.5 : 2,
              ),
            ),
            child: InkWell(
              key: ValueKey('welcome-level-$value'),
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: value == level
                            ? AppColors.highlight
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontFamily: displayFontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
      ],
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

class _Ready extends StatelessWidget {
  const _Ready({required this.level, required this.themes});

  final String? level;
  final Set<String> themes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Title(
        "You're all set",
        detail:
            'One topic a day is enough. On the free plan, Claude corrects '
            'one presentation a week; Leera Plus gives you three a day.',
      ),
      const SizedBox(height: AppSpacing.xl),
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
