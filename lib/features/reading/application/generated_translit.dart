/// Transliteration made by a program for Arabic strings that have none in
/// their own registry (`assets/translit/generated.json`).
///
/// Built by `tool/translit/build_generated_translit.py` with the quran-json
/// rule-based romaniser. Only fully vowelled phrases get an entry; anything
/// else keeps the honest "Transliteration not available yet" note. It is
/// machine-made, so every screen labels it "Scholar review needed".
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content_loader.dart';

const String kGeneratedTranslitAsset = 'assets/translit/generated.json';

/// Short source label shown after "Scholar review needed".
const String kGeneratedTranslitSource = 'rule-based romaniser';

/// Arabic with its spaces tidied, the key used by the data file.
String normaliseArabicKey(String s) =>
    s.split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).join(' ');

/// Parses the file into normalised Arabic -> transliteration. Never throws.
Map<String, String> parseGeneratedTranslit(String raw) {
  try {
    final Object? top = json.decode(raw);
    if (top is! Map) return const <String, String>{};
    final Object? map = top['map'];
    if (map is! Map) return const <String, String>{};
    final Map<String, String> out = <String, String>{};
    map.forEach((Object? k, Object? v) {
      if (k is String && v is Map && v['tl'] is String) {
        final String t = (v['tl'] as String).trim();
        if (t.isNotEmpty) out[k] = t;
      }
    });
    return out;
  } catch (_) {
    return const <String, String>{};
  }
}

final FutureProvider<Map<String, String>> generatedTranslitProvider =
    FutureProvider<Map<String, String>>((ref) async {
      try {
        return parseGeneratedTranslit(
          await ContentLoader.loadString(kGeneratedTranslitAsset),
        );
      } catch (_) {
        return const <String, String>{};
      }
    });
