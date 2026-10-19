import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common/id_generator.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/clock.dart';
import '../domain/practice_session_repository.dart';
import 'drift_practice_session_repository.dart';

/// The practice sessions repository. This is the only place the English
/// module reads the database provider; everything else depends on
/// [PracticeSessionRepository].
final practiceSessionRepositoryProvider = Provider<PracticeSessionRepository>((
  ref,
) {
  return DriftPracticeSessionRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  );
});
