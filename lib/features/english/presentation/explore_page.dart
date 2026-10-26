import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/session.dart';
import '../application/english_sessions.dart';
import '../application/english_themes.dart';
import '../data/preference_repository_providers.dart';
import '../data/topic_catalog.dart';
import '../english_routes.dart';
import 'session_chrome.dart';
import 'theme_style.dart';

/// The Explore tab: the themes of the topics, each opening its topics to
/// choose one, and the themes the daily topic is drawn from.
class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = ref.watch(catalogThemesProvider);
    final done = {
      for (final session
          in ref.watch(practiceStatsProvider).value?.completed ?? const [])
        session.topicId,
    };
    // How many topics of each theme have been done.
    final doneByTheme = <String, int>{};
    for (final topic in topicCatalog) {
      if (!done.contains(topic.id)) continue;
      for (final theme in topic.themes) {
        doneByTheme[theme] = (doneByTheme[theme] ?? 0) + 1;
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: SingleChildScrollView(
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
                    'Explore',
                    style: TextStyle(
                      fontFamily: displayFontFamily,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.7,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Pick a topic yourself, or choose the themes your daily '
                    'topic is drawn from.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg + 2),
                  const _DailyThemesCard(),
                  const SizedBox(height: AppSpacing.xl - 4),
                  const Text(
                    'Themes',
                    style: TextStyle(
                      fontFamily: displayFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Two columns of tiles, as many rows as needed.
                  for (var row = 0; row < themes.length; row += 2) ...[
                    if (row > 0) const SizedBox(height: AppSpacing.md),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var column = 0; column < 2; column++) ...[
                            if (column > 0) const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: row + column < themes.length
                                  ? _ThemeTile(
                                      theme: themes[row + column].$1,
                                      topics: themes[row + column].$2,
                                      done:
                                          doneByTheme[themes[row + column].$1] ??
                                          0,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.topics,
    required this.done,
  });

  final String theme;
  final int topics;
  final int done;

  @override
  Widget build(BuildContext context) {
    final style = themeStyle(theme);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: ValueKey('theme-$theme'),
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.goNamed(
          exploreThemeRouteName,
          pathParameters: {exploreThemeParameter: theme},
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(style.icon, size: 20, color: style.foreground),
              ),
              const SizedBox(height: AppSpacing.md - 2),
              Text(
                theme,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  topics == 1 ? '1 topic' : '$topics topics',
                  if (done > 0) '$done done',
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The themes the daily topic is drawn from, and the way to choose them:
/// a Leera Plus feature.
class _DailyThemesCard extends ConsumerWidget {
  const _DailyThemesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(canChooseThemesProvider);
    final chosen = ref.watch(dailyThemesProvider);

    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: const ValueKey('daily-themes'),
        borderRadius: BorderRadius.circular(24),
        onTap: allowed
            ? () => showModalBottomSheet<void>(
                context: context,
                // Above the tab bar, not under it.
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: AppColors.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                builder: (context) => _ThemePicker(chosen: chosen),
              )
            : () => context.pushNamed(plusRouteName),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.casino_outlined,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your daily topic',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !allowed
                          ? 'Choose its themes with Leera Plus'
                          : chosen.isEmpty
                          ? 'Drawn from every theme'
                          : 'Drawn from ${(chosen.toList()..sort()).join(', ')}',
                      key: const ValueKey('daily-themes-chosen'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD5DCE0),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                allowed ? Icons.tune_rounded : Icons.lock_outline_rounded,
                color: AppColors.background,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chooses the themes of the daily topic. None chosen: every theme.
class _ThemePicker extends ConsumerStatefulWidget {
  const _ThemePicker({required this.chosen});

  final Set<String> chosen;

  @override
  ConsumerState<_ThemePicker> createState() => _ThemePickerState();
}

class _ThemePickerState extends ConsumerState<_ThemePicker> {
  late final _chosen = {...widget.chosen};
  var _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(themePreferenceRepositoryProvider).setThemes(_chosen);
      navigator.pop();
    } on Object catch (e) {
      debugPrint('Saving the themes failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Your themes could not be saved.')),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = ref.watch(catalogThemesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Themes of your daily topic',
              style: TextStyle(
                fontFamily: displayFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _chosen.isEmpty
                  ? 'None chosen: every theme can come up.'
                  : 'Only topics in these themes will come up.',
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (theme, _) in themes)
                  FilterChip(
                    key: ValueKey('pick-$theme'),
                    label: Text(theme),
                    avatar: Icon(themeStyle(theme).icon, size: 18),
                    selected: _chosen.contains(theme),
                    showCheckmark: false,
                    selectedColor: AppColors.primarySoft,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: _chosen.contains(theme)
                          ? AppColors.primary
                          : AppColors.surfaceMuted,
                    ),
                    shape: const StadiumBorder(),
                    onSelected: (on) => setState(
                      () => on ? _chosen.add(theme) : _chosen.remove(theme),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            BottomActionButton(
              buttonKey: const ValueKey('save-themes'),
              label: 'Save',
              icon: Icons.check_rounded,
              onTap: _saving ? null : _save,
            ),
            if (_chosen.isNotEmpty)
              TextButton(
                key: const ValueKey('clear-themes'),
                onPressed: () => setState(_chosen.clear),
                child: const Text('Every theme'),
              ),
          ],
        ),
      ),
    );
  }
}
