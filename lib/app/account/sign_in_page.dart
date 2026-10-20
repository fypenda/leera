import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/backend_client.dart';
import '../../core/auth/auth_actions.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// The first page: the logo, what Leera does, and Sign in with Apple.
///
/// Once signed in, the router takes the person to the home page.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  var _busy = false;
  String? _error;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authActionsProvider).signInWithApple();
    } on BackendException catch (e) {
      debugPrint('Sign in failed: $e');
      if (mounted) setState(() => _error = describeBackendFailure(e.failure));
    } on Object catch (e) {
      debugPrint('Sign in failed: $e');
      if (mounted) {
        setState(
          () => _error = 'Sign in with Apple did not work. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Debug builds only: signs in without Apple, against a backend started
  /// with `LEERA_DEV_SIGN_IN=true`.
  Future<void> _devSignIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authActionsProvider).devSignIn();
    } on BackendException catch (e) {
      debugPrint('Developer sign-in failed: $e');
      if (mounted) {
        setState(
          () => _error = e.failure == BackendFailure.unreachable
              ? describeBackendFailure(e.failure)
              : 'Developer sign-in is off on this backend. Start it with '
                    'LEERA_DEV_SIGN_IN=true.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // The two soft circles of the launch screen.
          const Positioned(
            left: -90,
            top: -90,
            child: _Blob(size: 260, color: AppColors.accentSoft),
          ),
          const Positioned(
            right: -110,
            bottom: -70,
            child: _Blob(size: 300, color: AppColors.primarySoft),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/brand/logo.png',
                        width: 120,
                        height: 120,
                        semanticLabel: 'Leera logo',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'leera',
                        style: TextStyle(
                          fontFamily: displayFontFamily,
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          height: 1,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your English, elevated.',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'A random topic. You research it, you explain it, '
                        'then Leera corrects you.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          key: const ValueKey('sign-in-apple'),
                          onPressed: _busy ? null : _signIn,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.apple, size: 22),
                          label: Text(
                            _busy ? 'Signing in…' : 'Continue with Apple',
                          ),
                        ),
                      ),
                      if (_error case final error?) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          error,
                          key: const ValueKey('sign-in-error'),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.coralStrong,
                          ),
                        ),
                      ],
                      if (kDebugMode) ...[
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          key: const ValueKey('sign-in-dev'),
                          onPressed: _busy ? null : _devSignIn,
                          child: const Text('Developer sign-in (debug only)'),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Your presentations stay on this iPhone. Leera keeps '
                        'only an anonymous account, to count your '
                        'corrections: no name, no email.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
