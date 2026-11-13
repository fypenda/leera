import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/today.dart';
import '../data/idiom_bank.dart';
import '../domain/idiom.dart';
import '../domain/kept_words.dart';
import '../domain/session_feedback.dart';

/// The expressions of the day opened so far, by day. Null until read.
final idiomGiftsProvider = Provider<Map<CalendarDate, IdiomGift>?>((ref) {
  final stored = ref.watch(idiomGiftsSettingProvider);
  return stored.hasValue ? parseGifts(stored.value) : null;
});

/// Today's expression: the one opened today, or the next to give.
final idiomOfTheDayProvider = Provider.autoDispose<Idiom>(
  (ref) => idiomOfTheDay(
    idiomBank,
    ref.watch(idiomGiftsProvider) ?? const {},
    ref.watch(todayProvider),
  ),
);

/// An expression of the day by its id, if it is still in the bank.
Idiom? idiomById(String id) {
  for (final idiom in idiomBank) {
    if (idiom.id == id) return idiom;
  }
  return null;
}

/// The expressions of the day kept to review, as words.
final keptIdiomsProvider = Provider<List<KeptWord>>((ref) {
  final gifts = ref.watch(idiomGiftsProvider) ?? const {};
  return [
    for (final gift in gifts.values)
      if (gift.kept)
        if (idiomById(gift.idiomId) case final idiom?)
          KeptWord(
            item: VocabularyItem(
              idiom.expression,
              idiom.meaning,
              idiom.example,
            ),
            sessionId: 'idiom:${idiom.id}',
            // The day it was given, at noon: it sorts among that day's
            // corrections.
            keptAt: DateTime(gift.day.year, gift.day.month, gift.day.day, 12),
            ofTheDay: true,
            origin: 'Expression of the day',
          ),
  ];
});

final idiomActionsProvider = Provider<IdiomActions>(
  (ref) => IdiomActions(ref.watch(settingsRepositoryProvider)),
);

/// Opening the day's gift, and keeping its expression or not.
class IdiomActions {
  IdiomActions(this._settings);

  final SettingsRepository _settings;

  Future<Map<CalendarDate, IdiomGift>> _gifts() async =>
      parseGifts(await _settings.watch(SettingKeys.idiomGifts).first);

  /// [idiom] is opened on [day]; a day already opened keeps its own.
  Future<void> open(CalendarDate day, Idiom idiom) async {
    final gifts = await _gifts();
    if (gifts.containsKey(day)) return;
    gifts[day] = IdiomGift(day: day, idiomId: idiom.id);
    await _settings.write(SettingKeys.idiomGifts, encodeGifts(gifts.values));
  }

  /// The expression given on [day] is kept to review, or not.
  Future<void> keep(CalendarDate day, {required bool kept}) async {
    final gifts = await _gifts();
    final gift = gifts[day];
    if (gift == null || gift.kept == kept) return;
    gifts[day] = gift.withKept(kept);
    await _settings.write(SettingKeys.idiomGifts, encodeGifts(gifts.values));
  }
}
