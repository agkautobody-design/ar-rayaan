import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../../tracking/application/tracking_providers.dart';

/// Code-level kill switch for the private log of Qur'an reading, dhikr and
/// lessons (and the quiet completion cards). Set to false and the Settings
/// switch disappears, nothing is recorded and no card appears.
/// See docs/product/return_loop.md.
const bool kReturnLoopEnabled = true;

/// The only acts the switch records. There is deliberately NO value for the
/// five prayers or any other act of worship that is an obligation: a prayer
/// can never be recorded here, because the type has no way to say so. Prayers
/// and fasting are logged by hand in their own screens and My log only reads
/// them.
enum ReturnAct { quran, adhkar, lesson }

/// The Settings switch. OFF by default; stored on this device only.
class ReturnLoopEnabledController extends Notifier<bool> {
  static const String key = 'ar.return.enabled';

  /// Where an earlier release kept a second copy of the same days. No longer
  /// written; removed when the log is switched off.
  static const String legacyDaysKey = 'ar.return.days';

  @override
  bool build() {
    if (!kReturnLoopEnabled) return false;
    try {
      return ref.watch(sharedPreferencesProvider).getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> set(bool on) async {
    if (!kReturnLoopEnabled) return;
    state = on;
    try {
      await ref.read(sharedPreferencesProvider).setBool(key, on);
    } catch (_) {}
    // Switching off erases what the switch recorded; nothing lingers. The
    // prayer log and the fasting log are the person's own and stay.
    if (!on) {
      try {
        await ref.read(sharedPreferencesProvider).remove(legacyDaysKey);
      } catch (_) {}
      await ref.read(trackingStoreProvider.notifier).clear();
    }
  }
}

final NotifierProvider<ReturnLoopEnabledController, bool>
returnLoopEnabledProvider = NotifierProvider<ReturnLoopEnabledController, bool>(
  ReturnLoopEnabledController.new,
);

/// Fire-and-forget hook for the three screens. Never throws (a bare test
/// container has no preferences). A no-op while the switch is off.
Future<void> noteReturn(WidgetRef ref, ReturnAct act) async {
  await noteTracking(ref, switch (act) {
    ReturnAct.quran => TrackingAct.quran,
    ReturnAct.adhkar => TrackingAct.dhikr,
    ReturnAct.lesson => TrackingAct.lesson,
  });
}

/// Records [act] in the private log (Qur'an, dhikr, lessons). A no-op while
/// "Keep a private log" is off. Never throws.
Future<void> noteTracking(WidgetRef ref, TrackingAct act) async {
  try {
    if (!kReturnLoopEnabled) return;
    if (!ref.read(returnLoopEnabledProvider)) return;
    await ref.read(trackingStoreProvider.notifier).record(act);
  } catch (_) {}
}
