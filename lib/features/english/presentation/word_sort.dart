import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/english_reviews.dart';
import '../data/preference_repository_providers.dart';
import '../domain/kept_words.dart';

/// "I know it" or "To learn", for one kept word: a word known is left out
/// of the review. The choice can be changed at any time.
class WordSortButtons extends ConsumerWidget {
  const WordSortButtons({super.key, required this.word});

  final KeptWord word;

  Future<void> _sort(WidgetRef ref, bool known) async {
    try {
      await ref
          .read(wordTriageRepositoryProvider)
          .sort(word.key, known: known, at: ref.read(clockProvider)());
    } on Object catch (e) {
      debugPrint('Sorting a word failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = ref.watch(wordTriageProvider).value?[word.key];

    return Row(
      children: [
        Expanded(
          child: _Pill(
            key: ValueKey('know-${word.key}'),
            label: 'I know it',
            icon: Icons.check_rounded,
            selected: known == true,
            selectedColor: AppColors.primarySoft,
            selectedText: AppColors.primary,
            onTap: () => _sort(ref, true),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Pill(
            key: ValueKey('learn-${word.key}'),
            label: 'To learn',
            icon: Icons.bookmark_add_outlined,
            selected: known == false,
            selectedColor: AppColors.accentSoft,
            selectedText: AppColors.accentStrong,
            onTap: () => _sort(ref, false),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.selectedText,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color selectedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedText : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? selectedColor : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? selectedText : AppColors.surfaceMuted,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The words and phrasings of one correction, each to sort.
class ReviewCardsToSort extends ConsumerWidget {
  const ReviewCardsToSort({super.key, required this.words});

  final List<KeptWord> words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triage = ref.watch(wordTriageProvider).value ?? const {};
    final left = words.where((word) => !triage.containsKey(word.key)).length;

    return Column(
      key: const ValueKey('review-cards'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          left == 0
              ? 'All sorted. What you mark To learn comes back in your review.'
              : 'Sort them: what you mark To learn goes to your review, what '
                    'you know stays out of it.',
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final word in words) ...[
          Container(
            key: ValueKey('to-sort-${word.key}'),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (word.phrasing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(
                      'YOUR WORDS, MORE NATURAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Text(
                  word.item.expression,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  word.item.meaning,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                WordSortButtons(word: word),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
        ],
      ],
    );
  }
}
