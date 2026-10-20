import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../time/today.dart';
import '../../time/date_formatting.dart';

/// The frame of a top-level page: section label and date, a large title with
/// an optional badge beside it and an optional subtitle, then the page
/// content.
///
/// It brings its own [Scaffold]: the page's background and default text
/// style come from it. (In NOURISH the app shell provided it; without one,
/// the page is black and its text underlined in yellow.)
class PageScaffold extends ConsumerWidget {
  const PageScaffold({
    super.key,
    required this.section,
    this.parent,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  /// Below this width the page uses tighter side margins.
  static const double _compactWidth = 600;

  final String section;

  /// The page this one was opened from, shown before [section] as a link
  /// back to it. Null for a top-level page.
  final ({String label, VoidCallback onTap})? parent;
  final String title;
  final String? subtitle;

  /// Shown at the end of the title's line, such as a badge.
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final today = formatCalendarDate(ref.watch(todayProvider), weekday: true);
    final compact = MediaQuery.sizeOf(context).width < _compactWidth;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.lg + 4 : AppSpacing.xxl - 4,
              vertical: compact ? AppSpacing.xl : AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (parent case final parent?) ...[
                      InkWell(
                        key: const ValueKey('breadcrumb-parent'),
                        onTap: parent.onTap,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: Text(
                          parent.label,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Text('  /  ', style: textTheme.bodySmall),
                    ],
                    // Both shorten rather than overflow on a narrow screen or
                    // with large text.
                    Expanded(
                      child: Text(
                        section,
                        style: textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        today,
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title, style: textTheme.displaySmall),
                    ?trailing,
                  ],
                ),
                if (subtitle case final subtitle?) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle, style: textTheme.bodyLarge),
                ],
                const SizedBox(height: AppSpacing.xl + 2),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
