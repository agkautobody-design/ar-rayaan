import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import 'hadi_package.dart';

/// A read of the meter against one package's limits.
class UsageSnapshot {
  const UsageSnapshot({
    required this.usedToday,
    required this.usedThisMonth,
    required this.limits,
  });

  final int usedToday;
  final int usedThisMonth;
  final HadiPackageLimits limits;

  int get leftToday =>
      (limits.hostedPerDay - usedToday).clamp(0, limits.hostedPerDay);
  int get leftThisMonth =>
      (limits.hostedPerMonth - usedThisMonth).clamp(0, limits.hostedPerMonth);

  /// What the person can still use: the smaller of the day and month room.
  int get remaining => leftToday < leftThisMonth ? leftToday : leftThisMonth;

  bool get canUse => remaining > 0;

  /// True when the month, not the day, is what ran out.
  bool get monthSpent => leftThisMonth == 0;

  /// "2 of 3 AI messages left today".
  String get label {
    if (monthSpent) {
      return '0 of ${limits.hostedPerMonth} AI messages left this month';
    }
    return '$remaining of ${limits.hostedPerDay} AI messages left today';
  }
}

/// Counts hosted-AI messages on this device, per local day and per month.
///
/// This is a courtesy meter for the person's own display and a first line of
/// defence. It is NOT enforcement: anything stored on a device can be reset
/// by the person who owns it. The real cap must be enforced by the server
/// proxy (see docs/product/hadi_packages.md).
///
/// Only hosted-AI messages are counted. The built-in library never touches
/// this meter.
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

  int _usedToday() =>
      _prefs.getString(dayKey) == _dayStamp()
          ? (_prefs.getInt(dayCountKey) ?? 0)
          : 0;

  int _usedThisMonth() =>
      _prefs.getString(monthKey) == _monthStamp()
          ? (_prefs.getInt(monthCountKey) ?? 0)
          : 0;

  UsageSnapshot snapshot(HadiPackageLimits limits) => UsageSnapshot(
        usedToday: _usedToday(),
        usedThisMonth: _usedThisMonth(),
        limits: limits,
      );

  /// Spends one message if the package still has room. Returns false, and
  /// changes nothing, when the day or month allowance is used up.
  Future<bool> tryConsume(HadiPackageLimits limits) async {
    if (!snapshot(limits).canUse) return false;
    await _write(_usedToday() + 1, _usedThisMonth() + 1);
    return true;
  }

  /// Gives one message back (the hosted call failed, so the person should
  /// not pay for it).
  Future<void> refund() async {
    final int d = _usedToday();
    final int m = _usedThisMonth();
    await _write(d > 0 ? d - 1 : 0, m > 0 ? m - 1 : 0);
  }

  /// Marks today's allowance as spent, for when the server says so first.
  Future<void> markDayExhausted(HadiPackageLimits limits) async {
    final int m = _usedThisMonth();
    final int extra = limits.hostedPerDay - _usedToday();
    await _write(
      limits.hostedPerDay,
      extra > 0 ? m + extra : m,
    );
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
