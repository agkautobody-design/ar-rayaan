import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// The "Text size" choice in Settings: how much bigger (or smaller) the
/// words of the whole app are drawn, on top of the phone's own text size.
enum TextSizeChoice {
  small('small', 'Small', 0.9),
  normal('normal', 'Normal', 1.0),
  large('large', 'Large', 1.2),
  extraLarge('extraLarge', 'Extra large', 1.4);

  const TextSizeChoice(this.id, this.label, this.factor);

  /// What is stored in preferences.
  final String id;

  /// What the person reads in Settings.
  final String label;

  /// Multiplies the system text scale.
  final double factor;

  static TextSizeChoice fromId(String? id) {
    for (final TextSizeChoice c in TextSizeChoice.values) {
      if (c.id == id) return c;
    }
    return TextSizeChoice.normal;
  }
}

/// Elder Mode never draws text smaller than this, whatever the phone says.
const double kElderTextFloor = 1.35;

/// The smallest and largest overall text scale. Layouts are built and tested
/// up to 2.0x (Android's largest setting); beyond that nothing is promised.
const double kMinTextScale = 0.85;
const double kMaxTextScale = 2.0;

/// The one text scale the app draws with.
///
/// [system] is the phone's text scale, [user] the Settings > Text size
/// factor. Elder Mode lifts the result to at least [kElderTextFloor]. The
/// result always stays within [kMinTextScale] and [kMaxTextScale].
double effectiveTextScale({
  required double system,
  required double user,
  required bool elder,
}) {
  double scale = system * user;
  if (elder) scale = math.max(scale, kElderTextFloor);
  return math.min(kMaxTextScale, math.max(kMinTextScale, scale));
}

/// Remembers the Text size choice (shared_preferences, key `ar.text.size`).
class TextSizeController extends Notifier<TextSizeChoice> {
  static const String prefKey = 'ar.text.size';

  @override
  TextSizeChoice build() {
    try {
      return TextSizeChoice.fromId(
        ref.read(sharedPreferencesProvider).getString(prefKey),
      );
    } catch (_) {
      // Preferences unavailable (a test without a store): normal size.
      return TextSizeChoice.normal;
    }
  }

  Future<void> set(TextSizeChoice choice) async {
    state = choice;
    try {
      await ref.read(sharedPreferencesProvider).setString(prefKey, choice.id);
    } catch (_) {
      // Not saved; the choice still applies until the app closes.
    }
  }
}

final NotifierProvider<TextSizeController, TextSizeChoice> textSizeProvider =
    NotifierProvider<TextSizeController, TextSizeChoice>(
      TextSizeController.new,
    );
