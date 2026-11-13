import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../features/english/domain/learner_profile.dart';
import '../../features/english/domain/study_pace.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

// The choices that describe the learner, shared by the welcome and the
// account page.

/// The levels offered: a name, and how each feels from the inside.
const learnerLevels = [
  ('A2', 'Getting by', 'Simple conversations'),
  ('B1', 'Everyday', 'Most daily situations'),
  ('B2', 'Confident', 'Most topics'),
  ('C1', 'Fluent', 'Polishing it'),
];

/// Cards two by two, as wide as the room allows.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 12.0;
      final width = (box.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// One of a few options, as a card: a round badge, a name, a line. The
/// chosen one takes [tint] and a dark border.
class _Card extends StatelessWidget {
  const _Card({
    required this.index,
    required this.optionKey,
    required this.selected,
    required this.tint,
    required this.badge,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  /// Its place in the grid: cards arrive one after the other.
  final int index;
  final Key optionKey;
  final bool selected;
  final Color tint;
  final Widget badge;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RiseIn(
    delay: Duration(milliseconds: 100 + index * 60),
    child: SelectPop(
      selected: selected,
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        child: Material(
          color: selected ? tint : AppColors.surface,
          animationDuration: const Duration(milliseconds: 200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: selected ? AppColors.ink : AppColors.surfaceMuted,
              width: selected ? 2.5 : 2,
            ),
          ),
          child: InkWell(
            key: optionKey,
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              Haptics.selection();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 132),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badge,
                    const SizedBox(height: AppSpacing.sm + 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _badge({required Color color, required Widget child}) => AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  width: 44,
  height: 44,
  alignment: Alignment.center,
  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  child: child,
);

class LevelChoices extends StatelessWidget {
  const LevelChoices({super.key, required this.level, required this.onChanged});

  final String? level;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => _Grid(
    children: [
      for (final (index, (value, title, detail)) in learnerLevels.indexed)
        _Card(
          index: index,
          optionKey: ValueKey('welcome-level-$value'),
          selected: value == level,
          tint: AppColors.primarySoft,
          badge: _badge(
            color: value == level ? AppColors.ink : AppColors.highlight,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: displayFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: value == level ? AppColors.surface : AppColors.ink,
              ),
            ),
          ),
          title: title,
          detail: detail,
          onTap: () => onChanged(value),
        ),
    ],
  );
}

class GoalChoices extends StatelessWidget {
  const GoalChoices({super.key, required this.goal, required this.onChanged});

  final LearnerGoal? goal;
  final ValueChanged<LearnerGoal> onChanged;

  static const _looks = {
    LearnerGoal.work: (Icons.work_outline_rounded, AppColors.accentSoft),
    LearnerGoal.studies: (Icons.school_outlined, AppColors.primarySoft),
    LearnerGoal.exam: (Icons.assignment_turned_in_outlined, AppColors.coralSoft),
    LearnerGoal.travel: (Icons.flight_takeoff_rounded, AppColors.accentSoft),
    LearnerGoal.everyday: (Icons.favorite_border_rounded, AppColors.coralSoft),
  };

  @override
  Widget build(BuildContext context) => _Grid(
    children: [
      for (final value in LearnerGoal.values)
        if (_looks[value] case (final icon, final tint)?)
          _Card(
            index: value.index,
            optionKey: ValueKey('welcome-goal-${value.name}'),
            selected: value == goal,
            tint: tint,
            badge: _badge(
              color: value == goal ? AppColors.surface : tint,
              child: Icon(icon, size: 20, color: AppColors.ink),
            ),
            title: value.label,
            detail: value.detail,
            onTap: () => onChanged(value),
          ),
    ],
  );
}

/// The week to keep: minutes a day and the days, under a card that
/// shows the week they make as they change.
class RhythmPicker extends StatefulWidget {
  const RhythmPicker({super.key, required this.plan, required this.onChanged});

  final WeeklyPlan plan;
  final ValueChanged<WeeklyPlan> onChanged;

  @override
  State<RhythmPicker> createState() => _RhythmPickerState();
}

class _RhythmPickerState extends State<RhythmPicker> {
  /// The minutes it opened with, struck through once they change.
  late final int _was = widget.plan.minutes;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _eyebrow = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: AppColors.textMuted,
  );

  void _toggle(int weekday) {
    Haptics.selection();
    final days = {...widget.plan.days};
    days.contains(weekday) ? days.remove(weekday) : days.add(weekday);
    widget.onChanged(widget.plan.copyWith(days: days));
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final duration = motionOn(context)
        ? const Duration(milliseconds: 300)
        : Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The week it makes.
        RiseIn(
          child: Container(
            key: const ValueKey('rhythm-preview'),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      padding: const EdgeInsets.only(bottom: 14),
                      alignment: Alignment.bottomCenter,
                      decoration: const BoxDecoration(
                        color: AppColors.highlight,
                        shape: BoxShape.circle,
                      ),
                      child: const LogoBars(height: 23, barWidth: 7),
                    ),
                    const Spacer(),
                    ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var day = 1; day <= 7; day++) ...[
                                if (day > 1) const SizedBox(width: 4),
                                AnimatedContainer(
                                  duration: duration,
                                  curve: Curves.easeOutBack,
                                  width: 5,
                                  height: plan.days.contains(day) ? 22 : 12,
                                  decoration: BoxDecoration(
                                    color: plan.days.contains(day)
                                        ? AppColors.ink
                                        : AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${plan.sessions} / 7',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  plan.sessions == 1
                      ? '1 topic a week'
                      : '${plan.sessions} topics a week',
                  key: const ValueKey('rhythm-headline'),
                  style: const TextStyle(
                    fontFamily: displayFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.days.isEmpty
                            ? 'Choose your days below'
                            : '${plan.daysLabel} · ${plan.minutes} min a day',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (plan.reviews > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plan.reviews == 1
                              ? '1 review a week'
                              : '${plan.reviews} reviews a week',
                          key: const ValueKey('rhythm-reviews'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const RiseIn(
          delay: Duration(milliseconds: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MAKE IT A HABIT', style: _eyebrow),
              SizedBox(height: 2),
              Text(
                'Small enough to keep, every week.',
                style: TextStyle(fontSize: 15, color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Minutes a day.
        RiseIn(
          delay: const Duration(milliseconds: 180),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${plan.minutes}',
                      style: const TextStyle(
                        fontFamily: displayFontFamily,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'minutes a day',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (plan.minutes != _was)
                      Text(
                        'was $_was',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.ink,
                    inactiveTrackColor: AppColors.surfaceMuted,
                    thumbColor: AppColors.ink,
                    overlayColor: AppColors.ink.withValues(alpha: 0.08),
                    activeTickMarkColor: AppColors.surface,
                    inactiveTickMarkColor: AppColors.textMuted,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    key: const ValueKey('rhythm-minutes'),
                    min: WeeklyPlan.minuteSteps.first.toDouble(),
                    max: WeeklyPlan.minuteSteps.last.toDouble(),
                    divisions: WeeklyPlan.minuteSteps.length - 1,
                    value: plan.minutes.toDouble(),
                    semanticFormatterCallback: (value) =>
                        '${value.round()} minutes a day',
                    onChanged: (value) {
                      final minutes = value.round();
                      if (minutes == plan.minutes) return;
                      Haptics.selection();
                      widget.onChanged(plan.copyWith(minutes: minutes));
                    },
                  ),
                ),
                const ExcludeSemantics(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('10', style: _eyebrow),
                        Text('20', style: _eyebrow),
                        Text('30+', style: _eyebrow),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // The days.
        RiseIn(
          delay: const Duration(milliseconds: 260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('YOUR DAYS', style: _eyebrow),
              const SizedBox(height: AppSpacing.sm + 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var day = 1; day <= 7; day++)
                    Semantics(
                      button: true,
                      toggled: plan.days.contains(day),
                      label: _names[day - 1],
                      excludeSemantics: true,
                      child: SelectPop(
                        selected: plan.days.contains(day),
                        child: GestureDetector(
                          key: ValueKey('rhythm-day-$day'),
                          onTap: () => _toggle(day),
                          child: AnimatedContainer(
                            duration: duration,
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: plan.days.contains(day)
                                  ? AppColors.ink
                                  : AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _letters[day - 1],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: plan.days.contains(day)
                                    ? AppColors.surface
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    plan.days.isEmpty
                        ? 'Choose at least one day'
                        : 'One session on each day you chose',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The first language: one of the common ones, or another one typed.
class FirstLanguageChoices extends StatefulWidget {
  const FirstLanguageChoices({
    super.key,
    required this.language,
    required this.onChanged,
  });

  final String? language;

  /// Null when none is chosen.
  final ValueChanged<String?> onChanged;

  @override
  State<FirstLanguageChoices> createState() => _FirstLanguageChoicesState();
}

class _FirstLanguageChoicesState extends State<FirstLanguageChoices> {
  late var _other =
      widget.language != null &&
      !commonFirstLanguages.contains(widget.language);
  late final _typed = TextEditingController(
    text: _other ? widget.language : '',
  );

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Widget _chip(String label, {required bool selected, required VoidCallback onTap, Key? key}) =>
      ChoiceChip(
        key: key,
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primarySoft,
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.surfaceMuted,
        ),
        shape: const StadiumBorder(),
        onSelected: (_) {
          Haptics.selection();
          onTap();
        },
      );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final language in commonFirstLanguages)
            _chip(
              language,
              key: ValueKey('welcome-language-$language'),
              selected: !_other && widget.language == language,
              onTap: () {
                setState(() => _other = false);
                widget.onChanged(
                  widget.language == language ? null : language,
                );
              },
            ),
          _chip(
            'Another language',
            key: const ValueKey('welcome-language-other'),
            selected: _other,
            onTap: () {
              setState(() => _other = !_other);
              widget.onChanged(_other ? cleanFirstLanguage(_typed.text) : null);
            },
          ),
        ],
      ),
      if (_other) ...[
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('welcome-language-typed'),
          controller: _typed,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 40,
          decoration: InputDecoration(
            hintText: 'Your first language, in English',
            filled: true,
            fillColor: AppColors.surface,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (text) => widget.onChanged(cleanFirstLanguage(text)),
        ),
      ],
    ],
  );
}
