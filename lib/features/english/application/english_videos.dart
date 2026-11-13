import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/settings/settings.dart';
import '../../../core/time/calendar_date.dart';
import '../data/video_lessons.dart';
import '../domain/kept_words.dart';

/// Opens a web address outside the app: YouTube, or the browser. Replaced
/// in tests.
final openExternalUrlProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Whether to load the talks' pictures from YouTube. Off in tests, which
/// have no network.
final showVideoThumbnailsProvider = Provider<bool>((ref) => true);

/// The talks whose five expressions were kept, by id, with the day.
Map<String, CalendarDate> parseVideoWords(String? stored) {
  final kept = <String, CalendarDate>{};
  for (final entry in (stored ?? '').split(',')) {
    final at = entry.indexOf('@');
    if (at <= 0) continue;
    try {
      kept[entry.substring(0, at)] = CalendarDate.parse(entry.substring(at + 1));
    } on FormatException {
      continue;
    } on ArgumentError {
      continue;
    }
  }
  return kept;
}

String encodeVideoWords(Map<String, CalendarDate> kept) => [
  for (final MapEntry(:key, :value) in kept.entries)
    '$key@${value.toIso8601()}',
].join(',');

/// The talks whose expressions were kept, by id.
final keptVideosProvider = Provider<Map<String, CalendarDate>>(
  (ref) => parseVideoWords(ref.watch(videoWordsSettingProvider).value),
);

/// The expressions kept from the talks, as words.
final keptVideoWordsProvider = Provider<List<KeptWord>>((ref) {
  final kept = ref.watch(keptVideosProvider);
  return [
    for (final MapEntry(key: id, value: day) in kept.entries)
      if (videoLessonById(id) case final lesson?)
        for (final item in lesson.expressions)
          KeptWord(
            item: item,
            sessionId: 'video:$id',
            keptAt: DateTime(day.year, day.month, day.day, 12),
            origin: "From ${lesson.speaker}'s talk",
          ),
  ];
});

final videoActionsProvider = Provider<VideoActions>(
  (ref) => VideoActions(ref.watch(settingsRepositoryProvider)),
);

class VideoActions {
  VideoActions(this._settings);

  final SettingsRepository _settings;

  /// The five expressions of the talk [id] are kept from [day], or no
  /// longer.
  Future<void> keep(String id, {required bool kept, required CalendarDate day}) async {
    final stored = parseVideoWords(
      await _settings.watch(SettingKeys.videoWords).first,
    );
    if (kept) {
      stored.putIfAbsent(id, () => day);
    } else {
      stored.remove(id);
    }
    await _settings.write(SettingKeys.videoWords, encodeVideoWords(stored));
  }
}
