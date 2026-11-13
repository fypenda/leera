import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_actions.dart';
import '../../core/auth/quota.dart';
import '../../core/auth/session.dart';
import '../../core/motion/leera_bubble.dart';
import '../../core/motion/motion.dart';
import '../../core/settings/settings.dart';
import '../../core/time/today.dart';
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

/// The welcome, once, before the first topic.
///
/// A dark splash, then what Leera is; the level the person thinks they
/// have, why they learn, their first language, the themes they like and
/// the week they will keep; free or Plus; and Day 1, which rolls the first
/// topic. Leera's bubble travels from screen to screen.
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

// The steps, in order.
const _splash = 0;
const _hello = 1;
const _levelStep = 2;
const _goalStep = 3;
const _languageStep = 4;
const _themesStep = 5;
const _rhythmStep = 6;
const _plusStep = 7;
const _dayOne = 8;

/// The steps with a question, shown as segments at the top.
const _firstQuestion = _levelStep;
const _lastQuestion = _plusStep;

class _WelcomePageState extends ConsumerState<WelcomePage> {
  static const double _maxWidth = 560;

  /// How long the splash stays before moving on by itself.
  static const _splashTime = Duration(milliseconds: 2200);

  var _step = _splash;
  String? _level;
  LearnerGoal? _goal;
  String? _language;
  final _themes = <String>{};
  var _plan = WeeklyPlan.standard;

