import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../domain/word_review_repository.dart';
import 'drift_word_review_repository.dart';

/// The reviews repository: with [practiceSessionRepositoryProvider], the
/// only places the English module reads the database provider.
final wordReviewRepositoryProvider = Provider<WordReviewRepository>(
  (ref) => DriftWordReviewRepository(ref.watch(appDatabaseProvider)),
);
