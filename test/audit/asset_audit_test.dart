import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/games/chess/chess_board_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// WAVE 6 — ASSET INTEGRITY. Every asset path referenced in shipped
/// Dart code must exist in the repo.
void main() {
  test('W6 all referenced asset files exist', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final referenced = <String>{};
    final re = RegExp(
        r"assets/[A-Za-z0-9_\-/]+\.(?:jpg|png|webp|json|ttf)");
    for (final f in files) {
      for (final m in re.allMatches(f.readAsStringSync())) {
        referenced.add(m.group(0)!);
      }
    }
    expect(referenced, isNotEmpty);
    // Two packs are vault-delivered by design: their loaders return null
    // gracefully until the Quran Foundation vault ships them (checksums
    // gate every byte — see mushaf_layout_pack.dart).
    const vaultPending = {
      'assets/quran/madinah_layout.json',
      'assets/academy/player_catalog.json',
    };
    final missing = referenced
        .where((p) => !File(p).existsSync() && !vaultPending.contains(p))
        .toList();
    expect(missing, isEmpty,
        reason: 'missing assets referenced in code: \$missing');
  });

  test('chess board art: every file the board asks for exists, none is orphaned',
      () {
    // The board builds these paths from the piece and the theme, so the
    // literal-path scan above cannot see them.
    final Set<String> wanted = ChessAssets.all().toSet();
    for (final String p in wanted) {
      expect(File(p).existsSync(), isTrue, reason: 'missing $p');
    }
    final Set<String> onDisk = Directory(ChessAssets.root)
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path)
        .toSet();
    expect(onDisk.difference(wanted), isEmpty,
        reason: 'files in assets/games/chess that nothing uses');
  });

  test('W6 Games art: every manifest slot has its file, within budget', () {
    final dir = Directory('assets/games/art');
    final manifest = jsonDecode(File('${dir.path}/manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    final slots = manifest['slots'] as Map<String, dynamic>;
    expect(slots, isNotEmpty);
    var total = 0;
    for (final e in slots.entries) {
      final file = File((e.value as Map<String, dynamic>)['file'] as String);
      expect(file.existsSync(), isTrue, reason: 'slot ${e.key}');
      expect(file.path.split('/').last.split('.').first, e.key,
          reason: 'file is named after its slot');
      total += file.lengthSync();
    }
    // Art budget: keep the whole folder under 4 MB.
    expect(total, lessThan(4 * 1024 * 1024));
  });
}
