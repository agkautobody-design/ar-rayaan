/// The Hifz planner's saved state, readable by other screens (My Journey).
///
/// The planner keeps its own copy while it is open and writes to device
/// storage; it bumps [hifzTickProvider] after each save so readers refresh.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../domain/hifz_progress.dart';

/// Bumped by the planner after every save.
final StateProvider<int> hifzTickProvider = StateProvider<int>((ref) => 0);

/// What the planner has saved on this device (the default plan when nothing
/// is saved or storage is unavailable).
final Provider<HifzState> hifzStateProvider = Provider<HifzState>((Ref ref) {
  ref.watch(hifzTickProvider);
  try {
    return HifzState.decode(
      ref.watch(sharedPreferencesProvider).getString(kHifzPref),
    );
  } catch (_) {
    return const HifzState();
  }
});
