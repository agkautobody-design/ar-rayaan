import 'package:ar_rayaan/features/masjid/domain/masjid_search_service.dart';
import 'package:ar_rayaan/features/prayer/data/city_directory.dart';
import 'package:ar_rayaan/features/prayer/domain/prayer_zone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const PlaceChoice milton = PlaceChoice(
      'Milton, Halton Region, Ontario, Canada', 43.5183, -79.8774);

  test('short name and country come from the label', () {
    expect(milton.shortName, 'Milton');
    expect(milton.country, 'Canada');
    expect(const PlaceChoice('Nowhere', 0, 0).country, '');
  });

  test('a place on the device clock takes no zone (device zone applies)', () {
    final l = CityDirectory.fromChoice(milton, deviceOffsetMinutes: -300);
    expect(l.city, 'Milton');
    expect(l.country, 'Canada');
    expect(l.zone, isNull);
    expect(l.isSet, isTrue);
    expect(l.isGps, isFalse);
  });

  test('a place on another clock borrows the nearest listed city zone', () {
    // Near Dubai, viewed from a Toronto device.
    const PlaceChoice sharjah =
        PlaceChoice('Sharjah, Sharjah, United Arab Emirates', 25.35, 55.40);
    final l = CityDirectory.fromChoice(sharjah, deviceOffsetMinutes: -300);
    expect(l.zone, const PrayerZone(240));
  });

  test('a far-off place with no listed city nearby falls back to device zone',
      () {
    const PlaceChoice sea = PlaceChoice('Open Sea', 0, -30);
    expect(CityDirectory.fromChoice(sea, deviceOffsetMinutes: -300).zone,
        isNull);
  });
}
