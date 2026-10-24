import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/common/widgets/load_failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_formatting.dart';
import '../../../core/time/today.dart';
import '../application/english_feedback.dart';
import '../application/english_sessions.dart';
import '../data/topic_catalog.dart';
import '../domain/kept_words.dart';
import '../domain/practice_session.dart';
import 'english_page.dart';
import 'session_navigation.dart';

/// The Journal tab: every word kept from the corrections, searchable, and
/// every finished session, month by month. Each opens its correction.
class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

enum _Section { words, sessions }

class _JournalPageState extends ConsumerState<JournalPage> {
  var _section = _Section.words;
  final _search = TextEditingController();

  static const double _maxWidth = 560;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(practiceStatsProvider);
    final feedbacks = ref.watch(feedbacksProvider);
    final today = ref.watch(todayProvider);

    final Widget body = switch ((stats, feedbacks)) {
      (AsyncData(value: final stats), AsyncData(value: final feedbacks)) => () {
        final sessions = {
          for (final session in stats.completed) session.id: session,
        };
        final words = keptWords(feedbacks);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionSwitch(
              section: _section,
              words: words.length,
              sessions: stats.completed.length,
              onChanged: (section) => setState(() => _section = section),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_section == _Section.words)
              _Words(
                words: words,
                sessions: sessions,
                query: _search,
                today: today,
              )
            else
              _Sessions(
                sessions: stats.completed,
                scores: {
                  for (final MapEntry(:key, :value) in feedbacks.entries)
                    key: value.scores.average,
                },
                today: today,
              ),
          ],
        );
      }(),
      (AsyncError(), _) || (_, AsyncError()) => LoadFailure(
        message: 'Your journal could not be loaded.',
        onRetry: () => ref
          ..invalidate(practiceSessionsProvider)
          ..invalidate(feedbacksProvider),
      ),
      _ => const SizedBox.shrink(),
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Journal',
                    style: TextStyle(
                      fontFamily: displayFontFamily,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.7,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg + 2),
                  body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Words or sessions, as two pills on a white track.
class _SectionSwitch extends StatelessWidget {
  const _SectionSwitch({
    required this.section,
    required this.words,
    required this.sessions,
    required this.onChanged,
  });

  final _Section section;
  final int words;
  final int sessions;
  final ValueChanged<_Section> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        for (final (value, label, count) in [
          (_Section.words, 'Words', words),
          (_Section.sessions, 'Sessions', sessions),
        ])
          Expanded(
            child: Semantics(
              button: true,
              selected: value == section,
              child: Material(
                color: value == section ? AppColors.ink : Colors.transparent,
                shape: const StadiumBorder(),
                child: InkWell(
                  key: ValueKey('journal-${value.name}'),
                  customBorder: const StadiumBorder(),
                  onTap: () => onChanged(value),
                  child: Center(
                    child: Text(
                      '$label · $count',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: value == section
                            ? AppColors.surface
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Words extends StatelessWidget {
  const _Words({
    required this.words,
    required this.sessions,
    required this.query,
    required this.today,
  });

  final List<KeptWord> words;

  /// The finished sessions by id, to name and open where a word came from.
  final Map<String, PracticeSession> sessions;
  final TextEditingController query;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const _Empty(
        key: ValueKey('journal-no-words'),
        icon: Icons.bookmark_border_rounded,
        text: 'The words to keep from your corrections will gather here.',
      );
    }
    final found = searchWords(words, query.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('journal-search'),
          controller: query,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Search your words',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: query.clear,
                  ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (found.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'No word matches “${query.text.trim()}”.',
              key: const ValueKey('journal-no-match'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        for (final word in found) ...[
          if (sessions[word.sessionId] case final session)
            _WordCard(
              word: word,
              topic: session == null ? null : topicById(session.topicId).title,
              today: today,
              onTap: session == null
                  ? null
                  : () => openSession(context, session),
            ),
          const SizedBox(height: AppSpacing.sm + 2),
        ],
      ],
    );
  }
}

/// A kept word: the expression, its meaning and example, and where it
/// came from.
class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.topic,
    required this.today,
    required this.onTap,
  });

  final KeptWord word;

  /// The title of the topic it came from, if its session is still there.
  final String? topic;
  final CalendarDate today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = word.item;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      key: ValueKey('word-${word.key}'),
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.expression,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  color: AppColors.accentStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.meaning,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.text),
              ),
              if (item.example.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '“${item.example}”',
                  style: textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                [
                  ?topic,
                  formatRelativeDay(CalendarDate.ofLocal(word.keptAt), today),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every finished session, the latest first, under the month it was done.
class _Sessions extends StatelessWidget {
  const _Sessions({
    required this.sessions,
    required this.scores,
    required this.today,
  });

  final List<PracticeSession> sessions;
  final Map<String, double> scores;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _Empty(
        key: ValueKey('journal-no-sessions'),
        icon: Icons.history_rounded,
        text: 'Your finished sessions will gather here.',
      );
    }

    // Sessions come latest first: consecutive ones share their month.
    final months = <(String, List<PracticeSession>)>[];
    for (final session in sessions) {
      final month = _monthOf(session);
      if (months.isEmpty || months.last.$1 != month) {
        months.add((month, []));
      }
      months.last.$2.add(session);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, (month, inMonth)) in months.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              month,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ),
          for (final session in inMonth) ...[
            PracticeSessionTile(
              session: session,
              today: today,
              score: scores[session.id],
              onOpen: () => openSession(context, session),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
          ],
        ],
      ],
    );
  }

  /// "OCTOBER 2026".
  static String _monthOf(PracticeSession session) {
    final day = CalendarDate.ofLocal(session.completedAt!);
    final date = formatCalendarDate(day);
    return '${date.split(' ').first} ${day.year}'.toUpperCase();
  }
}

class _Empty extends StatelessWidget {
  const _Empty({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Icon(icon, size: 28, color: AppColors.textMuted),
        const SizedBox(height: AppSpacing.sm),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ],
    ),
  );
}
