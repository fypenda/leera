import 'package:flutter_test/flutter_test.dart';
import 'package:leera/features/english/domain/kept_words.dart';
import 'package:leera/features/english/domain/session_feedback.dart';

import '../../../support/fake_ai.dart';

void main() {
  test('each word once, from its latest correction, the latest first', () {
    final words = keptWords({
      'old': sampleFeedback(
        createdAt: DateTime.utc(2026, 10, 1),
        vocabulary: const [
          VocabularyItem('chokepoint', 'older meaning'),
          VocabularyItem('to bottleneck', 'to slow down'),
        ],
      ),
      'new': sampleFeedback(
        createdAt: DateTime.utc(2026, 10, 3),
        vocabulary: const [VocabularyItem('Chokepoint ', 'newer meaning')],
      ),
    });

    expect([for (final w in words) (w.sessionId, w.item.meaning)], [
      ('new', 'newer meaning'),
      ('old', 'to slow down'),
    ]);
  });

  test('search looks in the expression and the meaning, ignoring case', () {
    final words = keptWords({
      's': sampleFeedback(
        vocabulary: const [
          VocabularyItem('chokepoint', 'a narrow passage'),
          VocabularyItem('to bottleneck', 'to slow down'),
        ],
      ),
    });

    expect(searchWords(words, '  ').length, 2);
    expect(searchWords(words, 'CHOKE').single.item.expression, 'chokepoint');
    expect(searchWords(words, 'slow').single.item.expression, 'to bottleneck');
    expect(searchWords(words, 'canal'), isEmpty);
  });
}
