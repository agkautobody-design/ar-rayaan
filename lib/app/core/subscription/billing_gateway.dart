import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'subscription_service.dart';

/// The billing seam. The app speaks only this interface; the concrete
/// adapter (Stripe, RevenueCat, Google Play / App Store via RevenueCat)
/// is chosen by the founder and plugged in behind billingGatewayProvider
/// without touching Hadi, Wasia, or the key sheet.
///
/// Contract with SubscriptionService: a successful result carries a
/// per-user MANAGED key issued by the founder's server (never a founder
/// key shipped in the app) plus its expiry. The gateway never writes
/// prefs directly — it returns a result, the caller activates it.
abstract class BillingGateway {
  String get name;

  /// Restore an existing entitlement (app reinstall, new device, launch).
  Future<BillingResult> restore();

  /// Start a purchase for a tier id from assets/system/subscription.json
  /// ('plus' | 'family').
  Future<BillingResult> purchase(String tier);
}

class BillingResult {
  const BillingResult._({
    required this.success,
    this.tier,
    this.managedKey,
    this.expires,
    this.error,
  });

  factory BillingResult.ok({
    required String tier,
    required String managedKey,
    required DateTime expires,
  }) =>
      BillingResult._(
        success: true,
        tier: tier,
        managedKey: managedKey,
        expires: expires,
      );

  factory BillingResult.failed(String error) =>
      BillingResult._(success: false, error: error);

  final bool success;
  final String? tier;
  final String? managedKey;
  final DateTime? expires;
  final String? error;
}

/// Development gateway: grants a 24-hour Plus entitlement locally so the
/// whole subscription loop (activate → managed key → quota → live AI) can
/// be exercised without a server. NOT for production — replacing this
/// provider with the real adapter is the founder's billing decision.
class SandboxBillingGateway implements BillingGateway {
  const SandboxBillingGateway();

  @override
  String get name => 'sandbox';

  @override
  Future<BillingResult> restore() => _grant();

  @override
  Future<BillingResult> purchase(String tier) => _grant();

  Future<BillingResult> _grant() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Release builds must never hand out a fake entitlement: the sandbox
    // key is not a real AI key, so "active" would be a false promise.
    if (kReleaseMode) {
      return BillingResult.failed(
        'Subscriptions are not open yet. Hādi already works offline, and '
        'with your own free key for live answers.',
      );
    }
    return BillingResult.ok(
      tier: 'plus',
      managedKey: 'sandbox-${DateTime.now().millisecondsSinceEpoch}',
      expires: DateTime.now().add(const Duration(hours: 24)),
    );
  }
}

/// The single place the adapter choice lives. Swap the return value for
/// StripeBillingGateway / RevenueCatBillingGateway when billing launches.
final billingGatewayProvider = Provider<BillingGateway>(
  (ref) => const SandboxBillingGateway(),
);

/// Shared activate path — every surface that grants an entitlement goes
/// through here so keys, expiry, and state stay consistent.
Future<String?> activateBillingResult(
  SubscriptionService subscription,
  BillingResult result,
) async {
  if (!result.success ||
      result.tier == null ||
      result.managedKey == null ||
      result.expires == null) {
    return result.error ?? 'The purchase could not be completed.';
  }
  await subscription.activate(
      result.tier!, result.managedKey!, result.expires!);
  return null;
}
