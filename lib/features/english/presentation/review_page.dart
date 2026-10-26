import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/common/widgets/load_failure.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_formatting.dart';
import '../../../core/time/today.dart';
import '../application/english_reviews.dart';
import '../data/word_review_repository_provider.dart';
import '../domain/kept_words.dart';
import '../domain/word_review.dart';
import '../english_routes.dart';
import 'session_chrome.dart';

/// Reviewing the words kept, one card at a time: the expression first,
/// then its meaning, then whether it was known.
///
/// The words due are drawn once, when the page opens. A word missed comes
/// back once at the end of the round, and tomorrow.
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  /// The round, drawn once the words and reviews are loaded.
  List<KeptWord>? _queue;

  /// Words missed in this round, shown again at its end.
  final _missed = <String>{};
  var _index = 0;
  var _revealed = false;
  var _knownFirstTime = 0;
  var _saving = false;

  static const double _maxWidth = 560;

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(journalRouteName);
    }
  }

  Future<void> _answer(KeptWord word, {required bool knew}) async {
    if (_saving) return;
    final queue = _queue!;
    final repeat = _missed.contains(word.key);
    setState(() => _saving = true);
    try {
      // A word missed earlier in the round keeps its first answer: back
      // tomorrow, whatever happens now.
      if (!repeat) {
        await ref
            .read(wordReviewRepositoryProvider)
            .save(
              WordReview.answer(
                key: word.key,
                previous: ref.read(wordReviewsProvider).value?[word.key],
                knew: knew,
                today: ref.read(todayProvider),
                now: ref.read(clockProvider)(),
              ),
            );
      }
    } catch (e) {
      debugPrint('Saving a review failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!repeat && knew) _knownFirstTime++;
      if (!repeat && !knew) {
        _missed.add(word.key);
        queue.add(word);
      }
      _index++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(keptWordsProvider);
    final reviews = ref.watch(wordReviewsProvider);
    final today = ref.watch(todayProvider);

    // Drawn once: answering changes the reviews, not this round.
    if (_queue == null) {
      if (words case AsyncData(value: final kept) when reviews.hasValue) {
        _queue = reviewQueue(kept, reviews.requireValue, today);
      }
    }
    final queue = _queue;
    final failed = words.hasError || reviews.hasError;

    final Widget body;
    final Widget? bottom;
    if (queue == null) {
      body = failed
          ? LoadFailure(
              message: 'Your words could not be loaded.',
              onRetry: () => ref.invalidate(wordReviewsProvider),
            )
          : const SizedBox.shrink();
      bottom = null;
    } else if (queue.isEmpty) {
      body = _Message(
        key: const ValueKey('review-nothing-due'),
        title: 'Nothing to review today',
        text: _nextReview(reviews.value ?? const {}),
      );
      bottom = _done();
    } else if (_index >= queue.length) {
      final reviewed = queue.length - _missed.length;
      body = _Message(
        key: const ValueKey('review-finished'),
        title: 'Review done',
        text:
            '${reviewed == 1 ? '1 word' : '$reviewed words'} reviewed, '
            '$_knownFirstTime known straight away. '
            '${_missed.isEmpty ? 'Each comes back later, further apart.' : 'The ones you missed come back tomorrow.'}',
      );
      bottom = _done();
    } else {
      final word = queue[_index];
      body = _Card(word: word, revealed: _revealed);
      bottom = _revealed
          ? Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: FilledButton(
                      key: const ValueKey('review-again'),
                      onPressed: _saving
                          ? null
                          : () => _answer(word, knew: false),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.coralSoft,
                        foregroundColor: AppColors.coralStrong,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Again'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: BottomActionButton(
                    buttonKey: const ValueKey('review-knew'),
                    label: 'I knew it',
                    icon: Icons.check_rounded,
                    onTap: _saving ? null : () => _answer(word, knew: true),
                  ),
                ),
              ],
            )
          : BottomActionButton(
              buttonKey: const ValueKey('review-reveal'),
              label: 'Show the meaning',
              icon: Icons.visibility_outlined,
              onTap: () => setState(() => _revealed = true),
            );
    }

    final total = queue?.length ?? 0;
    final position = (_index + 1).clamp(0, total);

    return Scaffold(
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
                  Row(
                    children: [
                      RoundIconButton(
                        key: const ValueKey('review-close'),
                        icon: Icons.close_rounded,
                        label: 'Close',
                        onTap: _leave,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      if (total > 0 && _index < total) ...[
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _index / total,
                              minHeight: 6,
                              color: AppColors.highlight,
                              backgroundColor: AppColors.surfaceMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '$position / $total',
                          key: const ValueKey('review-position'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const StepEyebrow(
                    icon: Icons.bookmark_border_rounded,
                    label: 'Vocabulary review',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // The card fills the height left, as a flashcard; it
                  // scrolls only when its text is longer than the screen.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: box.maxHeight),
                          child: body,
                        ),
                      ),
                    ),
                  ),
                  if (bottom != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    bottom,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _done() => BottomActionButton(
    buttonKey: const ValueKey('review-done'),
    label: 'Done',
    icon: Icons.check_rounded,
    onTap: _leave,
  );

  /// When the next words come back, if any have been reviewed.
  static String _nextReview(Map<String, WordReview> reviews) {
    if (reviews.isEmpty) {
      return 'The words to keep from your corrections will come here to be '
          'reviewed.';
    }
    final next = reviews.values
        .map((review) => review.dueOn)
        .reduce((a, b) => a.daysUntil(b) < 0 ? b : a);
    return 'You are up to date. The next words come back on '
        '${formatShortDate(next)}.';
  }
}

/// A word: the expression, and once revealed its meaning and example.
class _Card extends StatelessWidget {
  const _Card({required this.word, required this.revealed});

  final KeptWord word;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final item = word.item;

    return Container(
      key: ValueKey('review-card-${word.key}'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.expression,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: displayFontFamily,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          if (!revealed) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Say what it means, then check.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.surfaceMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              item.meaning,
              key: const ValueKey('review-meaning'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: AppColors.ink,
              ),
            ),
            if (item.example.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '“${item.example}”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontFamily: displayFontFamily,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -0.6,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: AppColors.textMuted,
        ),
      ),
    ],
  );
}