  /// Changed at each choice: the bubble nods.
  var _nods = 0;
  var _saving = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(_splashTime, () {
      if (mounted && _step == _splash) _go(_hello);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void _go(int step) {
    _splashTimer?.cancel();
    setState(() => _step = step);
  }

  void _back() {
    if (_step > _hello) _go(_step - 1);
  }

  /// A choice made: kept, and the bubble nods.
  void _choose(VoidCallback change) => setState(() {
    change();
    _nods++;
  });

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
      await settings.write(SettingKeys.weeklyPlan, _plan.encode());
      if (_themes.isNotEmpty) {
        await ref.read(themePreferenceRepositoryProvider).setThemes(_themes);
      }
      // Today rolls the first topic as it opens.
      await settings.write(SettingKeys.rollOnArrival, 'yes');
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
    final dark = _step == _splash || _step == _dayOne;
    final motion = motionOn(context);
    final isPlus = switch (ref.watch(quotaProvider).value?.plan) {
      Plan.plus || Plan.dev => true,
      _ => false,
    };

    return PopScope(
      canPop: _step <= _hello,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: LayoutBuilder(
            builder: (context, box) {
              final padding = MediaQuery.paddingOf(context);
              final inner = box.maxHeight - padding.top - padding.bottom;
              final spot = _spot(box.maxWidth, inner, padding.top);

              return Stack(
                children: [
                  // A dark ground for the splash and Day 1.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: motion
                            ? const Duration(milliseconds: 600)
                            : Duration.zero,
                        opacity: dark ? 1 : 0,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(0, -0.24),
                              radius: 1.1,
                              colors: [
                                Color(0xFF3A5961),
                                AppColors.ink,
                                Color(0xFF1A252B),
                              ],
                              stops: [0, 0.55, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxWidth,
                          ),
                          child: _screen(inner, isPlus),
                        ),
                      ),
                    ),
                  ),
                  // Letters bursting out of the bubble, on Day 1.
                  if (_step == _dayOne && motion)
                    Positioned(
                      left: spot.left + spot.size / 2,
                      top: spot.top + spot.size * LeeraBubble.ratio / 2,
                      child: const IgnorePointer(
                        child: SizedBox.shrink(child: _LetterBurst()),
                      ),
                    ),
                  // Leera's bubble: one, travelling from screen to screen.
                  AnimatedPositioned(
                    duration: motion
                        ? const Duration(milliseconds: 750)
                        : Duration.zero,
                    curve: const Cubic(0.2, 0.8, 0.2, 1),
                    left: spot.left,
                    top: spot.top,
                    width: spot.size,
                    height: spot.size * LeeraBubble.ratio,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: motion
                            ? const Duration(milliseconds: 300)
                            : Duration.zero,
                        opacity: spot.visible ? 1 : 0,
                        child: FittedBox(
                          child: LeeraBubble(
                            key: const ValueKey('welcome-bubble'),
                            nods: _nods,
                            color: dark ? AppColors.background : AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Where the bubble sits on the current step, in the page.
  ({double left, double top, double size, bool visible}) _spot(
    double width,
    double inner,
    double safeTop,
  ) {
    final content = math.min(width, _maxWidth);
    final right = (width + content) / 2 - AppSpacing.xl;
    double centered(double size) => (width - size) / 2;
    return switch (_step) {
      _splash => (
        left: centered(150),
        top: safeTop + inner * 0.28,
        size: 150,
        visible: true,
      ),
      // In the middle of the dark circle.
      _hello => (
        left: centered(140),
        top: safeTop + _Hello.circleTop + 130 - 64,
        size: 140,
        visible: true,
      ),
      _dayOne => (
        left: centered(120),
        top: safeTop + 40,
        size: 120,
        visible: true,
      ),
      // By the title; out of the way of the rhythm's card.
      _ => (
        left: right - 48,
        top: safeTop + 76,
        size: 48,
        visible: _step != _rhythmStep,
      ),
    };
  }

  Widget _screen(double inner, bool isPlus) {
    if (_step == _splash) {
      return _Splash(
        textTop: inner * 0.28 + 170,
        onTap: () => _go(_hello),
      );
    }
    if (_step == _hello) return _Hello(onStart: () => _go(_levelStep));
    if (_step == _dayOne) {
      return _DayOne(
        level: _level,
        plan: _plan,
        saving: _saving,
        onBack: _back,
        onRoll: _finish,
      );
    }

    final (Widget body, String action, VoidCallback? onAction) = switch (_step) {
      _levelStep => (
        _Question(
          title: 'Where is your English today?',
          detail: "Your own estimate. Your first correction gives Claude's.",
          child: LevelChoices(
            level: _level,
            onChanged: (level) => _choose(() => _level = level),
          ),
        ),
        'Continue',
        _level == null ? null : () => _go(_goalStep),
      ),
      _goalStep => (
        _Question(
          title: 'What is your English for?',
          detail: 'Claude fits its corrections to it: the words, the tone.',
          child: GoalChoices(
            goal: _goal,
            onChanged: (goal) => _choose(() => _goal = goal),
          ),
        ),
        'Continue',
        _goal == null ? null : () => _go(_languageStep),
      ),
      _languageStep => (
        _Question(
          title: 'What is your first language?',
          detail:
              'So Claude can spot the traps it sets in English, such as '
              'false friends. Optional.',
          child: FirstLanguageChoices(
            language: _language,
            onChanged: (language) => _choose(() => _language = language),
          ),
        ),
        _language == null ? 'Skip' : 'Continue',
        () => _go(_themesStep),
      ),
      _themesStep => (
        _Question(
          title: 'What do you like to read about?',
          detail:
              'Your themes come first in Explore. With Leera Plus, your '
              'daily topic is drawn from them. You can change them later.',
          child: _Themes(
            chosen: _themes,
            onToggle: (theme) => _choose(
              () => _themes.contains(theme)
                  ? _themes.remove(theme)
                  : _themes.add(theme),
            ),
          ),
        ),
        _themes.isEmpty ? 'Skip for now' : 'Continue',
        () => _go(_rhythmStep),
      ),
      _rhythmStep => (
        RhythmPicker(
          plan: _plan,
          onChanged: (plan) => setState(() => _plan = plan),
        ),
        'Set my week',
        _plan.days.isEmpty ? null : () => _go(_plusStep),
      ),
      _ => (
        const _FreeOrPlus(),
        isPlus ? 'Continue' : 'Try Leera Plus free for 7 days',
        isPlus
            ? () => _go(_dayOne)
            : () {
                context.pushNamed(plusRouteName);
              },
      ),
    };
    final secondary = _step == _plusStep && !isPlus
        ? TextButton(
            key: const ValueKey('welcome-free'),
            onPressed: () => _go(_dayOne),
            child: const Text('Continue with the free plan'),
          )
        : null;

    return Padding(
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
                RoundIconButton(
                  key: const ValueKey('welcome-back'),
                  icon: Icons.chevron_left_rounded,
                  label: 'Back',
                  onTap: _back,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _Segments(step: _step)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _Slide(
              child: SingleChildScrollView(
                key: ValueKey('welcome-step-$_step'),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: body,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          BottomActionButton(
            buttonKey: const ValueKey('welcome-next'),
            label: action,
            icon: _step == _plusStep && !isPlus
                ? Icons.auto_awesome_rounded
                : Icons.arrow_forward_rounded,
            onTap: onAction,
          ),
          ?secondary,
        ],
      ),
    );
  }
}

/// Each step slides in from the right.
class _Slide extends StatelessWidget {
  const _Slide({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: motionOn(context)
        ? const Duration(milliseconds: 380)
        : Duration.zero,
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    layoutBuilder: (current, previous) =>
        Stack(alignment: Alignment.topCenter, children: [?current]),
    child: child,
  );
}

/// The questions, as segments filling in.
class _Segments extends StatelessWidget {
  const _Segments({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const count = _lastQuestion - _firstQuestion + 1;
    final at = step - _firstQuestion;
    return Semantics(
      label: 'Step ${at + 1} of $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: motionOn(context)
                    ? const Duration(milliseconds: 350)
                    : Duration.zero,
                height: 5,
                decoration: BoxDecoration(
                  color: i <= at ? AppColors.ink : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A question: its title, a line under it, then the choices.
class _Question extends StatelessWidget {
  const _Question({
    required this.title,
    required this.detail,
    required this.child,
  });

  final String title;
  final String detail;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RiseIn(
        child: Padding(
          // Room for the bubble, by the title.
          padding: const EdgeInsets.only(right: 60),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: displayFontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.7,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm + 2),
      RiseIn(
        delay: const Duration(milliseconds: 80),
        child: Text(
          detail,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      child,
    ],
  );
}

/// The dark splash: the name, the promise. It moves on by itself, or with
/// a tap.
class _Splash extends StatelessWidget {
  const _Splash({required this.textTop, required this.onTap});

  /// Where the name starts, under the bubble.
  final double textTop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('welcome-splash'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox.expand(
      child: Column(
      children: [
        SizedBox(height: textTop),
        const RiseIn(
          delay: Duration(milliseconds: 500),
          child: Text(
            'leera',
            style: TextStyle(
              fontFamily: displayFontFamily,
              fontSize: 52,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: AppColors.background,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const RiseIn(
          delay: Duration(milliseconds: 750),
          child: Text(
            'FLUENCY THROUGH REAL TOPICS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Color(0xFFBFE9EF),
            ),
          ),
        ),
        const Spacer(),
        const RiseIn(
          delay: Duration(milliseconds: 1100),
          child: Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xxl),
            child: Text(
              'Tap to begin',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8FA3AB),
              ),
            ),
          ),
        ),
      ],
    ),
    ),
  );
}

/// What Leera is: a dark circle holding the bubble, a few things floating
/// round it, and the promise.
class _Hello extends StatelessWidget {
  const _Hello({required this.onStart});

  final VoidCallback onStart;

  /// The circle's top, under the safe area.
  static const double circleTop = 32;

  static const _shadow = [
    BoxShadow(color: Color(0x2424323A), blurRadius: 24, offset: Offset(0, 10)),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      0,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: circleTop),
        Center(
          child: SizedBox(
            width: 260,
            height: 290,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const _PopFloat(
                  delay: Duration.zero,
                  float: false,
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          colors: [Color(0xFF3A5961), AppColors.ink],
                          stops: [0, 0.72],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 131,
                  top: -4,
                  child: _PopFloat(
                    delay: const Duration(milliseconds: 450),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: _shadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: AppColors.surface,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text(
                            '7-day streak',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -24,
                  top: 180,
                  child: _PopFloat(
                    delay: const Duration(milliseconds: 600),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: _shadow,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 24,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 180,
                  top: 232,
                  child: _PopFloat(
                    delay: const Duration(milliseconds: 750),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.highlight,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _shadow,
                      ),
                      child: const Text(
                        'B2 → C1',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        RiseIn(
          delay: const Duration(milliseconds: 350),
          child: Text.rich(
            const TextSpan(
              text: 'Real topics.\n',
              children: [
                TextSpan(
                  text: 'Real fluency.',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            style: const TextStyle(
              fontFamily: displayFontFamily,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.02,
              letterSpacing: -1,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const RiseIn(
          delay: Duration(milliseconds: 500),
          child: Text(
            'A topic is drawn. You research it, explain it in English, and '
            'Claude corrects you.',
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        RiseIn(
          delay: const Duration(milliseconds: 650),
          child: _StartButton(onTap: onStart),
        ),
      ],
    ),
  );
}

/// "Get started": a dark pill, a light sweeping across it, a teal arrow.
class _StartButton extends StatefulWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with SingleTickerProviderStateMixin {
  late final _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionOn(context)) {
      if (!_sheen.isAnimating) _sheen.repeat();
    } else {
      _sheen.stop();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Get started',
    excludeSemantics: true,
    child: Material(
      color: AppColors.ink,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('welcome-next'),
        onTap: () {
          Haptics.light();
          widget.onTap();
        },
        child: SizedBox(
          height: 62,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              fit: StackFit.expand,
              children: [
                if (motionOn(context))
                  AnimatedBuilder(
                    animation: _sheen,
                    builder: (context, _) => Positioned(
                      left: -80 + (box.maxWidth + 160) * _sheen.value,
                      top: 0,
                      bottom: 0,
                      width: 80,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0x1FFFFFFF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const Center(
                  child: Text(
                    'Get started',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.surface,
                    ),
                  ),
                ),
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.highlight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 22,
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
  );
}

/// [child] pops in after [delay], then bobs gently up and down.
class _PopFloat extends StatefulWidget {
  const _PopFloat({required this.delay, required this.child, this.float = true});

  final Duration delay;
  final bool float;
  final Widget child;

  @override
  State<_PopFloat> createState() => _PopFloatState();
}

class _PopFloatState extends State<_PopFloat> with TickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  Timer? _timer;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!motionOn(context)) {
      _pop.value = 1;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      _pop.forward();
      if (widget.float) _float.repeat();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pop.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_pop, _float]),
    child: widget.child,
    builder: (context, child) {
      final pop = Curves.easeOutBack.transform(_pop.value);
      final bob = -7 * (1 - math.cos(_float.value * 2 * math.pi)) / 2;
      return Opacity(
        opacity: _pop.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, bob),
          child: Transform.scale(scale: 0.3 + 0.7 * pop, child: child),
        ),
      );
    },
  );
}

class _Themes extends ConsumerWidget {
  const _Themes({required this.chosen, required this.onToggle});

  final Set<String> chosen;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = ref.watch(catalogThemesProvider);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (index, (theme, _)) in themes.indexed)
          RiseIn(
            delay: Duration(milliseconds: 80 + math.min(index, 12) * 30),
            child: FilterChip(
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
              onSelected: (_) {
                Haptics.selection();
                onToggle(theme);
              },
            ),
          ),
      ],
    );
  }
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
  Widget build(BuildContext context) => _Question(
    title: 'Free, or Plus?',
    detail:
        'Start free and upgrade when you want. Plus is free for 7 days, '
        'then billed by the App Store; cancel anytime in Settings.',
    child: RiseIn(
      delay: const Duration(milliseconds: 160),
      child: Container(
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
    ),
  );
}

/// Day 1, on the dark ground: the week that starts today, what is known of
/// the person, and the first topic to roll.
class _DayOne extends ConsumerWidget {
  const _DayOne({
    required this.level,
    required this.plan,
    required this.saving,
    required this.onBack,
    required this.onRoll,
  });

  final String? level;
  final WeeklyPlan plan;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onRoll;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static const _chip = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.background,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider).weekday;
    final levelChip = switch (level) {
      null => null,
      'C1' => 'C1, polishing',
      final level => '$level → C1',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RoundIconButton(
                key: const ValueKey('welcome-back'),
                icon: Icons.chevron_left_rounded,
                label: 'Back',
                onTap: onBack,
              ),
            ],
          ),
          // Room for the bubble.
          const SizedBox(height: 92),
          Align(
            alignment: const Alignment(0.62, 0),
            child: _PopFloat(
              delay: const Duration(milliseconds: 900),
              float: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(7, 7, 14, 7),
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      '+1 day',
                      style: TextStyle(
                        fontFamily: displayFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  const _PopFloat(
                    delay: Duration(milliseconds: 550),
                    float: false,
                    child: Text(
                      'Day 1',
                      key: ValueKey('welcome-day-one'),
                      style: TextStyle(
                        fontFamily: displayFontFamily,
                        fontSize: 78,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -2,
                        color: AppColors.highlight,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  const RiseIn(
                    delay: Duration(milliseconds: 800),
                    child: Text(
                      'Your first topic is waiting.',
                      style: TextStyle(fontSize: 16, color: Color(0xFFD5DCE0)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  RiseIn(
                    delay: const Duration(milliseconds: 1000),
                    child: Semantics(
                      label:
                          'Your week: ${plan.daysLabel}, starting today',
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF),
                          border: Border.all(color: const Color(0x14FFFFFF)),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var day = 1; day <= 7; day++)
                              Column(
                                children: [
                                  Text(
                                    _letters[day - 1],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF8FA3AB),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  if (day == today)
                                    const _Pulse(
                                      child: _WeekDot(
                                        color: AppColors.highlight,
                                      ),
                                    )
                                  else
                                    _WeekDot(
                                      border: plan.days.contains(day)
                                          ? const Color(0x59FFFFFF)
                                          : const Color(0x1FFFFFFF),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RiseIn(
                    delay: const Duration(milliseconds: 1150),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final text in [
                          ?levelChip,
                          '${plan.minutes} min a day',
                          plan.sessions == 1
                              ? '1 session a week'
                              : '${plan.sessions} sessions a week',
                        ])
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(text, style: _chip),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 60,
            child: FilledButton(
              key: const ValueKey('welcome-next'),
              onPressed: saving
                  ? null
                  : () {
                      Haptics.success();
                      onRoll();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.ink,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Roll my first topic'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDot extends StatelessWidget {
  const _WeekDot({this.color, this.border});

  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: border == null ? null : Border.all(color: border!, width: 2),
    ),
  );
}

/// A ring spreading out of [child], again and again: today.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionOn(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final t = Curves.easeOut.transform(_controller.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.highlight.withValues(alpha: 0.6 * (1 - t)),
              spreadRadius: 12 * t,
            ),
          ],
        ),
        child: child,
      );
    },
  );
}

/// Letters flying out of the bubble and fading, over and over.
class _LetterBurst extends StatefulWidget {
  const _LetterBurst();

  @override
  State<_LetterBurst> createState() => _LetterBurstState();
}

class _LetterBurstState extends State<_LetterBurst>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  static const _bits = ['A', 'b', '?', '!', 'C1', 'ok', '“', 'hi', 'B2', '…'];
  static const _colors = [
    AppColors.highlight,
    AppColors.accent,
    AppColors.background,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (i, bit) in _bits.indexed)
          () {
            // Each letter starts a little after the one before.
            final t = (_controller.value + (i % 5) * 0.16) % 1;
            final k = Curves.easeOutCubic.transform(t);
            final angle = 2 * math.pi * i / _bits.length;
            final opacity = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85;
            return Positioned(
              left: -14 + math.cos(angle) * 150 * k,
              top: -12 + (math.sin(angle) * 120 - 40) * k,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: (i.isOdd ? 20 : -20) * math.pi / 180 * k,
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * k,
                    child: Text(
                      bit,
                      style: TextStyle(
                        fontFamily: displayFontFamily,
                        fontSize: 14 + (i % 3) * 4,
                        fontWeight: FontWeight.w800,
                        color: _colors[i % 3],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }(),
      ],
    ),
  );
}
