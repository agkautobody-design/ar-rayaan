import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import 'hadi_package.dart';

/// A read of the meter against one package's limits. With the default
/// (unlimited) table, [canUse] is always true.
class UsageSnapshot {
  const UsageSnapshot({
    required this.usedToday,
    required this.usedThisMonth,
    required this.limits,
  });

  final int usedToday;
  final int usedThisMonth;
  final HadiPackageLimits limits;

  bool get canUse {
    final int? d = limits.hostedPerDay;
    final int? m = limits.hostedPerMonth;
    return (d == null || usedToday < d) && (m == null || usedThisMonth < m);
  }
}

/// Counts hosted-AI messages on this device, per local day and per month.
///
/// DORMANT: the owner has decided not to cap anything yet, so with the
/// default table this only counts. It is never shown to the person. If caps
/// are switched on later, remember that anything stored on a device can be
/// reset by its owner: the real cap must be enforced by the server proxy
/// (see docs/product/hadi_packages.md).
class UsageMeter {
  UsageMeter(this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const String dayKey = 'ar.hadi.usage.day';
  static const String dayCountKey = 'ar.hadi.usage.dayCount';
  static const String monthKey = 'ar.hadi.usage.month';
  static const String monthCountKey = 'ar.hadi.usage.monthCount';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  String _dayStamp() {
    final DateTime n = _clock();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  String _monthStamp() => _dayStamp().substring(0, 7);

  int _usedToday() => _prefs.getString(dayKey) == _dayStamp()
      ? (_prefs.getInt(dayCountKey) ?? 0)
      : 0;

  int _usedThisMonth() => _prefs.getString(monthKey) == _monthStamp()
      ? (_prefs.getInt(monthCountKey) ?? 0)
      : 0;

  UsageSnapshot snapshot(HadiPackageLimits limits) => UsageSnapshot(
        usedToday: _usedToday(),
        usedThisMonth: _usedThisMonth(),
        limits: limits,
      );

  /// Counts one hosted message if the package allows it. Returns false, and
  /// changes nothing, when a configured limit is reached.
  Future<bool> tryConsume(HadiPackageLimits limits) async {
    if (!snapshot(limits).canUse) return false;
    await _write(_usedToday() + 1, _usedThisMonth() + 1);
    return true;
  }

  /// Gives one back (the hosted call failed).
  Future<void> refund() async {
    final int d = _usedToday();
    final int m = _usedThisMonth();
    await _write(d > 0 ? d - 1 : 0, m > 0 ? m - 1 : 0);
  }

  Future<void> _write(int day, int month) async {
    await _prefs.setString(dayKey, _dayStamp());
    await _prefs.setInt(dayCountKey, day);
    await _prefs.setString(monthKey, _monthStamp());
    await _prefs.setInt(monthCountKey, month);
  }
}

final Provider<UsageMeter> usageMeterProvider = Provider<UsageMeter>(
  (ref) => UsageMeter(ref.watch(sharedPreferencesProvider)),
);
