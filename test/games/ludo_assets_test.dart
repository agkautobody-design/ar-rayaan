import 'dart:io';

import 'package:ar_rayaan/features/games/data/ludo_board_art.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ludo art exists, has alpha where it needs it, and stays small', () {
    final Directory d = Directory('assets/games/ludo');
    expect(d.existsSync(), isTrue);
    final Set<String> onDisk =
        d.listSync().whereType<File>().map((File f) => f.path).toSet();
    // Every file the game asks for is there and nothing else is.
    expect(onDisk, LudoBoardArt.allFiles.toSet());
    expect(LudoBoardArt.allFiles.length, 1 + 1 + 4 + 6);
    final int total = onDisk.fold<int>(0, (int s, String p) => s + File(p).lengthSync());
    expect(total, lessThan(900 * 1024));
    // Pawns and dice are transparent cut-outs: WebP with the alpha flag
    // (VP8X header, bit 4 of the flags byte).
    for (final String p in <String>[
      ...LudoBoardArt.pawnFiles,
      LudoBoardArt.dieRolling,
      for (int v = 1; v <= 6; v++) LudoBoardArt.dieFace(v),
    ]) {
      final List<int> b = File(p).readAsBytesSync();
      expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF', reason: p);
      expect(String.fromCharCodes(b.sublist(8, 12)), 'WEBP', reason: p);
      expect(String.fromCharCodes(b.sublist(12, 16)), 'VP8X', reason: p);
      expect(b[20] & 0x10, 0x10, reason: '$p has alpha');
    }
  });

  test('the processing script is shipped beside the art', () {
    expect(File('tool/process_game_art.py').existsSync(), isTrue);
    expect(File('docs/product/games_art_pipeline.md').existsSync(), isTrue);
  });
}
