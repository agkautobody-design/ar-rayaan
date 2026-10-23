import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';

/// "Bigger text" in the story reader, kept on this device.
class StoryBigTextController extends Notifier<bool> {
  static const String prefsKey = 'ar.stories.bigText';

  @override
  bool build() {
    try {
      return ref.watch(sharedPreferencesProvider).getBool(prefsKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> set(bool value) async {
    state = value;
    try {
      await ref.read(sharedPreferencesProvider).setBool(prefsKey, value);
    } catch (_) {
      // Session only.
    }
  }
}

final NotifierProvider<StoryBigTextController, bool> storyBigTextProvider =
    NotifierProvider<StoryBigTextController, bool>(StoryBigTextController.new);

/// Story body and heading sizes: normal and bigger.
double storyBodySize({required bool big}) => big ? 22 : 16.5;
double storyHeadingSize({required bool big}) => big ? 26 : 20;
