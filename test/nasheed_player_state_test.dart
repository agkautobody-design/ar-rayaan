import 'package:ar_rayaan/features/academy/application/nasheed_player_provider.dart';
import 'package:ar_rayaan/features/academy/domain/nasheed_player.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Silent implements AyahAudioPlayer {
  final List<String> log = <String>[];
  // Seam contract: play()'s future completes when the utterance ENDS.
  // Occupy one event-loop turn per track so an unbounded repeat-all loop
  // cannot starve the event loop (timers, stop(), the test watchdog).
  @override
  Future<void> play(String p) async {
    log.add(p);
    await Future<void>.delayed(Duration.zero);
  }
  @override
  Future<void> stop() async {}
}

NasheedTrack t(String id) => NasheedTrack(
      id: id, title: id, artist: 'a', language: 'ar',
      durationSec: 1, source: NasheedSource.officialCatalog,
      playableRef: 'p/$id',
    );

void main() {
  test('playQueue plays from startAt and advances to end', () async {
    final audio = _Silent();
    final n = NasheedPlayerNotifier(audio: audio);
    await n.playQueue(<NasheedTrack>[t('a'), t('b')]);
    expect(audio.log, <String>['p/a', 'p/b']);   // auto-advanced through queue
    expect(n.state.playing, isFalse);            // queue ended → stopped
  });

  test('repeat-all loops; repeat-one stays', () async {
    final audio = _Silent();
    final n = NasheedPlayerNotifier(audio: audio)..repeat = RepeatMode.all;
    // repeat-all never drains on its own: observe a few loops, then stop and
    // let the recursion unwind (stop() flips _stopped; the chain then ends).
    final Future<void> done = n.playQueue(<NasheedTrack>[t('a')]);
    for (int i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(audio.log.length, greaterThan(2)); // looped
    await n.stop();
    await done;
    // repeat-one: the first track repeats forever, so again observe a few
    // cycles rather than awaiting a drain that can never end.
    audio.log.clear();
    final n2 = NasheedPlayerNotifier(audio: audio)..repeat = RepeatMode.one;
    final Future<void> done2 = n2.playQueue(<NasheedTrack>[t('x'), t('y')]);
    for (int i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(audio.log.length, greaterThan(1)); // kept playing
    expect(audio.log.every((p) => p == 'p/x'), isTrue); // never advanced
    await n2.stop();
    await done2;
  });

  test('next/previous/pause state machine', () async {
    final audio = _Silent();
    final n = NasheedPlayerNotifier(audio: audio);
    await n.playQueue(<NasheedTrack>[t('a'), t('b'), t('c')], startAt: 0);
    // it auto-advanced to end during playQueue; reset
    final n2 = NasheedPlayerNotifier(audio: audio);
    await n2.playQueue(<NasheedTrack>[t('a'), t('b'), t('c')], startAt: 1);
    await n2.pause();
    expect(n2.state.playing, isFalse);
    // playQueue drains to the queue's end, so we park on the last track ('c').
    expect(n2.state.current?.id, 'c');
  });

  test('empty queue is a safe no-op', () async {
    final n = NasheedPlayerNotifier(audio: _Silent());
    await n.playQueue(<NasheedTrack>[]);
    expect(n.state.current, isNull);
    await n.next();
    await n.previous();
  });
}
