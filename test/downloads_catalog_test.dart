import 'dart:io';

import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/downloads/domain/download_catalog.dart';
import 'package:ar_rayaan/features/quran/application/quran_offline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('juz and surah ranges', () {
    test('the 30 juz tile the Qur’an with no gap and no overlap', () {
      final Set<int> seen = <int>{};
      int total = 0;
      for (int j = 1; j <= kJuzCount; j++) {
        final List<AyahRef> refs = juzRefs(j);
        expect(refs, isNotEmpty, reason: 'juz $j');
        for (final AyahRef r in refs) {
          expect(seen.add(ayahKey(r)), isTrue, reason: 'duplicate $r');
        }
        total += refs.length;
      }
      expect(total, 6236);
      expect(seen.length, allRefs().length);
    });

    test('known juz sizes and borders', () {
      expect(juzRefs(1).length, 148);
      expect(juzRefs(1).last, const AyahRef(2, 141));
      expect(juzRefs(2).first, const AyahRef(2, 142));
      expect(juzRefs(30).first, const AyahRef(78, 1));
      expect(juzRefs(30).last, const AyahRef(114, 6));
      expect(juzRefs(30).length, 564);
    });

    test('every juz start is a real ayah and they ascend', () {
      AyahRef? prev;
      for (final (int, int) s in kJuzStarts) {
        expect(s.$1, inInclusiveRange(1, 114));
        expect(s.$2, inInclusiveRange(1, ayahCountOf(s.$1)));
        final AyahRef cur = AyahRef(s.$1, s.$2);
        if (prev != null) expect(ayahKey(cur), greaterThan(ayahKey(prev)));
        prev = cur;
      }
      expect(kJuzStarts.length, kJuzCount);
    });

    test('surah ranges use the ayah counts', () {
      expect(surahRefs(1).length, 7);
      expect(surahRefs(2).length, 286);
      expect(
        <int>[for (int s = 1; s <= 114; s++) surahRefs(s).length]
            .fold<int>(0, (int a, int b) => a + b),
        6236,
      );
    });

    test('file names round-trip and bad names are rejected', () {
      expect(refFromFileName('002255.mp3'), const AyahRef(2, 255));
      expect(refFromFileName('001008.mp3'), isNull);
      expect(refFromFileName('115001.mp3'), isNull);
      expect(refFromFileName('notes.txt'), isNull);
      expect(refFromFileName('001001.mp3.part'), isNull);
      for (final AyahRef r in surahRefs(114)) {
        expect(refFromFileName(r.fileName), r);
      }
    });
  });

  group('sizes', () {
    test('estimates scale with ayahs and bit rate', () {
      final int one = estimateAudioBytes(ReciterPack.alHusary, 100);
      expect(estimateAudioBytes(ReciterPack.alHusary, 200), one * 2);
      expect(bitrateKbps(ReciterPack.alHusary), 128);
      expect(bitrateKbps(ReciterPack.abdulBasit), 192);
      expect(estimateAudioBytes(ReciterPack.abdulBasit, 100), greaterThan(one));
      expect(
        estimateAudioBytes(ReciterPack.husaryMuallim, 100),
        greaterThan(one),
      );
    });

    test('the whole Qur’an is in a believable range', () {
      final int whole = estimateAudioBytes(ReciterPack.alHusary, 6236);
      expect(whole, inInclusiveRange(300 * 1000 * 1000, 900 * 1000 * 1000));
    });

    test('formatBytes', () {
      expect(formatBytes(0), '1 KB');
      expect(formatBytes(80000), '80 KB');
      expect(formatBytes(2300000), '2.3 MB');
      expect(formatBytes(549000000), '549 MB');
      expect(formatBytes(1500000000), '1.5 GB');
    });
  });

  group('pack ids', () {
    test('every audio pack resolves back from its id', () {
      for (final ReciterPack r in ReciterPack.all) {
        final AudioCatalog c = AudioCatalog.of(r);
        expect(c.juz.length, 30);
        expect(c.surahs.length, 114);
        expect(c.byId(c.all.id), same(c.all));
        expect(c.byId(c.juz[4].id)?.title, 'Juz 5');
        expect(c.byId(c.surahs[0].id)?.title, '1. Al-Fatihah');
        expect(c.byId('audio:other:all'), isNull);
        expect(audioPackById(r, c.surahs[113].id)?.refs.length, 6);
      }
      expect(
        audioPackById(ReciterPack.alafasy, 'audio:alafasy:juz:31'),
        isNull,
      );
      expect(
        audioPackById(ReciterPack.alafasy, 'audio:alafasy:surah:0'),
        isNull,
      );
      expect(audioPackById(ReciterPack.alafasy, 'nonsense'), isNull);
    });

    test('ids never collide across reciters', () {
      final Set<String> ids = <String>{};
      for (final ReciterPack r in ReciterPack.all) {
        final AudioCatalog c = AudioCatalog.of(r);
        for (final AudioPack p in <AudioPack>[c.all, ...c.juz, ...c.surahs]) {
          expect(ids.add(p.id), isTrue, reason: p.id);
        }
      }
    });
  });

  group('text packs', () {
    final List<String> allAssets = <String>[
      for (final FileSystemEntity f in Directory(
        'assets',
      ).listSync(recursive: true))
        if (f is File) f.path.replaceAll('\\', '/'),
    ];

    test('every pack lists files that exist', () {
      for (final TextPackSpec s in kTextPackSpecs) {
        final List<String> files = s.resolve(allAssets);
        expect(files, isNotEmpty, reason: s.id);
        for (final String f in files) {
          expect(File(f).existsSync(), isTrue, reason: '${s.id}: $f');
        }
      }
    });

    test('ids are unique and no file is in two packs', () {
      final Set<String> ids = <String>{};
      final Set<String> files = <String>{};
      for (final TextPackSpec s in kTextPackSpecs) {
        expect(ids.add(s.id), isTrue, reason: s.id);
        for (final String f in s.resolve(allAssets)) {
          expect(files.add(f), isTrue, reason: 'duplicate $f in ${s.id}');
        }
      }
    });

    test('the Qur’an pack is the same files the reader needs offline', () {
      expect(
        textPackById('text-quran')!.resolve(allAssets),
        (List<String>.of(kQuranOfflineAssets)..sort()),
      );
    });

    test('folder entries expand to json files only', () {
      final List<String> files = textPackById('text-prophets')!
          .resolve(<String>[
            'assets/stories/layers/adam.json',
            'assets/stories/layers/readme.txt',
            'assets/stories/earlier/nuh.json',
            'assets/stories/other.json',
          ]);
      expect(files, contains('assets/stories/layers/adam.json'));
      expect(files, contains('assets/stories/earlier/nuh.json'));
      expect(files, contains('assets/stories/prophets.json'));
      expect(files, isNot(contains('assets/stories/layers/readme.txt')));
      expect(files, isNot(contains('assets/stories/other.json')));
    });

    test('the size estimates are within a factor of two of the real files', () {
      for (final TextPackSpec s in kTextPackSpecs) {
        int real = 0;
        for (final String f in s.resolve(allAssets)) {
          real += File(f).lengthSync();
        }
        expect(s.estimatedBytes, greaterThan(real ~/ 2), reason: s.id);
        expect(s.estimatedBytes, lessThan(real * 2), reason: s.id);
      }
    });

    test('the nasheed note says why there is no download', () {
      expect(kNasheedNoDownloadNote, contains('licence'));
      expect(kNasheedNoDownloadNote, contains('cannot be downloaded'));
    });
  });
}
