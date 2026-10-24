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
import '../../features/english/presentation/session_chrome.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

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
    final quota = ref.watch(quotaProvider);

    final Widget plan = switch (quota) {
      AsyncData(value: final status) => _PlanCard(
        quota: status,
        onOpenPlus: () => context.pushNamed(plusRouteName),
      ),
      AsyncError() => _Card(
        child: LoadFailure(
          message: 'Your plan could not be loaded.',
          onRetry: () => ref.invalidate(quotaProvider),
        ),
      ),
      _ => const _Card(child: LinearProgressIndicator()),
    };

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RoundIconButton(
                      key: const ValueKey('account-leave'),
                      icon: Icons.chevron_left_rounded,
                      label: 'Back',
                      onTap: _leave,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Account',
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
                  plan,
                  const SizedBox(height: AppSpacing.lg + 2),
                  const _Card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IconTile(
                          icon: Icons.lock_outline_rounded,
                          background: AppColors.primarySoft,
                          foreground: AppColors.primary,
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Signed in with Apple',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Leera keeps no name and no email: only your '
                                'plan and when you asked for corrections. '
                                'Your sessions stay on this iPhone.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg + 2),
                  _Card(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _ActionRow(
                          key: const ValueKey('sign-out'),
                          icon: Icons.logout_rounded,
                          label: 'Sign out',
                          color: AppColors.ink,
                          onTap: _busy ? null : _signOut,
                        ),
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.surfaceMuted,
                        ),
                        _ActionRow(
                          key: const ValueKey('delete-account'),
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete my account',
                          color: AppColors.coralStrong,
                          onTap: _busy ? null : _delete,
                        ),
                      ],
                    ),
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

/// The plan, what is left of the quota, and the way to Leera Plus.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.quota, required this.onOpenPlus});

  final Quota quota;
  final VoidCallback onOpenPlus;

  @override
  Widget build(BuildContext context) {
    final plan = quota.plan;
    final (icon, background, foreground) = switch (plan) {
      Plan.plus => (
        Icons.auto_awesome_rounded,
        AppColors.accentSoft,
        AppColors.accentStrong,
      ),
      Plan.dev => (
        Icons.build_outlined,
        AppColors.surfaceMuted,
        AppColors.ink,
      ),
      Plan.free => (
        Icons.person_outline_rounded,
        AppColors.primarySoft,
        AppColors.primary,
      ),
    };

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconTile(
                icon: icon,
                background: background,
                foreground: foreground,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (plan) {
                        Plan.plus => 'Leera Plus',
                        Plan.dev => 'Developer account',
                        Plan.free => 'Free plan',
                      },
                      key: const ValueKey('account-plan'),
                      style: const TextStyle(
                        fontFamily: displayFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      describeQuota(quota),
                      key: const ValueKey('account-quota'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (plan == Plan.dev)
            Text(
              '${quota.used} this week. No limit while the backend lets '
              'developers sign in without Apple.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: quota.limit == 0
                    ? 1
                    : (quota.used / quota.limit).clamp(0.0, 1.0),
                minHeight: 6,
                color: quota.remaining == 0
                    ? AppColors.coral
                    : AppColors.highlight,
                backgroundColor: AppColors.surfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Starts again on ${formatLongDate(quota.resetsAt.toLocal())}.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
          // A developer account never meets the paywall: it can preview it.
          if (plan != Plan.plus) ...[
            const SizedBox(height: AppSpacing.lg),
            BottomActionButton(
              buttonKey: const ValueKey('open-plus'),
              label: plan == Plan.dev
                  ? 'Preview Leera Plus'
                  : 'Get Leera Plus: 3 corrections a day',
              icon: Icons.auto_awesome_rounded,
              onTap: onOpenPlus,
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, size: 20, color: foreground),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    ),
  );
}
