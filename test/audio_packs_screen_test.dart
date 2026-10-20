import 'package:ar_rayaan/features/academy/presentation/audio_packs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AudioPacksScreen says plainly that packs are not available', (t) async {
    await t.pumpWidget(const MaterialApp(home: AudioPacksScreen()));
    await t.pump();
    expect(find.text('Audio Packs'), findsOneWidget);
    expect(find.text('NOT AVAILABLE YET'), findsOneWidget);
    expect(find.textContaining('Planned: Juz Amma'), findsOneWidget);
  });
}
