/// Player catalog pack loader — same contract as every content pack:
/// checksum gate, null until Pack 1 ships, never unverified content.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/player.dart';

const String kCatalogSha256 = '71589f1c3f1b775a4be8535fc4a28242c07750b660bc56a4d385fcde507c5ec0';

abstract final class PlayerCatalogPack {
  static Future<Catalog?> load() async {
    if (kCatalogSha256.isEmpty) return null;
    String raw;
    try {
      raw = await rootBundle.loadString('assets/academy/player_catalog.json');
    } catch (_) {
      return null;
    }
    final String digest = sha256.convert(utf8.encode(raw)).toString();
    if (digest != kCatalogSha256) {
      throw StateError('player_catalog.json checksum mismatch');
    }
    final Map<String, dynamic> doc = jsonDecode(raw) as Map<String, dynamic>;
    return Catalog(<Track>[
      for (final Map<String, dynamic> j
          in (doc['tracks'] as List<dynamic>).cast<Map<String, dynamic>>())
        Track.fromJson(j),
    ]);
  }
}
