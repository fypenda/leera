import 'word_review.dart';

/// Where the reviews of kept words are stored.
abstract interface class WordReviewRepository {
  /// Every review, by word key, updated as they change.
  Stream<Map<String, WordReview>> watchReviews();

  /// Stores [review], replacing the word's previous one.
  Future<void> save(WordReview review);
}
