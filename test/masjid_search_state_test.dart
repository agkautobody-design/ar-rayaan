import 'package:ar_rayaan/features/masjid/domain/masjid_search_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MasjidPhase phase({
    bool hasPlace = true,
    bool loading = false,
    bool failed = false,
    int count = 0,
  }) =>
      masjidPhaseFor(
        hasPlace: hasPlace,
        loading: loading,
        failed: failed,
        resultCount: count,
      );

  group('masjidPhaseFor shows one state at a time', () {
    test('no place yet asks for one, whatever else is set', () {
      expect(phase(hasPlace: false), MasjidPhase.needsPlace);
      expect(phase(hasPlace: false, failed: true), MasjidPhase.needsPlace);
    });

    test('loading comes before everything else', () {
      expect(phase(loading: true), MasjidPhase.loading);
      expect(phase(loading: true, failed: true), MasjidPhase.loading);
    });

    test('a failure with nothing to show is "failed", never "empty"', () {
      expect(phase(failed: true), MasjidPhase.failed);
    });

    test('"empty" only when the search really returned zero', () {
      expect(phase(), MasjidPhase.empty);
    });

    test('results win over a failed refresh', () {
      expect(phase(count: 3), MasjidPhase.results);
      expect(phase(count: 3, failed: true), MasjidPhase.results);
    });
  });

  group('masjidStatusText', () {
    test('failed never says none were found', () {
      for (final bool food in <bool>[false, true]) {
        final String t = masjidStatusText(MasjidPhase.failed, food: food)!;
        expect(t, contains('Could not reach the map service'));
        expect(t.toLowerCase(), isNot(contains('no masajid')));
        expect(t.toLowerCase(), isNot(contains('no halal')));
      }
    });

    test('empty is the only phase that says none were found', () {
      expect(
        masjidStatusText(MasjidPhase.empty, food: false),
        startsWith('No masajid found'),
      );
      expect(
        masjidStatusText(MasjidPhase.empty, food: true),
        startsWith('No halal places found'),
      );
      expect(masjidStatusText(MasjidPhase.results, food: false), isNull);
      expect(masjidStatusText(MasjidPhase.needsPlace, food: false), isNull);
      expect(
        masjidStatusText(MasjidPhase.loading, food: false),
        contains('Searching'),
      );
    });
  });

  test('the fallback map link searches the right thing at the right place', () {
    final Uri mosque = masjidFallbackMapUri(lat: 51.5, lon: -0.12, food: false);
    expect(mosque.scheme, 'https');
    expect(mosque.toString(), contains('/search/mosque/@51.5,-0.12'));
    final Uri food = masjidFallbackMapUri(lat: 51.5, lon: -0.12, food: true);
    expect(food.toString(), contains('halal%20restaurant'));
  });
}
