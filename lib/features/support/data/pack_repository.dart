import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../domain/support_engine.dart';
import '../domain/support_pack.dart';

/// Loads the knowledge packs once at start-up and keeps them in memory so the
/// controllers can read them without waiting.
///
/// Packs past their `reviewBy` date are dropped by the engine (the date is
/// checked on every use). Files whose name starts with `_` are ignored. A pack
/// that fails to parse is skipped: the app then falls back to its built-in
/// wording, never to nothing.
abstract final class SupportPackRepository {
  static const String folder = 'assets/support/packs/';

  static List<SupportPack> _packs = <SupportPack>[];
  static SupportEngine? _engine;

  static List<SupportPack> get packs => _packs;

  /// The engine over the loaded packs, or null when none loaded.
  static SupportEngine? get engine => _engine;

  /// Whether draft wording may be shown. Internal builds and this release
  /// show it with the "review needed" labels; set to false to show only
  /// `shippable` snippets once reviewers have signed.
  static bool allowDraft = true;

  static void setPacks(List<SupportPack> packs) {
    _packs = packs;
    _engine = packs.isEmpty ? null : SupportEngine(packs: packs, allowDraft: allowDraft);
  }

  static SupportPack? byName(String name) {
    for (final SupportPack p in _packs) {
      if (p.name == name) return p;
    }
    return null;
  }

  static Future<void> load() async {
    try {
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> paths = <String>[
        for (final String path in manifest.listAssets())
          if (path.startsWith(folder) &&
              path.endsWith('.json') &&
              !path.substring(folder.length).startsWith('_'))
            path,
      ];
      // All packs are fetched at once (on the web each is a network request;
      // one after another they held the splash screen for about 12 seconds).
      // Future.wait keeps the manifest order, so the engine sees the same list.
      final List<SupportPack?> loaded = await Future.wait<SupportPack?>(
        <Future<SupportPack?>>[
          for (final String path in paths)
            rootBundle
                .loadString(path)
                .then<SupportPack?>(SupportPack.parse)
                .catchError((Object _) => null),
        ],
      );
      setPacks(<SupportPack>[
        for (final SupportPack? p in loaded)
          if (p != null) p,
      ]);
    } catch (_) {
      setPacks(<SupportPack>[]);
    }
  }

  static void debugReset() => setPacks(<SupportPack>[]);
}
