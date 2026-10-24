import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/time/calendar_date.dart';
import 'package:leera/features/english/domain/kept_words.dart';
import 'package:leera/features/english/domain/session_feedback.dart';
import 'package:leera/features/english/domain/word_review.dart';

final _today = CalendarDate(2026, 10, 5);
final _now = DateTime.utc(2026, 10, 5, 9);

WordReview _answer(WordReview? previous, {required bool knew}) =>
    WordReview.answer(
      key: 'chokepoint',
      previous: previous,
      knew: knew,
      today: _today,
      now: _now,
    );

WordReview _review(String key, {int box = 1, required CalendarDate dueOn}) =>
    WordReview(key: key, box: box, dueOn: dueOn, reviewedAt: _now);

KeptWord _word(String expression) => KeptWord(
  item: VocabularyItem(expression, 'meaning'),
  sessionId: 's',
  keptAt: _now,
);

void main() {
  group('an answer', () {
    test('known at once skips the first box: back in 3 days', () {
      final review = _answer(null, knew: true);
      expect(review.box, 1);
      expect(review.dueOn, CalendarDate(2026, 10, 8));
    });

    test('known again moves up a box, up to the last', () {
      expect(_answer(_review('chokepoint', box: 2, dueOn: _today), knew: true)
          .dueOn, CalendarDate(2026, 10, 19));
      final last = _answer(_review('chokepoint', box: 5, dueOn: _today),
          knew: true);
      expect(last.box, 5);
      expect(last.dueOn, _today.addDays(60));
    });

    test('missed goes back to the first box: back tomorrow', () {
      final review = _answer(_review('chokepoint', box: 4, dueOn: _today),
          knew: false);
      expect(review.box, 0);
      expect(review.dueOn, CalendarDate(2026, 10, 6));
    });
  });

  test('the queue: overdue first, then never reviewed, then nothing else', () {
    final words = [
      _word('new'),
      _word('later'),
      _word('due today'),
      _word('long overdue'),
    ];
    final reviews = {
      'later': _review('later', dueOn: _today.addDays(2)),
      'due today': _review('due today', dueOn: _today),
      'long overdue': _review('long overdue', dueOn: _today.addDays(-9)),
    };

    expect(
      [for (final w in reviewQueue(words, reviews, _today)) w.key],
      ['long overdue', 'due today', 'new'],
    );
    expect(reviewQueue(words, reviews, _today, limit: 1).single.key,
        'long overdue');
  });
}
