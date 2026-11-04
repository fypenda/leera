import 'package:flutter/material.dart';

import '../../features/english/domain/learner_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

// The choices that describe the learner, shared by the welcome and the
// account page.

/// The levels offered, with how each feels from the inside.
const learnerLevels = [
  ('A2', 'I get by in simple conversations'),
  ('B1', 'I handle everyday situations'),
  ('B2', 'I can discuss most topics'),
  ('C1', 'I am fluent, and polishing'),
];

/// One of a few options, as white cards; the chosen one has a dark border.
class _Option extends StatelessWidget {
  const _Option({
    required this.optionKey,
    required this.selected,
    required this.leading,
    required this.title,
    this.detail,
    required this.onTap,
  });

  final Key optionKey;
  final bool selected;
  final Widget leading;
  final String title;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
    child: Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? AppColors.ink : AppColors.surfaceMuted,
            width: selected ? 2.5 : 2,
          ),
        ),
        child: InkWell(
          key: optionKey,
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (detail case final detail?)
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
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class LevelChoices extends StatelessWidget {
  const LevelChoices({super.key, required this.level, required this.onChanged});

  final String? level;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (value, description) in learnerLevels)
        _Option(
          optionKey: ValueKey('welcome-level-$value'),
          selected: value == level,
          leading: Container(
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
          title: description,
          onTap: () => onChanged(value),
        ),
    ],
  );
}

class GoalChoices extends StatelessWidget {
  const GoalChoices({super.key, required this.goal, required this.onChanged});

  final LearnerGoal? goal;
  final ValueChanged<LearnerGoal> onChanged;

  static const _icons = {
    LearnerGoal.work: Icons.work_outline_rounded,
    LearnerGoal.studies: Icons.school_outlined,
    LearnerGoal.exam: Icons.assignment_turned_in_outlined,
    LearnerGoal.travel: Icons.flight_takeoff_rounded,
    LearnerGoal.everyday: Icons.favorite_border_rounded,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final value in LearnerGoal.values)
        _Option(
          optionKey: ValueKey('welcome-goal-${value.name}'),
          selected: value == goal,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value == goal ? AppColors.highlight : AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icons[value], size: 20, color: AppColors.ink),
          ),
          title: value.label,
          detail: value.detail,
          onTap: () => onChanged(value),
        ),
    ],
  );
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
        onSelected: (_) => onTap(),
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
