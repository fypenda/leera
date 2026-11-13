import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/time/calendar_date.dart';
import 'package:leera/features/english/data/idiom_bank.dart';
import 'package:leera/features/english/domain/idiom.dart';

const _a = Idiom(id: 'a', level: 'B1', expression: 'a', meaning: '', example: '');
const _b = Idiom(id: 'b', level: 'B1', expression: 'b', meaning: '', example: '');
const _c = Idiom(id: 'c', level: 'B1', expression: 'c', meaning: '', example: '');

void main() {
  final today = CalendarDate(2026, 11, 13);

  test('the bank has distinct, complete expressions', () {
    expect(idiomBank.length, greaterThanOrEqualTo(100));
    expect(idiomBank.map((idiom) => idiom.id).toSet(), hasLength(idiomBank.length));
    for (final idiom in idiomBank) {
      expect(idiom.meaning, isNotEmpty, reason: idiom.id);
      expect(idiom.example, isNotEmpty, reason: idiom.id);
      expect(['B1', 'B2', 'C1'], contains(idiom.level), reason: idiom.id);
    }
  });

  test('gifts are stored, and read back', () {
    final gifts = [
      IdiomGift(day: today, idiomId: 'b', kept: true),
      IdiomGift(day: CalendarDate(2026, 11, 10), idiomId: 'a'),
    ];
    final stored = encodeGifts(gifts);
    expect(stored, '2026-11-10:a:0,2026-11-13:b:1');
    expect(parseGifts(stored), {
      CalendarDate(2026, 11, 10): gifts[1],
      today: gifts[0],
    });
    expect(parseGifts(null), isEmpty);
    expect(parseGifts('garbage,2026-02-30:a:1,2026-11-12::0'), isEmpty);
  });

  test("today's expression is the one given today, or the next never given", () {
    const bank = [_a, _b, _c];
    expect(idiomOfTheDay(bank, const {}, today), _a);

    final yesterday = today.addDays(-1);
    final gifts = {yesterday: IdiomGift(day: yesterday, idiomId: 'a')};
    expect(idiomOfTheDay(bank, gifts, today), _b);

    gifts[today] = IdiomGift(day: today, idiomId: 'c');
    expect(idiomOfTheDay(bank, gifts, today), _c);
  });

  test('once all were given, the oldest comes back', () {
    const bank = [_a, _b];
    final gifts = {
      today.addDays(-1): IdiomGift(day: today.addDays(-1), idiomId: 'a'),
      today.addDays(-5): IdiomGift(day: today.addDays(-5), idiomId: 'b'),
    };
    expect(idiomOfTheDay(bank, gifts, today), _b);
  });

  test('the gift opens with a session or a review done today', () {
    expect(giftUnlocked(practisedToday: false, reviewedToday: false), isFalse);
    expect(giftUnlocked(practisedToday: true, reviewedToday: false), isTrue);
    expect(giftUnlocked(practisedToday: false, reviewedToday: true), isTrue);
  });
}
