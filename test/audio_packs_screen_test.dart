import 'package:ar_rayaan/features/academy/presentation/audio_packs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AudioPacksScreen lists the promised packs and the vault note', (t) async {
    await t.pumpWidget(const MaterialApp(home: AudioPacksScreen()));
    await t.pump();
    expect(find.text('Audio Packs'), findsOneWidget);
    expect(find.textContaining('RECITATION, COMING WITH THE VAULT'), findsOneWidget);
    expect(find.textContaining('Juz 1-30'), findsOneWidget);
  });
}
