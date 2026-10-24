import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/word_review.dart';
import '../domain/word_review_repository.dart';

/// [WordReviewRepository] backed by the local SQLite database.
class DriftWordReviewRepository implements WordReviewRepository {
  DriftWordReviewRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<Map<String, WordReview>> watchReviews() =>
      _db.select(_db.wordReviews).watch().map(
        (rows) => {
          for (final row in rows)
            row.expressionKey: WordReview(
              key: row.expressionKey,
              box: row.box,
              dueOn: row.dueOn,
              reviewedAt: row.reviewedAt,
            ),
        },
      );

  @override
  Future<void> save(WordReview review) => _db
      .into(_db.wordReviews)
      .insertOnConflictUpdate(
        WordReviewsCompanion.insert(
          expressionKey: review.key,
          box: review.box,
          dueOn: review.dueOn,
          reviewedAt: review.reviewedAt,
        ),
      );
}
