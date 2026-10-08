/// Madinah layout content pack — loader, parser, checksum gate.
///
/// The authentic 604-page mapping ships as `assets/quran/madinah_layout.json`:
/// ```json
/// {
///   "sha256": "<hex of the canonical pack>",
///   "pages": [
///     {"n": 1, "lines": [
///       [{"t": "بِسْمِ", "s": 1, "a": 1, "na": true}],
///       ...
///     ]}
///   ]
/// }
/// ```
/// Segment keys: t=text · s=surah · a=ayah · na=starts-new-ayah ·
/// ea=ends-ayah · sj=sajdah · m=decorative-marker.
///
/// INTEGRITY: the computed SHA-256 must equal the pack's declared hash
/// (which is recorded in the Quran Data Integrity doc and this file's
/// [kMadinahLayoutSha256] after verification). A single flipped bit
/// fails the load — same rule as the Tanzil text.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/mushaf_layout.dart';

/// Filled in when the authentic pack is verified and shipped.
/// Until then the loader returns null and Madinah mode stays hidden.
const String kMadinahLayoutSha256 = '';

abstract final class MushafLayoutPack {
  /// Load + verify + parse the pack. Returns null when the asset is
  /// absent or the checksum is unconfigured — Madinah mode hides
  /// silently rather than ever showing unverified geometry.
  static Future<List<MushafPage>?> load() async {
    String raw;
    try {
      raw = await rootBundle.loadString('assets/quran/madinah_layout.json');
    } catch (_) {
      return null; // pack not shipped yet
    }
    if (kMadinahLayoutSha256.isEmpty) {
      return null; // checksum not recorded — refuse unverified geometry
    }
    final String digest =
        sha256.convert(utf8.encode(raw)).toString();
    if (digest != kMadinahLayoutSha256) {
      throw LayoutFormatException(
        'madinah_layout.json checksum mismatch: $digest',
      );
    }
    final Map<String, dynamic> doc =
        jsonDecode(raw) as Map<String, dynamic>;
    final List<MushafPage> pages = <MushafPage>[
      for (final Map<String, dynamic> p
          in (doc['pages'] as List<dynamic>).cast<Map<String, dynamic>>())
        _parsePage(p),
    ];
    MushafLayoutEngine.validate(pages);
    return pages;
  }

  static MushafPage _parsePage(Map<String, dynamic> p) {
    final List<MushafLine> lines = <MushafLine>[
      for (final List<dynamic> line
          in (p['lines'] as List<dynamic>).cast<List<dynamic>>())
        MushafLine(<LayoutSegment>[
          for (final Map<String, dynamic> seg
              in line.cast<Map<String, dynamic>>())
            LayoutSegment(
              text: seg['t'] as String? ?? '',
              surah: seg['s'] as int?,
              ayah: seg['a'] as int?,
              startsNewAyah: seg['na'] as bool? ?? false,
              endsAyah: seg['ea'] as bool? ?? false,
              sajdah: seg['sj'] as bool? ?? false,
              marker: seg['m'] as bool? ?? false,
            ),
        ]),
    ];
    return MushafPage(
      pageNumber: p['n'] as int,
      lines: lines,
    );
  }
}
