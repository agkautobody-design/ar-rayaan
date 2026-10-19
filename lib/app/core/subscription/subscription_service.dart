import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';

/// Subscription entitlement — tiers ship with the app, billing plugs in
/// later. A paid tier's live AI travels as a per-user MANAGED key issued
/// by the founder's server (assets/system/subscription.json's endpoint);
/// a founder key must never ship inside the app itself.
///
/// Keys the app owns today:
///   ar.sub.tier        — 'free' | 'plus' | 'family'
///   ar.sub.managedKey  — per-user key from the managed endpoint
///   ar.sub.expires     — epoch millis; entitlement ends after this
///   ar.sub.askedToday  — daily live-AI counter (quota per tier)
class SubscriptionService extends Notifier<String> {
  static const tierPref = 'ar.sub.tier';
  static const keyPref = 'ar.sub.managedKey';
  static const expiresPref = 'ar.sub.expires';
  static const askedTodayPref = 'ar.sub.askedToday';
  static const askedDayPref = 'ar.sub.askedDay';

  /// Daily live-AI quota per tier (mirrors assets/system/subscription.json).
  static const quota = <String, int>{'free': 0, 'plus': 30, 'family': 100};

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(tierPref) ?? 'free';
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  bool get isEntitled {
    if (state == 'free') return false;
    final int? expires = _prefs.getInt(expiresPref);
    if (expires == null) return false; // no expiry recorded → not activated
    return DateTime.now().millisecondsSinceEpoch < expires;
  }

  /// The managed key, but only while the subscription is active.
  String? get managedKey => isEntitled ? _prefs.getString(keyPref) : null;

  int get remainingToday {
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    if (_prefs.getString(askedDayPref) != today) return quota[state] ?? 0;
    final int used = _prefs.getInt(askedTodayPref) ?? 0;
    return ((quota[state] ?? 0) - used).clamp(0, 1 << 30);
  }

  /// Consume one live question. Returns false when the quota is spent —
  /// callers should fall back to the offline shelf, never fail silently.
  bool consumeQuestion() {
    if (!isEntitled) return false;
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final int used = _prefs.getString(askedDayPref) == today
        ? (_prefs.getInt(askedTodayPref) ?? 0)
        : 0;
    if (used >= (quota[state] ?? 0)) return false;
    _prefs.setString(askedDayPref, today);
    _prefs.setInt(askedTodayPref, used + 1);
    return true;
  }

  /// Activated by billing later; exposed now so the restore flow and
  /// manual grant tooling share one path.
  Future<void> activate(String tier, String managedKey, DateTime expires) async {
    await _prefs.setString(tierPref, tier);
    await _prefs.setString(keyPref, managedKey);
    await _prefs.setInt(expiresPref, expires.millisecondsSinceEpoch);
    state = tier;
  }

  Future<void> deactivate() async {
    await _prefs.setString(tierPref, 'free');
    await _prefs.remove(keyPref);
    await _prefs.remove(expiresPref);
    state = 'free';
  }
}

final subscriptionServiceProvider =
    NotifierProvider<SubscriptionService, String>(SubscriptionService.new);
