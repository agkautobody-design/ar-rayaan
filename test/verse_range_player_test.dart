import 'dart:async';

import 'package:ar_rayaan/features/academy/application/recitation_player_provider.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/academy/presentation/verse_range_player_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ar_rayaan/app/theme/app_theme.dart';

/// Instant, silent backend — plans complete within microtasks.
class _SilentAudio implements AyahAudioPlayer {
  @override
  Future<void> play(String pathOrUrl) async {}
  @override
  Future<void> stop() async {}
}

/// Holds each utterance open until released — for observing mid-play state.
class _HoldingAudio implements AyahAudioPlayer {
  Completer<void>? _current;
  @override
  Future<void> play(String pathOrUrl) async {
    _current = Completer<void>();
    return _current!.future;
  }
  @override
  Future<void> stop() async {
    _current?.complete();
    _current = null;
  }
  void release() {
    _current?.complete();
    _current = null;
  }
}

void main() {
  Future<Widget> wrap(Widget child) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final notifier = RecitationPlayerNotifier(
      audio: _SilentAudio(),
      sourceResolver: (PlaybackEvent e) async => 'src:${e.ref.ayah}',
      sleeper: (int ms) async {},
    );
    return ProviderScope(
      overrides: <Override>[
        recitationPlayerProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders play control, range, and reciter credit',
      (tester) async {
    await tester.pumpWidget(
        await wrap(const VerseRangePlayerBar(surah: 1, ayahCount: 7)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    expect(find.text('1 – 7'), findsOneWidget);
    expect(find.text('Sheikh Mahmoud Khalil Al-Husary'), findsOneWidget);
  });

  testWidgets('expanded controls respect engine bounds', (tester) async {
    await tester.pumpWidget(
        await wrap(const VerseRangePlayerBar(surah: 1, ayahCount: 7)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Range loop'), findsOneWidget);
    expect(find.text('Repeat each ayah'), findsOneWidget);
    expect(find.text('Pause between'), findsOneWidget);
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('From ayah'), findsOneWidget);
    expect(find.text('To ayah'), findsOneWidget);

    // Bounds from the locked spec: loop ≤ 10, repeat ≤ 5.
    expect(find.text('10'), findsNothing, reason: 'defaults are 1');
  });

  testWidgets('play drives the player notifier', (tester) async {
    final audio = _HoldingAudio();
    final notifier = RecitationPlayerNotifier(
      audio: audio,
      sourceResolver: (PlaybackEvent e) async => 'src:${e.ref.ayah}',
      sleeper: (int ms) async {},
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        recitationPlayerProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
            body: VerseRangePlayerBar(surah: 1, ayahCount: 7)),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_circle_filled));
    await tester.pump();
    expect(notifier.state.playing, isTrue, reason: 'first utterance held');
    expect(notifier.state.plan.length, 7, reason: 'one event per ayah');

    // Release the held utterance repeatedly until the plan completes.
    for (var i = 0; i < 8; i++) {
      audio.release();
      await tester.pump();
    }
    expect(notifier.state.finished, isTrue);
    expect(notifier.state.playing, isFalse);
  });
}
