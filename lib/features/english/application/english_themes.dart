import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_actions.dart';
import '../../../core/auth/quota.dart';
import '../data/preference_repository_providers.dart';
import '../data/topic_catalog.dart';

/// The themes chosen for the daily topic. Empty: every theme.
final preferredThemesProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(themePreferenceRepositoryProvider).watchThemes(),
);

/// Whether this account may choose its themes: Leera Plus, or a developer
/// account. Unknown while the plan has not loaded (offline, say): the
/// themes chosen stay in use.
final canChooseThemesProvider = Provider<bool>(
  (ref) => ref.watch(quotaProvider).value?.plan != Plan.free,
);

/// The themes the next topic is drawn from: the ones chosen, as long as
/// the account may choose them.
final dailyThemesProvider = Provider<Set<String>>(
  (ref) => ref.watch(canChooseThemesProvider)
      ? ref.watch(preferredThemesProvider).value ?? const {}
      : const {},
);

/// Every theme of the catalog with its number of topics, the most
/// furnished first, then by name.
final catalogThemesProvider = Provider<List<(String, int)>>((ref) {
  final counts = <String, int>{};
  for (final topic in topicCatalog) {
    for (final theme in topic.themes) {
      counts[theme] = (counts[theme] ?? 0) + 1;
    }
  }
  return [for (final MapEntry(:key, :value) in counts.entries) (key, value)]
    ..sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
});
