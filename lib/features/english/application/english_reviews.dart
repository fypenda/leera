import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preference_repository_providers.dart';
import '../domain/kept_words.dart';
import '../domain/word_review.dart';
import 'english_feedback.dart';

final wordReviewsProvider = StreamProvider<Map<String, WordReview>>(
  (ref) => ref.watch(wordReviewRepositoryProvider).watchReviews(),
);

/// Every word kept from the corrections, the latest first.
final keptWordsProvider = Provider<AsyncValue<List<KeptWord>>>(
  (ref) => ref.watch(feedbacksProvider).whenData(keptWords),
);

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
