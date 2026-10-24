import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ai/backend_client.dart';
import '../../core/auth/auth_actions.dart';
import '../../core/auth/quota.dart';
import '../../core/auth/session.dart';
import '../../core/common/widgets/load_failure.dart';
import '../../core/time/date_formatting.dart';
import '../../features/english/english_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The account: the plan and what is left of the quota, signing out, and
/// deleting the account.
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  var _busy = false;

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(englishRouteName);
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authActionsProvider).signOut();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'Leera forgets your account and the count of your corrections. '
          'Your sessions and corrections stay on this iPhone. This cannot '
          'be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirm-delete-account'),
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coralStrong),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(authActionsProvider).deleteAccount();
    } on BackendException catch (e) {
      debugPrint('Deleting the account failed: $e');
      if (mounted) _say(describeBackendFailure(e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quota = ref.watch(quotaProvider);

    final Widget plan = switch (quota) {
      AsyncData(value: final status) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            switch (status.plan) {
              Plan.plus => 'Leera Plus ✨',
              Plan.dev => 'Developer account 🛠️',
              Plan.free => 'Free plan',
            },
            key: const ValueKey('account-plan'),
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            describeQuota(status),
            key: const ValueKey('account-quota'),
            style: textTheme.titleMedium,
          ),
          if (status.plan == Plan.dev) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${status.used} this week. No limit while the backend lets '
              'developers sign in without Apple.',
              style: textTheme.bodyMedium,
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: status.limit == 0 ? 1 : status.used / status.limit,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Starts again on ${formatLongDate(status.resetsAt.toLocal())}.',
              style: textTheme.bodyMedium,
            ),
            if (status.plan == Plan.free) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                key: const ValueKey('open-plus'),
                onPressed: () => context.pushNamed(plusRouteName),
                child: const Text('Get Leera Plus: 3 corrections a day'),
              ),
            ],
          ],
        ],
      ),
      AsyncError() => LoadFailure(
        message: 'Your plan could not be loaded.',
        onRetry: () => ref.invalidate(quotaProvider),
      ),
      _ => const LinearProgressIndicator(),
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const ValueKey('account-leave'),
                      onPressed: _leave,
                      child: const Text('← Back'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Your account', style: textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Signed in with Apple. Leera keeps no name and no email: '
                    'only your plan and when you asked for corrections.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: plan,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      OutlinedButton(
                        key: const ValueKey('sign-out'),
                        onPressed: _busy ? null : _signOut,
                        child: const Text('Sign out'),
                      ),
                      TextButton(
                        key: const ValueKey('delete-account'),
                        onPressed: _busy ? null : _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.coralStrong,
                        ),
                        child: const Text('Delete my account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
