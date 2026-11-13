import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preference_repository_providers.dart';
import '../domain/kept_words.dart';
import '../domain/word_review.dart';
import 'english_feedback.dart';
import 'english_idioms.dart';
import 'english_videos.dart';

final wordReviewsProvider = StreamProvider<Map<String, WordReview>>(
  (ref) => ref.watch(wordReviewRepositoryProvider).watchReviews(),
);

/// Every word kept from the corrections and the expressions of the day,
/// the latest first.
final keptWordsProvider = Provider<AsyncValue<List<KeptWord>>>((ref) {
  final ofTheDay = [
    ...ref.watch(keptIdiomsProvider),
    ...ref.watch(keptVideoWordsProvider),
  ];
  return ref
      .watch(feedbacksProvider)
      .whenData((feedbacks) => keptWords(feedbacks, ofTheDay: ofTheDay));
});

/// By word key: true if the person knows it, false if they want to learn
/// it. Words never sorted are not in it.
final wordTriageProvider = StreamProvider<Map<String, bool>>(
  (ref) => ref.watch(wordTriageRepositoryProvider).watchTriage(),
);

/// The keys of the words the person knows: left out of the review.
final knownWordsProvider = Provider<Set<String>>(
  (ref) => {
    for (final MapEntry(:key, :value)
        in (ref.watch(wordTriageProvider).value ?? const {}).entries)
      if (value) key,
  },
);
