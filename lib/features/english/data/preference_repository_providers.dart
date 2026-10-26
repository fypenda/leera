import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../domain/theme_preferences.dart';
import '../domain/word_review_repository.dart';
import 'drift_theme_preference_repository.dart';
import 'drift_word_review_repository.dart';

/// The reviews repository. With the themes repository below and
/// [practiceSessionRepositoryProvider], the only places the English module
/// reads the database provider.
final wordReviewRepositoryProvider = Provider<WordReviewRepository>(
  (ref) => DriftWordReviewRepository(ref.watch(appDatabaseProvider)),
);

/// Where the themes of the daily topic are kept.
final themePreferenceRepositoryProvider = Provider<ThemePreferenceRepository>(
  (ref) => DriftThemePreferenceRepository(ref.watch(appDatabaseProvider)),
);
