import 'word_review.dart';

/// Where the reviews of kept words are stored.
abstract interface class WordReviewRepository {
  /// Every review, by word key, updated as they change.
  Stream<Map<String, WordReview>> watchReviews();

  /// Stores [review], replacing the word's previous one.
  Future<void> save(WordReview review);
}

/// Where it is kept which words the person knows, and which they want to
/// learn.
abstract interface class WordTriageRepository {
  /// By word key: true if known, false if to learn. A word not in it was
  /// never sorted.
  Stream<Map<String, bool>> watchTriage();

  Future<void> sort(String key, {required bool known, required DateTime at});
}
