import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/features/english/data/topic_catalog.dart';
import 'package:leera/features/english/presentation/theme_style.dart';

void main() {
  test('every theme of the catalog has its own icon', () {
    final themes = {for (final topic in topicCatalog) ...topic.themes};
    for (final theme in themes) {
      expect(theme.trim(), isNotEmpty);
      expect(
        themeStyle(theme).icon,
        isNot(Icons.label_outline_rounded),
        reason: theme,
      );
    }
  });

  test('every theme has a few topics to choose from', () {
    final counts = <String, int>{};
    for (final topic in topicCatalog) {
      for (final theme in topic.themes) {
        counts[theme] = (counts[theme] ?? 0) + 1;
      }
    }
    for (final MapEntry(:key, :value) in counts.entries) {
      expect(value, greaterThanOrEqualTo(5), reason: key);
    }
  });
}
