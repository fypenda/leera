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

  test('natural phrasings are kept too, short ones only', () {
    Correction correction(CorrectionKind kind, String fix) => Correction(
      kind: kind,
      original: 'I am agree with that',
      corrected: 'I agree with that',
      mistake: 'am agree',
      fix: fix,
      explanation: 'Agree is a verb.',
      tag: 'verbs',
    );
    final feedback = SessionFeedback(
      promptVersion: 'feedback-v3',
      model: 'claude-test',
      createdAt: DateTime.utc(2026, 11, 4),
      estimatedLevel: 'B2',
      headline: 'Good',
      summary: 'Clear.',
      scores: FeedbackScores(
        grammar: 7,
        vocabulary: 7,
        naturalness: 7,
        structure: 7,
        content: 7,
      ),
      corrections: [
        correction(CorrectionKind.naturalness, 'agree'),
        correction(CorrectionKind.grammar, 'agree with'),
        correction(CorrectionKind.naturalness, 'x' * (maxPhrasingLength + 1)),
        correction(CorrectionKind.naturalness, '  '),
      ],
      vocabulary: const [VocabularyItem('chokepoint', 'a narrow passage')],
      followUpQuestions: const [],
      recurringMistakesSeen: const [],
    );

    final words = wordsOf('s', feedback);

    expect([for (final w in words) (w.item.expression, w.phrasing)], [
      ('chokepoint', false),
      ('agree', true),
    ]);
    expect(words.last.item.meaning, 'Rather than “am agree”. Agree is a verb.');
    expect(words.last.item.example, 'I agree with that');
  });
}
