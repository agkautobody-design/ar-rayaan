import 'package:ar_rayaan/features/academy/presentation/audio_packs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AudioPacksScreen points to Downloads and promises nothing else',
      (t) async {
    await t.pumpWidget(const MaterialApp(home: AudioPacksScreen()));
    await t.pump();
    expect(find.text('Audio Packs'), findsOneWidget);
    expect(find.text('RECITATION DOWNLOADS'), findsOneWidget);
    expect(find.byKey(const Key('audio-packs-open-downloads')), findsOneWidget);
    // The old "not available yet" list is gone.
    expect(find.textContaining('Planned:'), findsNothing);
    expect(find.text('NOT AVAILABLE YET'), findsNothing);
  });
}
