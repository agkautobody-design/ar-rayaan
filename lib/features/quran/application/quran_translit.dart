/// The Qur'an transliteration for every ayah (`assets/quran/translit_en.json`).
///
/// Made by a rule-based romaniser from the Arabic (see
/// `tool/translit/build_quran_translit.py`), never typed by hand. It is a
/// reading aid, machine-generated and not yet reviewed by a qualified reader,
/// so every screen that shows it says "Scholar review needed". Licence: CC BY-SA 4.0
/// (quran-json); credit is on the Our Sources screen.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content_loader.dart';
import '../../../app/core/retry_when_online.dart';

/// The data file.
const String kQuranTranslitAsset = 'assets/quran/translit_en.json';

/// Credit shown with the transliteration (Our Sources, and under the reader).
const String kQuranTranslitCredit =
    'Transliteration: quran-json (CC BY-SA 4.0), machine-generated.';

/// Parses the data file into 's:a' -> text. Returns an empty map on anything
/// unexpected, never throws.
Map<String, String> parseQuranTranslit(String raw) {
  try {
    final Object? top = json.decode(raw);
    if (top is! Map) return const <String, String>{};
    final Object? map = top['map'];
    if (map is! Map) return const <String, String>{};
    final Map<String, String> out = <String, String>{};
    map.forEach((Object? k, Object? v) {
      if (k is String && v is String && v.trim().isNotEmpty) out[k] = v;
    });
    return out;
  } catch (_) {
    return const <String, String>{};
  }
}

/// 's:a' -> transliteration for all 6,236 ayahs. Empty if the file cannot be
/// read (offline for the first time); the reader then falls back to the older
/// short list and tries again when the connection returns.
final FutureProvider<Map<String, String>> quranTranslitProvider =
    FutureProvider<Map<String, String>>((ref) async {
      try {
        final String raw = await ContentLoader.loadString(kQuranTranslitAsset);
        return parseQuranTranslit(raw);
      } catch (_) {
        refreshWhenBackOnline(ref);
        return const <String, String>{};
      }
    });
