import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ludo art exists and stays under 1.5MB in total', () {
    final Directory d = Directory('assets/games/ludo');
    expect(d.existsSync(), isTrue);
    final List<File> files = d.listSync().whereType<File>().toList();
    for (final String n in <String>[
      'board.webp',
      'dice_idle.webp',
      'pawn_red.webp',
      'pawn_blue.webp',
      'pawn_yellow.webp',
      'pawn_green.webp',
    ]) {
      expect(File('assets/games/ludo/$n').existsSync(), isTrue, reason: n);
    }
    final int total = files.fold<int>(0, (int s, File f) => s + f.lengthSync());
    expect(total, lessThan(1500 * 1024));
  });

  test('the crop script is shipped beside the art', () {
    expect(File('tool/crop_ludo_board.py').existsSync(), isTrue);
  });
}
