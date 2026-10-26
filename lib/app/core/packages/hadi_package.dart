import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../subscription/subscription_service.dart';

/// Which package a person is on, for the hosted-AI allowance in Hādi.
///
/// TODO-OWNER: the three names below are placeholders that mirror the tier
/// ids already in assets/system/subscription.json ('free', 'plus', 'family').
/// Rename the labels in [kHadiPackageLabels] once the owner picks the names.
/// Nothing here charges anyone: billing is a separate, closed seam
/// (billing_gateway.dart).
enum HadiPackage { free, plus, family }

/// TODO-OWNER: display names for the packages (placeholders).
const Map<HadiPackage, String> kHadiPackageLabels = <HadiPackage, String>{
  HadiPackage.free: 'Free',
  HadiPackage.plus: 'Plus',
  HadiPackage.family: 'Family',
};

/// What one package allows. A null limit means UNLIMITED.
///
/// OWNER DECISION (Oct 2026): nothing is capped yet. Every package is
/// unlimited and no limit is shown anywhere. The fields exist so caps can be
/// switched on later by changing this one table (and the server proxy), with
/// no other code change.
/// TODO-OWNER: set real limits when caps are switched on.
class HadiPackageLimits {
  const HadiPackageLimits({
    this.hostedPerDay,
    this.hostedPerMonth,
    this.maxReplyChars = 900,
    this.features = const <String>{},
  });

  /// Hosted-AI messages allowed per local calendar day (null = unlimited).
  final int? hostedPerDay;

  /// Hosted-AI messages allowed per local calendar month (null = unlimited).
  final int? hostedPerMonth;

  /// A hosted reply longer than this is shortened at a sentence end.
  final int maxReplyChars;

  /// Feature flags for the package. Hādi's built-in library, the core
  /// religious answers and every crisis or safety reply are NEVER gated by a
  /// package and are not listed here.
  final Set<String> features;
}

/// The single table of limits. All unlimited by default (see above).
const Map<HadiPackage, HadiPackageLimits> kHadiPackageLimits =
    <HadiPackage, HadiPackageLimits>{
  HadiPackage.free: HadiPackageLimits(),
  HadiPackage.plus: HadiPackageLimits(),
  HadiPackage.family: HadiPackageLimits(),
};

/// Feature flags for the package. Hādi's built-in library, the core
  /// religious answers and every crisis or safety reply are NEVER gated by a
  /// package and are not listed here.
  final Set<String> features;
}

/// The single table of limits. Day/month values for plus and family start
/// from the daily quotas already in assets/system/subscription.json; the free
/// row and every monthly figure are placeholders.
/// TODO-OWNER: replace all placeholder values.
const Map<HadiPackage, HadiPackageLimits> kHadiPackageLimits =
    <HadiPackage, HadiPackageLimits>{
  HadiPackage.free: HadiPackageLimits(
    hostedPerDay: 3,
    hostedPerMonth: 30,
    maxReplyChars: 600,
  ),
  HadiPackage.plus: HadiPackageLimits(
    hostedPerDay: 30,
    hostedPerMonth: 600,
    maxReplyChars: 900,
    features: <String>{kFeatureLongerReplies},
  ),
  HadiPackage.family: HadiPackageLimits(
    hostedPerDay: 100,
    hostedPerMonth: 2000,
    maxReplyChars: 900,
    features: <String>{kFeatureLongerReplies},
  ),
};

/// Feature flag: longer hosted replies (placeholder example of a feature).
const String kFeatureLongerReplies = 'longer-replies';

/// Maps a stored tier id to a package; anything unknown is [HadiPackage.free].
HadiPackage packageFromTier(String tier) {
  for (final HadiPackage p in HadiPackage.values) {
    if (p.name == tier) return p;
  }
  return HadiPackage.free;
}

/// The package in force right now. An expired or never-activated paid tier
/// counts as free (SubscriptionService.isEntitled decides).
final Provider<HadiPackage> hadiPackageProvider = Provider<HadiPackage>((ref) {
  final String tier = ref.watch(subscriptionServiceProvider);
  final SubscriptionService sub =
      ref.watch(subscriptionServiceProvider.notifier);
  if (tier == 'free' || !sub.isEntitled) return HadiPackage.free;
  return packageFromTier(tier);
});
