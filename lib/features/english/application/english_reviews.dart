import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/word_review_repository_provider.dart';
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
