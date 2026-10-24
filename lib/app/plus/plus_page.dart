import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_actions.dart';
import '../../core/purchases/purchases.dart';
import '../../features/english/english_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Leera Plus" in the Leera design: what Plus adds, the two plans, and
/// the button to subscribe.
class PlusPage extends ConsumerStatefulWidget {
  const PlusPage({super.key});

  @override
  ConsumerState<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends ConsumerState<PlusPage> {
  var _plan = PlusPlan.yearly;
  var _busy = false;

  static const double _maxWidth = 560;

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

  /// Runs a store action, then leaves once Plus is there.
  Future<void> _run(Future<bool> Function() action, String ifNothing) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (await action()) {
        ref.invalidate(quotaProvider);
        if (mounted) _leave();
      } else if (ifNothing.isNotEmpty && mounted) {
        _say(ifNothing);
      }
    } on PurchaseException catch (e) {
      debugPrint('Leera Plus: $e');
      if (mounted) _say(describePurchaseFailure(e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(purchasesProvider);
    final offers = ref.watch(plusOffersProvider).value ?? const [];
    final chosen = offers.where((offer) => offer.plan == _plan).firstOrNull;
    final trial = chosen?.freeTrialDays;

    return Scaffold(
      body: Stack(
        children: [
          // The teal band and the peach sun behind the top of the page.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 300,
            child: Container(color: AppColors.highlight),
          ),
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Semantics(
                                  button: true,
                                  label: 'Close',
                                  excludeSemantics: true,
                                  child: Material(
                                    color: AppColors.surface,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      key: const ValueKey('plus-close'),
                                      customBorder: const CircleBorder(),
                                      onTap: _leave,
                                      child: const SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  key: const ValueKey('plus-restore'),
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                          purchases.restore,
                                          'No Leera Plus found on this Apple ID.',
                                        ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: const Text('Restore'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/brand/logo.png',
                                  width: 56,
                                  height: 56,
                                  semanticLabel: 'Leera logo',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Leera Plus',
                              style: TextStyle(
                                fontFamily: displayFontFamily,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: -0.7,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Fluency through real topics, without waiting a '
                              'week.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _Perks(),
                            const SizedBox(height: 18),
                            Semantics(
                              label: 'Choose a plan',
                              child: Column(
                                children: [
                                  for (final offer in offers) ...[
                                    _PlanOption(
                                      offer: offer,
                                      selected: offer.plan == _plan,
                                      onTap: () =>
                                          setState(() => _plan = offer.plan),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 58,
                            width: double.infinity,
                            child: FilledButton(
                              key: const ValueKey('plus-subscribe'),
                              onPressed: _busy || chosen == null
                                  ? null
                                  : () => _run(() => purchases.buy(_plan), ''),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.ink,
                                foregroundColor: AppColors.surface,
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: Text(
                                trial == 7
                                    ? 'Start my free week'
                                    : trial != null
                                    ? 'Start my $trial free days'
                                    : 'Subscribe',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Cancel anytime in Settings · Terms · Privacy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What Plus adds. Only what the app does today: features still to come
/// are marked as such.
class _Perks extends StatelessWidget {
  const _Perks();

  static const _perks = [
    (
      icon: Icons.auto_awesome_rounded,
      background: AppColors.coralSoft,
      foreground: AppColors.coralStrong,
      title: 'Three corrections a day',
      detail: 'Instead of one a week on the free plan',
      soon: false,
    ),
    (
      icon: Icons.mic_none_rounded,
      background: AppColors.primarySoft,
      foreground: AppColors.primary,
      title: 'Speak or write, every day',
      detail: 'Every mistake explained, with words to keep',
      soon: false,
    ),
    (
      icon: Icons.layers_outlined,
      background: AppColors.accentSoft,
      foreground: AppColors.accentStrong,
      title: 'Pick your themes',
      detail: 'Science, history, culture, business…',
      soon: true,
    ),
    (
      icon: Icons.bookmark_border_rounded,
      background: AppColors.primarySoft,
      foreground: AppColors.primary,
      title: 'Vocabulary review',
      detail: 'Spaced repetition of your saved words',
      soon: true,
    ),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        for (final (index, perk) in _perks.indexed) ...[
          if (index > 0) const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: perk.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(perk.icon, size: 18, color: perk.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perk.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      perk.detail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (perk.soon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final PlusOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final yearly = offer.plan == PlusPlan.yearly;
    final trial = offer.freeTrialDays;
    final details = [
      offer.price ?? 'Price set on the App Store',
      if (trial != null) '$trial-day free trial',
    ].join(' · ');

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? AppColors.ink : AppColors.surfaceMuted,
            width: selected ? 2.5 : 2,
          ),
        ),
        child: InkWell(
          key: ValueKey('plus-plan-${offer.plan.name}'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 22,
                  color: selected ? AppColors.ink : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        yearly ? 'Yearly' : 'Monthly',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        details,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (yearly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      'Best value',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
