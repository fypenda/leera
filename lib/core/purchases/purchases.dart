import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The two ways to pay for Leera Plus.
enum PlusPlan { yearly, monthly }

/// A plan as the App Store sells it.
class PlusOffer {
  const PlusOffer({required this.plan, this.price, this.freeTrialDays});

  final PlusPlan plan;

  /// The price as the store formats it ("€39.99/year"), or null while the
  /// store has not said.
  final String? price;

  /// Days free before the first payment, or null without a trial.
  final int? freeTrialDays;
}

enum PurchaseFailure {
  /// The store cannot sell yet: no App Store products, or no store at all.
  unavailable,

  /// The App Store refused or failed the payment.
  failed,
}

class PurchaseException implements Exception {
  const PurchaseException(this.failure);

  final PurchaseFailure failure;

  @override
  String toString() => 'PurchaseException($failure)';
}

/// Buying Leera Plus. The backend learns of a purchase from the store
/// itself (a webhook), never from the app.
abstract interface class Purchases {
  /// The plans on sale, the best value first.
  Future<List<PlusOffer>> offers();

  /// Buys [plan]. True once bought, false if the person cancelled; throws a
  /// [PurchaseException] otherwise.
  Future<bool> buy(PlusPlan plan);

  /// Restores a subscription bought before, on this Apple ID. True if one
  /// was found.
  Future<bool> restore();
}

/// The store until RevenueCat is set up: the plans are shown, without
/// prices, and nothing can be bought.
class StoreNotReady implements Purchases {
  const StoreNotReady();

  @override
  Future<List<PlusOffer>> offers() async => const [
    PlusOffer(plan: PlusPlan.yearly, freeTrialDays: 7),
    PlusOffer(plan: PlusPlan.monthly),
  ];

  @override
  Future<bool> buy(PlusPlan plan) async =>
      throw const PurchaseException(PurchaseFailure.unavailable);

  @override
  Future<bool> restore() async =>
      throw const PurchaseException(PurchaseFailure.unavailable);
}

final purchasesProvider = Provider<Purchases>((ref) => const StoreNotReady());

final plusOffersProvider = FutureProvider<List<PlusOffer>>(
  (ref) => ref.watch(purchasesProvider).offers(),
  retry: (retryCount, error) => null,
);

/// What to tell the person when a purchase fails.
String describePurchaseFailure(PurchaseFailure failure) => switch (failure) {
  PurchaseFailure.unavailable =>
    'Leera Plus is not on sale yet. It opens with the App Store release.',
  PurchaseFailure.failed =>
    'The App Store could not complete it. Nothing was charged; try again.',
};
