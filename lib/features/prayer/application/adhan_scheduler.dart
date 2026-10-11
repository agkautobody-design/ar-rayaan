import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/sound/sound_services.dart';
import 'prayer_providers.dart';

/// THE AUTONOMOUS ADHAN. Once the user has interacted with the app (browsers
/// require one gesture before audio), the adhan plays ITSELF at each prayer
/// time — once per prayer per day, gated by an on/off switch the user owns.
class AdhanScheduler {
  AdhanScheduler(this._ref) {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  final Ref _ref;
  Timer? _timer;
  final _played = <String>{};

  Future<void> _tick() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('ar.adhan.autoplay') != true) return;
      final times = await _ref.read(prayerTimesProvider.future);
      final now = DateTime.now();
      final today = now.toIso8601String().substring(0, 10);
      final slots = <String, DateTime>{
        'fajr': times.fajr, 'dhuhr': times.dhuhr, 'asr': times.asr,
        'maghrib': times.maghrib, 'isha': times.isha,
      };
      for (final e in slots.entries) {
        final key = '$today-${e.key}';
        if (_played.contains(key)) continue;
        final diff = now.difference(e.value).inMinutes;
        // fire within the prayer minute (0..0 after; allow 1 min window)
        if (diff >= 0 && diff <= 1) {
          _played.add(key);
          unawaited(_ref.read(speechServiceProvider.notifier).playAdhan());
        }
      }
      if (_played.length > 40) _played.clear();
    } catch (_) {
      // No times yet (location pending) — the next tick tries again.
    }
  }

  void dispose() => _timer?.cancel();
}

final adhanSchedulerProvider = Provider<AdhanScheduler>((ref) {
  final s = AdhanScheduler(ref);
  ref.onDispose(s.dispose);
  return s;
});
