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

/// [WordTriageRepository] backed by the local SQLite database.
class DriftWordTriageRepository implements WordTriageRepository {
  DriftWordTriageRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<Map<String, bool>> watchTriage() => _db
      .select(_db.wordTriage)
      .watch()
      .map((rows) => {for (final row in rows) row.expressionKey: row.known});

  @override
  Future<void> sort(String key, {required bool known, required DateTime at}) {
    if (key.trim().isEmpty) throw ArgumentError.value(key, 'key');
    return _db
        .into(_db.wordTriage)
        .insertOnConflictUpdate(
          WordTriageCompanion.insert(
            expressionKey: key,
            known: known,
            decidedAt: at.toUtc(),
          ),
        );
  }
}
