/// Short Qur'an texts shown outside the reader, with transliteration and
/// meaning: the Bismillah, and the part of 39:9 on the Academy gate and home
/// banner. Data: `assets/quran/snippets.json`, built by
/// `tool/translit/build_quran_snippets.py` from the Qur'an registry and the
/// transliteration dataset (nothing typed by hand).
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content_loader.dart';

const String kQuranSnippetsAsset = 'assets/quran/snippets.json';

class QuranSnippet {
  const QuranSnippet({
    required this.ref,
    required this.arabic,
    required this.translit,
    required this.english,
  });

  final String ref;
  final String arabic;
  final String translit;
  final String english;

  static QuranSnippet? _from(Object? d) {
    if (d is! Map) return null;
    final Object? ref = d['ref'];
    final Object? ar = d['ar'];
    final Object? tl = d['tl'];
    final Object? en = d['en'];
    if (ref is! String || ar is! String || tl is! String || en is! String) {
      return null;
    }
    if (ar.trim().isEmpty || tl.trim().isEmpty || en.trim().isEmpty) {
      return null;
    }
    return QuranSnippet(ref: ref, arabic: ar, translit: tl, english: en);
  }

  /// The snippet called [name] in [raw], or null if absent or malformed.
  static QuranSnippet? parse(String raw, String name) {
    try {
      final Object? d = json.decode(raw);
      if (d is! Map) return null;
      return _from(d[name]);
    } catch (_) {
      return null;
    }
  }
}

/// All snippets by name ('bismillah', 'knowledge'); empty if unreadable.
final FutureProvider<Map<String, QuranSnippet>> quranSnippetsProvider =
    FutureProvider<Map<String, QuranSnippet>>((ref) async {
      try {
        final String raw = await ContentLoader.loadString(kQuranSnippetsAsset);
        final Map<String, QuranSnippet> out = <String, QuranSnippet>{};
        for (final String name in <String>['bismillah', 'knowledge']) {
          final QuranSnippet? s = QuranSnippet.parse(raw, name);
          if (s != null) out[name] = s;
        }
        return out;
      } catch (_) {
        return const <String, QuranSnippet>{};
      }
    });
