import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';

/// Shown in place of content that could not be loaded: what happened, in
/// plain words, and the way to try again.
class LoadFailure extends StatelessWidget {
  const LoadFailure({
    super.key,
    required this.message,
    required this.onRetry,
    this.retrying = false,
  });

  final String message;
  final VoidCallback onRetry;

  /// Whether a retry is under way; the button waits for it to finish.
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Nothing you saved has been changed.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: retrying ? null : onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
