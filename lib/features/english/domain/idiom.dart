import '../../../core/time/calendar_date.dart';

/// An expression of the day: an idiom, what it means, and a sentence that
/// uses it.
class Idiom {
  const Idiom({
    required this.id,
    required this.level,
    required this.expression,
    required this.meaning,
    required this.example,
  });

  final String id;

  /// The CEFR level it is usually met at.
  final String level;
  final String expression;
  final String meaning;
  final String example;
}

/// The expression given on a [day], and whether the person kept it to
/// review.
class IdiomGift {
  const IdiomGift({
    required this.day,
    required this.idiomId,
    this.kept = false,
  });

  final CalendarDate day;
  final String idiomId;
  final bool kept;

  IdiomGift withKept(bool kept) =>
      IdiomGift(day: day, idiomId: idiomId, kept: kept);

  @override
  bool operator ==(Object other) =>
      other is IdiomGift &&
      other.day == day &&
      other.idiomId == idiomId &&
      other.kept == kept;

  @override
  int get hashCode => Object.hash(day, idiomId, kept);
}

/// The gifts as stored: `2026-11-13:break-the-ice:1`, comma separated,
/// 1 when kept.
String encodeGifts(Iterable<IdiomGift> gifts) {
  final sorted = gifts.toList()..sort((a, b) => a.day.compareTo(b.day));
  return [
    for (final gift in sorted)
      '${gift.day.toIso8601()}:${gift.idiomId}:${gift.kept ? 1 : 0}',
  ].join(',');
}

/// The gifts stored, by day; anything unreadable is skipped.
Map<CalendarDate, IdiomGift> parseGifts(String? stored) {
  final gifts = <CalendarDate, IdiomGift>{};
  for (final entry in (stored ?? '').split(',')) {
    final parts = entry.split(':');
    if (parts.length != 3 || parts[1].isEmpty) continue;
    try {
      final day = CalendarDate.parse(parts[0]);
      gifts[day] = IdiomGift(day: day, idiomId: parts[1], kept: parts[2] == '1');
    } on FormatException {
      continue;
    } on ArgumentError {
      continue;
    }
  }
  return gifts;
}

/// The expression for [today]: the one already given today, or else the
/// first of [bank] never given. Once all have been given, the one given
/// longest ago comes back.
Idiom idiomOfTheDay(
  List<Idiom> bank,
  Map<CalendarDate, IdiomGift> gifts,
  CalendarDate today,
) {
  if (bank.isEmpty) throw ArgumentError.value(bank, 'bank', 'is empty');
  final byId = {for (final idiom in bank) idiom.id: idiom};
  if (byId[gifts[today]?.idiomId] case final given?) return given;

  // When each was last given.
  final last = <String, CalendarDate>{};
  for (final gift in gifts.values) {
    final seen = last[gift.idiomId];
    if (seen == null || seen.compareTo(gift.day) < 0) {
      last[gift.idiomId] = gift.day;
    }
  }
  for (final idiom in bank) {
    if (!last.containsKey(idiom.id)) return idiom;
  }
  return bank.reduce(
    (a, b) => last[b.id]!.compareTo(last[a.id]!) < 0 ? b : a,
  );
}

/// The day's expression opens once something was done that day: a
/// session finished, or a review round.
bool giftUnlocked({required bool practisedToday, required bool reviewedToday}) =>
    practisedToday || reviewedToday;
