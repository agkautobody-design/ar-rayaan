import '../../masjid/domain/masjid_search_service.dart';
import '../../places/domain/community_place.dart';
import '../../places/domain/jumuah_time.dart';

/// The answer to "where is juma" / "closest masjid": the nearest masajid to
/// the person's saved location, with the Jumu'ah time when one is known.
/// Pure, so it is tested without a network or a phone.
class HadiNearestMasjid {
  const HadiNearestMasjid._();

  static const int shown = 3;

  /// "850 m" under a kilometre, "1.2 km" up to 10 km, "14 km" beyond.
  static String distance(double meters) {
    if (meters < 1000) return '${(meters / 10).round() * 10} m';
    final double km = meters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  /// The reply. [community] holds community-added Jumu'ah times by masjid
  /// key. Says plainly when nothing was found.
  static String reply({
    required List<Mosque> mosques,
    required double lat,
    required double lon,
    required bool friday,
    Map<String, JumuahEntry> community = const <String, JumuahEntry>{},
  }) {
    if (mosques.isEmpty) {
      return 'I searched open map data around your saved location and found '
          'no masjid. Open the Masajid screen to search another city, or add '
          'one you know.\n[GO:/masajid]';
    }
    final List<({Mosque m, double d})> ranked = <({Mosque m, double d})>[
      for (final Mosque m in mosques)
        (m: m, d: masjidDistanceMeters(lat, lon, m.lat, m.lon)),
    ]..sort((a, b) => a.d.compareTo(b.d));
    final StringBuffer b = StringBuffer(friday
        ? 'The closest masajid to your saved location, with Jumu’ah '
            'times where anyone has listed one:\n'
        : 'The closest masajid to your saved location:\n');
    for (final ({Mosque m, double d}) r in ranked.take(shown)) {
      final Mosque m = r.m;
      final String key = PlacesPolicy.osmTargetId(m.name, m.lat, m.lon);
      final JumuahEntry? c = community[key];
      final String? time = c?.text ?? m.jumuah;
      b.write('\n• ${m.name} — ${distance(r.d)}');
      if (friday || time != null) {
        if (time != null) {
          b.write('\n  Jumu’ah: $time (${c != null ? 'added by a '
              'community member' : 'from open map data'})');
        } else {
          b.write('\n  Jumu’ah time not listed');
        }
      }
    }
    b.write('\n\nTimes can change, so confirm with the masjid. The Masajid '
        'screen has directions, and a button to add a Jumu’ah time '
        'where none is listed. The search sent only your approximate '
        'location to OpenStreetMap services.\n[GO:/masajid]');
    return b.toString();
  }
}
