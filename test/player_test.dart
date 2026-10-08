import 'package:ar_rayaan/features/academy/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

Track t(String id, {String mood = 'morning', String lang = 'ar'}) => Track(
    id: id, title: 'T $id', artist: 'A', language: lang, theme: 'praise',
    mood: mood, audioUrl: 'https://x/$id.mp3');

void main() {
  group('PlayerQueue', () {
    test('enqueue sets index 0 on first track', () {
      var q = const PlayerQueue();
      q = q.enqueue(t('a'));
      expect(q.index, 0);
      expect(q.current!.id, 'a');
      q = q.enqueue(t('b'));
      expect(q.tracks.length, 2);
    });

    test('playNext inserts after current', () {
      var q = const PlayerQueue().enqueue(t('a')).enqueue(t('c'));
      q = q.playNext(t('b'));
      expect(q.tracks.map((Track x) => x.id).toList(), <String>['a', 'b', 'c']);
      expect(q.index, 0);
    });

    test('reorder moves and follows the current track', () {
      var q = const PlayerQueue().enqueue(t('a')).enqueue(t('b')).enqueue(t('c'));
      q = q.reorder(0, 2); // move current 'a' to end
      expect(q.tracks.map((Track x) => x.id).toList(), <String>['b', 'c', 'a']);
      expect(q.current!.id, 'a');
      expect(q.index, 2);
    });

    test('next/previous clamp at the ends', () {
      var q = const PlayerQueue().enqueue(t('a')).enqueue(t('b'));
      expect(q.previous().index, 0, reason: 'start clamps');
      q = q.next();
      expect(q.current!.id, 'b');
      expect(q.next().index, 1, reason: 'end clamps');
    });

    test('named() preserves queue and sets playlist name', () {
      final q = const PlayerQueue().enqueue(t('a')).named('Favorites');
      expect(q.playlistName, 'Favorites');
      expect(q.tracks.length, 1);
    });
  });

  group('Catalog', () {
    test('browse facets are sorted and unique', () {
      final Catalog c = Catalog(<Track>[t('a'), t('b', lang: 'ur'), t('c'), t('d', lang: 'ur')]);
      expect(c.languages, <String>['ar', 'ur']);
      expect(c.byLanguage('ur').length, 2);
      expect(c.artists, <String>['A']);
      expect(c.poets, isEmpty);
    });

    test('json round-trip preserves all fields incl. lyrics', () {
      final Track tr = Track(id: 'x', title: 'Naat', artist: 'Munshid', poet: 'Poet',
          language: 'ur', theme: 'madih', mood: 'night',
          audioUrl: 'https://x/x.mp3', lyricsLines: <String>['line1', 'line2'],
          licenseLine: '(c) Example Reciter — used with permission');
      final Track back = Track.fromJson(tr.toJson());
      expect(back.poet, 'Poet');
      expect(back.lyricsLines, <String>['line1', 'line2']);
      expect(back.licenseLine, '(c) Example Reciter — used with permission');
    });
  });

  group('Mixes', () {
    test('seed cycles the mood pool to the requested count', () {
      final Catalog c = Catalog(<Track>[t('a'), t('b'), t('c')]);
      final List<Track> mix = Mixes.seed('morning', c, count: 7);
      expect(mix.length, 7);
      expect(mix.first.id, mix[3].id, reason: 'cycles');
    });

    test('empty pool yields empty mix (no crash)', () {
      final Catalog c = Catalog(<Track>[t('a', mood: 'night')]);
      expect(Mixes.seed('morning', c), isEmpty);
    });

    test('five moods are defined', () {
      expect(Mixes.kMoods.length, 5);
    });
  });
}
