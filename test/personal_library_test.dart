
import 'package:ar_rayaan/features/academy/domain/nasheed_player.dart';
import 'package:ar_rayaan/features/academy/application/personal_library_provider.dart';
import 'package:ar_rayaan/features/academy/domain/personal_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // RULE (§8.15): mock-reset lives in setUp ONLY — never in helpers.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  NasheedTrack official(String id) => NasheedTrack(
        id: id, title: 'T $id', artist: 'A', language: 'ar',
        durationSec: 100, source: NasheedSource.officialCatalog,
        playableRef: 'p/$id',
      );

  group('PersonalTrack', () {
    test('json round-trip preserves all fields', () {
      final x = PersonalTrack(
          id: 'p1', title: 'Mine', source: '/music/mine.mp3',
          addedAt: DateTime(2026, 10, 6, 12));
      final r = PersonalTrack.fromJson(x.toJson());
      expect(r.id, 'p1');
      expect(r.title, 'Mine');
      expect(r.source, '/music/mine.mp3');
      expect(r.addedAt, x.addedAt);
    });

    test('isUrl distinguishes URLs from local paths', () {
      expect(PersonalTrack(id: 'a', title: 't', source: 'https://x/y.mp3',
          addedAt: DateTime(2026)).isUrl, isTrue);
      expect(PersonalTrack(id: 'b', title: 't', source: '/m/y.mp3',
          addedAt: DateTime(2026)).isUrl, isFalse);
    });
  });

  group('import tagging', () {
    test('toPlayable maps to personalImport with the founder-law tag', () {
      final p = PersonalTrack(id: 'p9', title: 'Recital',
          source: 'https://example.com/n.mp3', addedAt: DateTime(2026));
      final t = p.toPlayable();
      expect(t.source, NasheedSource.personalImport);
      expect(t.playableRef, p.source); // user's own path/URL is the ref
      expect(t.licenseLine,
          PersonalTrackPlayable.personalBadge); // "Personal — added by you"
    });
  });

  group('exclusion rules', () {
    test('buildMix never includes personalImport tracks', () {
      final personal = PersonalTrack(id: 'p1', title: 'Mine',
          source: 'https://x/y.mp3', addedAt: DateTime(2026)).toPlayable();
      final mix = QueueEngine.buildMix(
          catalog: <NasheedTrack>[official('1'), personal, official('2')]);
      final ids = mix.map((NasheedTrack t) => t.id).toList();
      expect(ids, hasLength(2));
      expect(ids, containsAll(<String>['1', '2']));
      expect(ids, isNot(contains('p1')));
    });

    test('household filter hides the whole library when on', () {
      final lib = <PersonalTrack>[
        PersonalTrack(id: 'p1', title: 'A', source: 's1',
            addedAt: DateTime(2026)),
        PersonalTrack(id: 'p2', title: 'B', source: 's2',
            addedAt: DateTime(2026)),
      ];
      expect(visiblePersonal(lib, false), hasLength(2));
      expect(visiblePersonal(lib, true), isEmpty);
    });
  });

  group('persistence', () {
    test('add/remove round-trips through a fresh notifier instance', () async {
      final prefs = await SharedPreferences.getInstance();
      // ignore: invalid_use_of_visible_for_testing_member
      final a = PersonalLibraryNotifier(prefs);
      await a.add(title: 'One', source: 'https://x/1.mp3');
      await a.add(title: 'Two', source: '/m/2.mp3');
      expect(a.state, hasLength(2));
      await a.remove(a.state.first.id);
      // Re-load from the same prefs: the remove persisted.
      // ignore: invalid_use_of_visible_for_testing_member
      final b = PersonalLibraryNotifier(prefs);
      expect(b.state, hasLength(1));
      expect(b.state.single.title, 'Two');
    });

    test('household hidden flag persists', () async {
      final prefs = await SharedPreferences.getInstance();
      // ignore: invalid_use_of_visible_for_testing_member
      final h = PersonalHiddenNotifier(prefs);
      await h.set(true);
      // ignore: invalid_use_of_visible_for_testing_member
      final h2 = PersonalHiddenNotifier(prefs);
      expect(h2.state, isTrue);
    });
  });
}
