import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/moon_sighting.dart';
import 'hijri_settings.dart';

/// The person's moon-sighting choice (country + authority), saved on this
/// device. Saving a choice also applies its calendar effect (basis + day
/// shift) through [hijriSettingsProvider], so the calendar, Ramadan,
/// fasting markers and Zakat reminders all follow the same month start.
class MoonSightingController extends Notifier<MoonSightingChoice?> {
  @override
  MoonSightingChoice? build() {
    // SharedPreferences is synchronous once bootstrapped, but the moon
    // choice predates no bootstrap contract, so load it lazily instead.
    Future.microtask(() async {
      final MoonSightingChoice? loaded = await MoonSightingChoice.load();
      if (loaded != null && state == null) state = loaded;
    });
    return null;
  }

  Future<void> setChoice(MoonSightingChoice choice) async {
    state = choice;
    await choice.save();
    // Apply the matching calendar basis and shift (the person can still
    // fine-tune the shift afterwards from the calendar sheet).
    final HijriSettingsController hijri = ref.read(hijriSettingsProvider.notifier);
    final effect = choice.hijriEffect;
    await hijri.setBasis(effect.basis);
    await hijri.setAdjustDays(effect.adjustDays);
  }

  Future<void> clear() async {
    state = null;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(MoonSightingChoice.countryKey);
      await prefs.remove(MoonSightingChoice.conventionKey);
    } catch (_) {}
  }
}

final NotifierProvider<MoonSightingController, MoonSightingChoice?>
    moonSightingProvider =
    NotifierProvider<MoonSightingController, MoonSightingChoice?>(
        MoonSightingController.new);
