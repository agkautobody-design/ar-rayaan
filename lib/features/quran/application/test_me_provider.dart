/// "Hide text / test me" in the Qur'an reader: a display switch only. It adds
/// no content; it just covers the Arabic of each ayah until it is tapped, so
/// a person memorising can try to recite first and then check.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the Arabic is covered. Resets when the reader is left.
final AutoDisposeStateProvider<bool> testMeProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Ayahs the person has tapped to show while test mode is on, as 's:a' keys.
final AutoDisposeStateProvider<Set<String>> revealedAyahsProvider =
    StateProvider.autoDispose<Set<String>>((ref) => const <String>{});

/// Key for one ayah in [revealedAyahsProvider].
String ayahKey(int surah, int ayah) => '$surah:$ayah';
