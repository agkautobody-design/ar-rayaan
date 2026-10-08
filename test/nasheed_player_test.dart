import 'package:ar_rayaan/features/academy/domain/nasheed_player.dart';
import 'package:flutter_test/flutter_test.dart';

NasheedTrack t(String id, {String theme = 'praise', String language = 'ar'}) =>
    NasheedTrack(
      id: id,
      title: 'T $id',
      artist: 'A',
      language: language,
      theme: theme,
      durationSec: 100,
      source: NasheedSource.officialCatalog,
      playableRef: 'p/$id',
    );

void main() {
  group('QueueEngine.next/prev', () {
    test('advances within bounds', () {
      expect(QueueEngine.next(0, 3, RepeatMode.off), 1);
      expect(QueueEngine.next(2, 3, RepeatMode.off), isNull);
      expect(QueueEngine.next(2, 3, RepeatMode.all), 0);
      expect(QueueEngine.next(1, 3, RepeatMode.one), 1);
    });

    test('prev at start replays first', () {
      expect(QueueEngine.prev(0, 3), 0);
      expect(QueueEngine.prev(2, 3), 1);
    });

    test('empty queue is safe', () {
      expect(QueueEngine.next(0, 0, RepeatMode.all), isNull);
      expect(QueueEngine.prev(0, 0), 0);
    });
  });

  group('QueueEngine.buildMix', () {
    final catalog = <NasheedTrack>[
      t('1'), t('2', theme: 'istighfar'), t('3', language: 'ur'),
      t('4', theme: 'istighfar', language: 'ur'), t('5'),
    ];

    test('filters by theme and language', () {
      final m1 = QueueEngine.buildMix(catalog: catalog, theme: 'istighfar');
      expect(m1.length, 2);
      expect(m1.every((x) => x.theme == 'istighfar'), isTrue);
      final m2 = QueueEngine.buildMix(catalog: catalog, language: 'ur');
      expect(m2.length, 2);
      expect(m2.every((x) => x.language == 'ur'), isTrue);
    });

    test('deterministic order by seed; different seeds differ', () {
      final a = QueueEngine.buildMix(catalog: catalog, seed: 1);
      final b = QueueEngine.buildMix(catalog: catalog, seed: 1);
      final c = QueueEngine.buildMix(catalog: catalog, seed: 99);
      expect(a.map((x) => x.id).toList(), b.map((x) => x.id).toList());
      expect(a.map((x) => x.id).toList(),
          isNot(c.map((x) => x.id).toList()));
    });

    test('caps at maxTracks', () {
      final big = List<NasheedTrack>.generate(40, (i) => t('x$i'));
      expect(QueueEngine.buildMix(catalog: big, maxTracks: 10).length, 10);
    });
  });

  group('NasheedTrack json', () {
    test('round-trip preserves all fields', () {
      final x = t('9', theme: 'night') ;
      final r = NasheedTrack.fromJson(x.toJson());
      expect(r.id, '9');
      expect(r.theme, 'night');
      expect(r.source, NasheedSource.officialCatalog);
    });
  });
}
