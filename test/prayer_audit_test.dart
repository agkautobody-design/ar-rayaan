import 'package:ar_rayaan/features/prayer/application/prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_settings.dart';
import 'package:ar_rayaan/features/prayer/data/adhan_calc_prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/data/city_directory.dart';
import 'package:ar_rayaan/features/prayer/domain/prayer_times.dart';
import 'package:ar_rayaan/features/prayer/domain/prayer_zone.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prayer-times audit (October 2026): the city list, the daylight-saving
/// rules, the regional default method, and the on-device calculation checked
/// against an independent astronomical calculation (PyEphem: sunrise and
/// sunset with the sun's centre 50 arcminutes below the horizon, twilight at
/// the method's angle, Asr from the sun's altitude at transit, then the
/// high-latitude rule applied to the same night length).

PrayerLocation _city(String name) =>
    CityDirectory.cities.firstWhere((PrayerLocation c) => c.city == name);

PrayerLocation _at(double lat, double lng) => PrayerLocation(
      city: 'x',
      country: 'x',
      latitude: lat,
      longitude: lng,
    );

class _Golden {
  const _Golden(this.city, this.method, this.hanafi, this.highLat, this.date,
      this.fajr, this.sunrise, this.dhuhr, this.asr, this.maghrib, this.isha);
  final String city, method, highLat, date;
  final bool hanafi;

  /// Minutes after local midnight.
  final int fajr, sunrise, dhuhr, asr, maghrib, isha;
}

/// Local minutes after midnight from PyEphem. Dhuhr includes the method's
/// own safety minute where the method has one.
const List<_Golden> _golden = <_Golden>[
  _Golden('Makkah', 'umm_al_qura', false, 'auto', '2026-10-27', 304, 381, 725, 921, 1068, 1158),
  _Golden('Makkah', 'umm_al_qura', false, 'auto', '2026-06-21', 251, 339, 742, 942, 1146, 1236),
  _Golden('Makkah', 'umm_al_qura', false, 'auto', '2026-12-21', 332, 414, 739, 923, 1064, 1154),
  _Golden('London', 'muslim_world_league', false, 'middle_of_the_night', '2026-10-27', 293, 405, 705, 853, 1003, 1109),
  _Golden('London', 'muslim_world_league', false, 'middle_of_the_night', '2026-06-21', 62, 283, 783, 1045, 1282, 62),
  _Golden('London', 'muslim_world_league', false, 'middle_of_the_night', '2026-12-21', 359, 484, 720, 818, 953, 1071),
  _Golden('Jakarta', 'kemenag', false, 'auto', '2026-10-27', 248, 327, 696, 890, 1066, 1137),
  _Golden('Jakarta', 'kemenag', false, 'auto', '2026-06-21', 278, 361, 714, 916, 1067, 1142),
  _Golden('Jakarta', 'kemenag', false, 'auto', '2026-12-21', 250, 336, 711, 918, 1085, 1161),
  _Golden('Dhaka', 'karachi', true, 'auto', '2026-10-27', 285, 361, 703, 946, 1043, 1119),
  _Golden('Dhaka', 'karachi', true, 'auto', '2026-06-21', 224, 312, 721, 1001, 1128, 1216),
  _Golden('Dhaka', 'karachi', true, 'auto', '2026-12-21', 315, 396, 717, 940, 1036, 1117),
  _Golden('Sydney', 'muslim_world_league', false, 'auto', '2026-10-27', 271, 360, 760, 980, 1158, 1243),
  _Golden('Sydney', 'muslim_world_league', false, 'auto', '2026-06-21', 330, 420, 718, 876, 1014, 1098),
  _Golden('Sydney', 'muslim_world_league', false, 'auto', '2026-12-21', 236, 341, 774, 998, 1205, 1303),
  _Golden('Oslo', 'muslim_world_league', false, 'auto', '2026-10-27', 318, 446, 722, 841, 995, 1122),
  _Golden('Oslo', 'muslim_world_league', false, 'auto', '2026-06-21', 189, 234, 800, 1080, 1364, 1408),
  _Golden('Oslo', 'muslim_world_league', false, 'auto', '2026-12-21', 403, 558, 736, 787, 912, 1067),
  _Golden('Toronto', 'north_america', false, 'auto', '2026-10-27', 387, 467, 782, 949, 1095, 1175),
  _Golden('Toronto', 'north_america', false, 'auto', '2026-06-21', 225, 336, 800, 1046, 1263, 1373),
  _Golden('Toronto', 'north_america', false, 'auto', '2026-12-21', 381, 468, 737, 866, 1004, 1090),
];

/// (standard offset, rule, UTC instant, expected offset in minutes), taken
/// from the IANA tz database (2026e) one hour either side of every change
/// in 2026-2028 and in mid January and mid July.
const List<(int, DstRule, String, int)> _tzRows = <(int, DstRule, String, int)>[
  (-300, DstRule.us, '2026-03-08T06:00:00Z', -300), // America/New_York
  (-300, DstRule.us, '2026-03-08T07:00:00Z', -240), // America/New_York
  (-300, DstRule.us, '2026-11-01T05:00:00Z', -240), // America/New_York
  (-300, DstRule.us, '2026-11-01T06:00:00Z', -300), // America/New_York
  (-300, DstRule.us, '2027-03-14T06:00:00Z', -300), // America/New_York
  (-300, DstRule.us, '2027-03-14T07:00:00Z', -240), // America/New_York
  (-300, DstRule.us, '2027-11-07T05:00:00Z', -240), // America/New_York
  (-300, DstRule.us, '2027-11-07T06:00:00Z', -300), // America/New_York
  (-300, DstRule.us, '2028-03-12T06:00:00Z', -300), // America/New_York
  (-300, DstRule.us, '2028-03-12T07:00:00Z', -240), // America/New_York
  (-300, DstRule.us, '2028-11-05T05:00:00Z', -240), // America/New_York
  (-300, DstRule.us, '2028-11-05T06:00:00Z', -300), // America/New_York
  (-300, DstRule.us, '2026-01-15T12:00:00Z', -300), // America/New_York
  (-300, DstRule.us, '2026-07-15T12:00:00Z', -240), // America/New_York
  (-300, DstRule.us, '2027-01-15T12:00:00Z', -300), // America/New_York
  (-300, DstRule.us, '2027-07-15T12:00:00Z', -240), // America/New_York
  (-300, DstRule.us, '2028-01-15T12:00:00Z', -300), // America/New_York
  (-300, DstRule.us, '2028-07-15T12:00:00Z', -240), // America/New_York
  (-360, DstRule.us, '2026-03-08T07:00:00Z', -360), // America/Chicago
  (-360, DstRule.us, '2026-03-08T08:00:00Z', -300), // America/Chicago
  (-360, DstRule.us, '2026-11-01T06:00:00Z', -300), // America/Chicago
  (-360, DstRule.us, '2026-11-01T07:00:00Z', -360), // America/Chicago
  (-360, DstRule.us, '2027-03-14T07:00:00Z', -360), // America/Chicago
  (-360, DstRule.us, '2027-03-14T08:00:00Z', -300), // America/Chicago
  (-360, DstRule.us, '2027-11-07T06:00:00Z', -300), // America/Chicago
  (-360, DstRule.us, '2027-11-07T07:00:00Z', -360), // America/Chicago
  (-360, DstRule.us, '2028-03-12T07:00:00Z', -360), // America/Chicago
  (-360, DstRule.us, '2028-03-12T08:00:00Z', -300), // America/Chicago
  (-360, DstRule.us, '2028-11-05T06:00:00Z', -300), // America/Chicago
  (-360, DstRule.us, '2028-11-05T07:00:00Z', -360), // America/Chicago
  (-360, DstRule.us, '2026-01-15T12:00:00Z', -360), // America/Chicago
  (-360, DstRule.us, '2026-07-15T12:00:00Z', -300), // America/Chicago
  (-360, DstRule.us, '2027-01-15T12:00:00Z', -360), // America/Chicago
  (-360, DstRule.us, '2027-07-15T12:00:00Z', -300), // America/Chicago
  (-360, DstRule.us, '2028-01-15T12:00:00Z', -360), // America/Chicago
  (-360, DstRule.us, '2028-07-15T12:00:00Z', -300), // America/Chicago
  (-420, DstRule.us, '2026-03-08T08:00:00Z', -420), // America/Denver
  (-420, DstRule.us, '2026-03-08T09:00:00Z', -360), // America/Denver
  (-420, DstRule.us, '2026-11-01T07:00:00Z', -360), // America/Denver
  (-420, DstRule.us, '2026-11-01T08:00:00Z', -420), // America/Denver
  (-420, DstRule.us, '2027-03-14T08:00:00Z', -420), // America/Denver
  (-420, DstRule.us, '2027-03-14T09:00:00Z', -360), // America/Denver
  (-420, DstRule.us, '2027-11-07T07:00:00Z', -360), // America/Denver
  (-420, DstRule.us, '2027-11-07T08:00:00Z', -420), // America/Denver
  (-420, DstRule.us, '2028-03-12T08:00:00Z', -420), // America/Denver
  (-420, DstRule.us, '2028-03-12T09:00:00Z', -360), // America/Denver
  (-420, DstRule.us, '2028-11-05T07:00:00Z', -360), // America/Denver
  (-420, DstRule.us, '2028-11-05T08:00:00Z', -420), // America/Denver
  (-420, DstRule.us, '2026-01-15T12:00:00Z', -420), // America/Denver
  (-420, DstRule.us, '2026-07-15T12:00:00Z', -360), // America/Denver
  (-420, DstRule.us, '2027-01-15T12:00:00Z', -420), // America/Denver
  (-420, DstRule.us, '2027-07-15T12:00:00Z', -360), // America/Denver
  (-420, DstRule.us, '2028-01-15T12:00:00Z', -420), // America/Denver
  (-420, DstRule.us, '2028-07-15T12:00:00Z', -360), // America/Denver
  (-480, DstRule.us, '2026-03-08T09:00:00Z', -480), // America/Los_Angeles
  (-480, DstRule.us, '2026-03-08T10:00:00Z', -420), // America/Los_Angeles
  (-480, DstRule.us, '2026-11-01T08:00:00Z', -420), // America/Los_Angeles
  (-480, DstRule.us, '2026-11-01T09:00:00Z', -480), // America/Los_Angeles
  (-480, DstRule.us, '2027-03-14T09:00:00Z', -480), // America/Los_Angeles
  (-480, DstRule.us, '2027-03-14T10:00:00Z', -420), // America/Los_Angeles
  (-480, DstRule.us, '2027-11-07T08:00:00Z', -420), // America/Los_Angeles
  (-480, DstRule.us, '2027-11-07T09:00:00Z', -480), // America/Los_Angeles
  (-480, DstRule.us, '2028-03-12T09:00:00Z', -480), // America/Los_Angeles
  (-480, DstRule.us, '2028-03-12T10:00:00Z', -420), // America/Los_Angeles
  (-480, DstRule.us, '2028-11-05T08:00:00Z', -420), // America/Los_Angeles
  (-480, DstRule.us, '2028-11-05T09:00:00Z', -480), // America/Los_Angeles
  (-480, DstRule.us, '2026-01-15T12:00:00Z', -480), // America/Los_Angeles
  (-480, DstRule.us, '2026-07-15T12:00:00Z', -420), // America/Los_Angeles
  (-480, DstRule.us, '2027-01-15T12:00:00Z', -480), // America/Los_Angeles
  (-480, DstRule.us, '2027-07-15T12:00:00Z', -420), // America/Los_Angeles
  (-480, DstRule.us, '2028-01-15T12:00:00Z', -480), // America/Los_Angeles
  (-480, DstRule.us, '2028-07-15T12:00:00Z', -420), // America/Los_Angeles
  (-240, DstRule.us, '2026-03-08T05:00:00Z', -240), // America/Halifax
  (-240, DstRule.us, '2026-03-08T06:00:00Z', -180), // America/Halifax
  (-240, DstRule.us, '2026-11-01T04:00:00Z', -180), // America/Halifax
  (-240, DstRule.us, '2026-11-01T05:00:00Z', -240), // America/Halifax
  (-240, DstRule.us, '2027-03-14T05:00:00Z', -240), // America/Halifax
  (-240, DstRule.us, '2027-03-14T06:00:00Z', -180), // America/Halifax
  (-240, DstRule.us, '2027-11-07T04:00:00Z', -180), // America/Halifax
  (-240, DstRule.us, '2027-11-07T05:00:00Z', -240), // America/Halifax
  (-240, DstRule.us, '2028-03-12T05:00:00Z', -240), // America/Halifax
  (-240, DstRule.us, '2028-03-12T06:00:00Z', -180), // America/Halifax
  (-240, DstRule.us, '2028-11-05T04:00:00Z', -180), // America/Halifax
  (-240, DstRule.us, '2028-11-05T05:00:00Z', -240), // America/Halifax
  (-240, DstRule.us, '2026-01-15T12:00:00Z', -240), // America/Halifax
  (-240, DstRule.us, '2026-07-15T12:00:00Z', -180), // America/Halifax
  (-240, DstRule.us, '2027-01-15T12:00:00Z', -240), // America/Halifax
  (-240, DstRule.us, '2027-07-15T12:00:00Z', -180), // America/Halifax
  (-240, DstRule.us, '2028-01-15T12:00:00Z', -240), // America/Halifax
  (-240, DstRule.us, '2028-07-15T12:00:00Z', -180), // America/Halifax
  (-300, DstRule.us, '2026-03-08T06:00:00Z', -300), // America/Toronto
  (-300, DstRule.us, '2026-03-08T07:00:00Z', -240), // America/Toronto
  (-300, DstRule.us, '2026-11-01T05:00:00Z', -240), // America/Toronto
  (-300, DstRule.us, '2026-11-01T06:00:00Z', -300), // America/Toronto
  (-300, DstRule.us, '2027-03-14T06:00:00Z', -300), // America/Toronto
  (-300, DstRule.us, '2027-03-14T07:00:00Z', -240), // America/Toronto
  (-300, DstRule.us, '2027-11-07T05:00:00Z', -240), // America/Toronto
  (-300, DstRule.us, '2027-11-07T06:00:00Z', -300), // America/Toronto
  (-300, DstRule.us, '2028-03-12T06:00:00Z', -300), // America/Toronto
  (-300, DstRule.us, '2028-03-12T07:00:00Z', -240), // America/Toronto
  (-300, DstRule.us, '2028-11-05T05:00:00Z', -240), // America/Toronto
  (-300, DstRule.us, '2028-11-05T06:00:00Z', -300), // America/Toronto
  (-300, DstRule.us, '2026-01-15T12:00:00Z', -300), // America/Toronto
  (-300, DstRule.us, '2026-07-15T12:00:00Z', -240), // America/Toronto
  (-300, DstRule.us, '2027-01-15T12:00:00Z', -300), // America/Toronto
  (-300, DstRule.us, '2027-07-15T12:00:00Z', -240), // America/Toronto
  (-300, DstRule.us, '2028-01-15T12:00:00Z', -300), // America/Toronto
  (-300, DstRule.us, '2028-07-15T12:00:00Z', -240), // America/Toronto
  (0, DstRule.eu, '2026-03-29T00:00:00Z', 0), // Europe/London
  (0, DstRule.eu, '2026-03-29T01:00:00Z', 60), // Europe/London
  (0, DstRule.eu, '2026-10-25T00:00:00Z', 60), // Europe/London
  (0, DstRule.eu, '2026-10-25T01:00:00Z', 0), // Europe/London
  (0, DstRule.eu, '2027-03-28T00:00:00Z', 0), // Europe/London
  (0, DstRule.eu, '2027-03-28T01:00:00Z', 60), // Europe/London
  (0, DstRule.eu, '2027-10-31T00:00:00Z', 60), // Europe/London
  (0, DstRule.eu, '2027-10-31T01:00:00Z', 0), // Europe/London
  (0, DstRule.eu, '2028-03-26T00:00:00Z', 0), // Europe/London
  (0, DstRule.eu, '2028-03-26T01:00:00Z', 60), // Europe/London
  (0, DstRule.eu, '2028-10-29T00:00:00Z', 60), // Europe/London
  (0, DstRule.eu, '2028-10-29T01:00:00Z', 0), // Europe/London
  (0, DstRule.eu, '2026-01-15T12:00:00Z', 0), // Europe/London
  (0, DstRule.eu, '2026-07-15T12:00:00Z', 60), // Europe/London
  (0, DstRule.eu, '2027-01-15T12:00:00Z', 0), // Europe/London
  (0, DstRule.eu, '2027-07-15T12:00:00Z', 60), // Europe/London
  (0, DstRule.eu, '2028-01-15T12:00:00Z', 0), // Europe/London
  (0, DstRule.eu, '2028-07-15T12:00:00Z', 60), // Europe/London
  (60, DstRule.eu, '2026-03-29T00:00:00Z', 60), // Europe/Paris
  (60, DstRule.eu, '2026-03-29T01:00:00Z', 120), // Europe/Paris
  (60, DstRule.eu, '2026-10-25T00:00:00Z', 120), // Europe/Paris
  (60, DstRule.eu, '2026-10-25T01:00:00Z', 60), // Europe/Paris
  (60, DstRule.eu, '2027-03-28T00:00:00Z', 60), // Europe/Paris
  (60, DstRule.eu, '2027-03-28T01:00:00Z', 120), // Europe/Paris
  (60, DstRule.eu, '2027-10-31T00:00:00Z', 120), // Europe/Paris
  (60, DstRule.eu, '2027-10-31T01:00:00Z', 60), // Europe/Paris
  (60, DstRule.eu, '2028-03-26T00:00:00Z', 60), // Europe/Paris
  (60, DstRule.eu, '2028-03-26T01:00:00Z', 120), // Europe/Paris
  (60, DstRule.eu, '2028-10-29T00:00:00Z', 120), // Europe/Paris
  (60, DstRule.eu, '2028-10-29T01:00:00Z', 60), // Europe/Paris
  (60, DstRule.eu, '2026-01-15T12:00:00Z', 60), // Europe/Paris
  (60, DstRule.eu, '2026-07-15T12:00:00Z', 120), // Europe/Paris
  (60, DstRule.eu, '2027-01-15T12:00:00Z', 60), // Europe/Paris
  (60, DstRule.eu, '2027-07-15T12:00:00Z', 120), // Europe/Paris
  (60, DstRule.eu, '2028-01-15T12:00:00Z', 60), // Europe/Paris
  (60, DstRule.eu, '2028-07-15T12:00:00Z', 120), // Europe/Paris
  (120, DstRule.eu, '2026-03-29T00:00:00Z', 120), // Europe/Athens
  (120, DstRule.eu, '2026-03-29T01:00:00Z', 180), // Europe/Athens
  (120, DstRule.eu, '2026-10-25T00:00:00Z', 180), // Europe/Athens
  (120, DstRule.eu, '2026-10-25T01:00:00Z', 120), // Europe/Athens
  (120, DstRule.eu, '2027-03-28T00:00:00Z', 120), // Europe/Athens
  (120, DstRule.eu, '2027-03-28T01:00:00Z', 180), // Europe/Athens
  (120, DstRule.eu, '2027-10-31T00:00:00Z', 180), // Europe/Athens
  (120, DstRule.eu, '2027-10-31T01:00:00Z', 120), // Europe/Athens
  (120, DstRule.eu, '2028-03-26T00:00:00Z', 120), // Europe/Athens
  (120, DstRule.eu, '2028-03-26T01:00:00Z', 180), // Europe/Athens
  (120, DstRule.eu, '2028-10-29T00:00:00Z', 180), // Europe/Athens
  (120, DstRule.eu, '2028-10-29T01:00:00Z', 120), // Europe/Athens
  (120, DstRule.eu, '2026-01-15T12:00:00Z', 120), // Europe/Athens
  (120, DstRule.eu, '2026-07-15T12:00:00Z', 180), // Europe/Athens
  (120, DstRule.eu, '2027-01-15T12:00:00Z', 120), // Europe/Athens
  (120, DstRule.eu, '2027-07-15T12:00:00Z', 180), // Europe/Athens
  (120, DstRule.eu, '2028-01-15T12:00:00Z', 120), // Europe/Athens
  (120, DstRule.eu, '2028-07-15T12:00:00Z', 180), // Europe/Athens
  (0, DstRule.eu, '2026-03-29T00:00:00Z', 0), // Europe/Lisbon
  (0, DstRule.eu, '2026-03-29T01:00:00Z', 60), // Europe/Lisbon
  (0, DstRule.eu, '2026-10-25T00:00:00Z', 60), // Europe/Lisbon
  (0, DstRule.eu, '2026-10-25T01:00:00Z', 0), // Europe/Lisbon
  (0, DstRule.eu, '2027-03-28T00:00:00Z', 0), // Europe/Lisbon
  (0, DstRule.eu, '2027-03-28T01:00:00Z', 60), // Europe/Lisbon
  (0, DstRule.eu, '2027-10-31T00:00:00Z', 60), // Europe/Lisbon
  (0, DstRule.eu, '2027-10-31T01:00:00Z', 0), // Europe/Lisbon
  (0, DstRule.eu, '2028-03-26T00:00:00Z', 0), // Europe/Lisbon
  (0, DstRule.eu, '2028-03-26T01:00:00Z', 60), // Europe/Lisbon
  (0, DstRule.eu, '2028-10-29T00:00:00Z', 60), // Europe/Lisbon
  (0, DstRule.eu, '2028-10-29T01:00:00Z', 0), // Europe/Lisbon
  (0, DstRule.eu, '2026-01-15T12:00:00Z', 0), // Europe/Lisbon
  (0, DstRule.eu, '2026-07-15T12:00:00Z', 60), // Europe/Lisbon
  (0, DstRule.eu, '2027-01-15T12:00:00Z', 0), // Europe/Lisbon
  (0, DstRule.eu, '2027-07-15T12:00:00Z', 60), // Europe/Lisbon
  (0, DstRule.eu, '2028-01-15T12:00:00Z', 0), // Europe/Lisbon
  (0, DstRule.eu, '2028-07-15T12:00:00Z', 60), // Europe/Lisbon
  (600, DstRule.au, '2026-04-04T15:00:00Z', 660), // Australia/Sydney
  (600, DstRule.au, '2026-04-04T16:00:00Z', 600), // Australia/Sydney
  (600, DstRule.au, '2026-10-03T15:00:00Z', 600), // Australia/Sydney
  (600, DstRule.au, '2026-10-03T16:00:00Z', 660), // Australia/Sydney
  (600, DstRule.au, '2027-04-03T15:00:00Z', 660), // Australia/Sydney
  (600, DstRule.au, '2027-04-03T16:00:00Z', 600), // Australia/Sydney
  (600, DstRule.au, '2027-10-02T15:00:00Z', 600), // Australia/Sydney
  (600, DstRule.au, '2027-10-02T16:00:00Z', 660), // Australia/Sydney
  (600, DstRule.au, '2028-04-01T15:00:00Z', 660), // Australia/Sydney
  (600, DstRule.au, '2028-04-01T16:00:00Z', 600), // Australia/Sydney
  (600, DstRule.au, '2028-09-30T15:00:00Z', 600), // Australia/Sydney
  (600, DstRule.au, '2028-09-30T16:00:00Z', 660), // Australia/Sydney
  (600, DstRule.au, '2026-01-15T12:00:00Z', 660), // Australia/Sydney
  (600, DstRule.au, '2026-07-15T12:00:00Z', 600), // Australia/Sydney
  (600, DstRule.au, '2027-01-15T12:00:00Z', 660), // Australia/Sydney
  (600, DstRule.au, '2027-07-15T12:00:00Z', 600), // Australia/Sydney
  (600, DstRule.au, '2028-01-15T12:00:00Z', 660), // Australia/Sydney
  (600, DstRule.au, '2028-07-15T12:00:00Z', 600), // Australia/Sydney
  (570, DstRule.au, '2026-04-04T16:00:00Z', 630), // Australia/Adelaide
  (570, DstRule.au, '2026-04-04T17:00:00Z', 570), // Australia/Adelaide
  (570, DstRule.au, '2026-10-03T16:00:00Z', 570), // Australia/Adelaide
  (570, DstRule.au, '2026-10-03T17:00:00Z', 630), // Australia/Adelaide
  (570, DstRule.au, '2027-04-03T16:00:00Z', 630), // Australia/Adelaide
  (570, DstRule.au, '2027-04-03T17:00:00Z', 570), // Australia/Adelaide
  (570, DstRule.au, '2027-10-02T16:00:00Z', 570), // Australia/Adelaide
  (570, DstRule.au, '2027-10-02T17:00:00Z', 630), // Australia/Adelaide
  (570, DstRule.au, '2028-04-01T16:00:00Z', 630), // Australia/Adelaide
  (570, DstRule.au, '2028-04-01T17:00:00Z', 570), // Australia/Adelaide
  (570, DstRule.au, '2028-09-30T16:00:00Z', 570), // Australia/Adelaide
  (570, DstRule.au, '2028-09-30T17:00:00Z', 630), // Australia/Adelaide
  (570, DstRule.au, '2026-01-15T12:00:00Z', 630), // Australia/Adelaide
  (570, DstRule.au, '2026-07-15T12:00:00Z', 570), // Australia/Adelaide
  (570, DstRule.au, '2027-01-15T12:00:00Z', 630), // Australia/Adelaide
  (570, DstRule.au, '2027-07-15T12:00:00Z', 570), // Australia/Adelaide
  (570, DstRule.au, '2028-01-15T12:00:00Z', 630), // Australia/Adelaide
  (570, DstRule.au, '2028-07-15T12:00:00Z', 570), // Australia/Adelaide
  (120, DstRule.egypt, '2026-04-23T21:00:00Z', 120), // Africa/Cairo
  (120, DstRule.egypt, '2026-04-23T22:00:00Z', 180), // Africa/Cairo
  (120, DstRule.egypt, '2026-10-29T20:00:00Z', 180), // Africa/Cairo
  (120, DstRule.egypt, '2026-10-29T21:00:00Z', 120), // Africa/Cairo
  (120, DstRule.egypt, '2027-04-29T21:00:00Z', 120), // Africa/Cairo
  (120, DstRule.egypt, '2027-04-29T22:00:00Z', 180), // Africa/Cairo
  (120, DstRule.egypt, '2027-10-28T20:00:00Z', 180), // Africa/Cairo
  (120, DstRule.egypt, '2027-10-28T21:00:00Z', 120), // Africa/Cairo
  (120, DstRule.egypt, '2028-04-27T21:00:00Z', 120), // Africa/Cairo
  (120, DstRule.egypt, '2028-04-27T22:00:00Z', 180), // Africa/Cairo
  (120, DstRule.egypt, '2028-10-26T20:00:00Z', 180), // Africa/Cairo
  (120, DstRule.egypt, '2028-10-26T21:00:00Z', 120), // Africa/Cairo
  (120, DstRule.egypt, '2026-01-15T12:00:00Z', 120), // Africa/Cairo
  (120, DstRule.egypt, '2026-07-15T12:00:00Z', 180), // Africa/Cairo
  (120, DstRule.egypt, '2027-01-15T12:00:00Z', 120), // Africa/Cairo
  (120, DstRule.egypt, '2027-07-15T12:00:00Z', 180), // Africa/Cairo
  (120, DstRule.egypt, '2028-01-15T12:00:00Z', 120), // Africa/Cairo
  (120, DstRule.egypt, '2028-07-15T12:00:00Z', 180), // Africa/Cairo
  (180, DstRule.none, '2026-01-15T12:00:00Z', 180), // Asia/Amman
  (180, DstRule.none, '2026-07-15T12:00:00Z', 180), // Asia/Amman
  (180, DstRule.none, '2027-01-15T12:00:00Z', 180), // Asia/Amman
  (180, DstRule.none, '2027-07-15T12:00:00Z', 180), // Asia/Amman
  (180, DstRule.none, '2028-01-15T12:00:00Z', 180), // Asia/Amman
  (180, DstRule.none, '2028-07-15T12:00:00Z', 180), // Asia/Amman
  (210, DstRule.none, '2026-01-15T12:00:00Z', 210), // Asia/Tehran
  (210, DstRule.none, '2026-07-15T12:00:00Z', 210), // Asia/Tehran
  (210, DstRule.none, '2027-01-15T12:00:00Z', 210), // Asia/Tehran
  (210, DstRule.none, '2027-07-15T12:00:00Z', 210), // Asia/Tehran
  (210, DstRule.none, '2028-01-15T12:00:00Z', 210), // Asia/Tehran
  (210, DstRule.none, '2028-07-15T12:00:00Z', 210), // Asia/Tehran
];

/// Every directory city and its zone id (`rule|standard minutes`), derived
/// from the tz database; a change here is a deliberate decision.
const Map<String, String> _cityZones = <String, String>{
  'Makkah': 'none|180',
  'Madinah': 'none|180',
  'Riyadh': 'none|180',
  'Jeddah': 'none|180',
  'Dubai': 'none|240',
  'Doha': 'none|180',
  'Kuwait City': 'none|180',
  'Istanbul': 'none|180',
  'Cairo': 'egypt|120',
  'Amman': 'none|180',
  'Karachi': 'none|300',
  'Lahore': 'none|300',
  'Dhaka': 'none|360',
  'Jakarta': 'none|420',
  'Kuala Lumpur': 'none|480',
  'London': 'eu|0',
  'Birmingham': 'eu|0',
  'Toronto': 'us|-300',
  'New York': 'us|-300',
  'Chicago': 'us|-360',
  'Los Angeles': 'us|-480',
  'Sydney': 'au|600',
  'Lagos': 'none|60',
  'Nairobi': 'none|180',
  'Dammam': 'none|180',
  'Taif': 'none|180',
  'Tabuk': 'none|180',
  'Abha': 'none|180',
  'Muscat': 'none|240',
  'Manama': 'none|180',
  'Abu Dhabi': 'none|240',
  'Sharjah': 'none|240',
  'Al Ain': 'none|240',
  'Sanaa': 'none|180',
  'Aden': 'none|180',
  'Baghdad': 'none|180',
  'Basra': 'none|180',
  'Mosul': 'none|180',
  'Erbil': 'none|180',
  'Najaf': 'none|180',
  'Karbala': 'none|180',
  'Damascus': 'none|180',
  'Aleppo': 'none|180',
  'Ankara': 'none|180',
  'Izmir': 'none|180',
  'Bursa': 'none|180',
  'Konya': 'none|180',
  'Tehran': 'none|210',
  'Mashhad': 'none|210',
  'Isfahan': 'none|210',
  'Shiraz': 'none|210',
  'Qom': 'none|210',
  'Tabriz': 'none|210',
  'Alexandria': 'egypt|120',
  'Giza': 'egypt|120',
  'Luxor': 'egypt|120',
  'Algiers': 'none|60',
  'Tunis': 'none|60',
  'Tripoli': 'none|120',
  'Khartoum': 'none|120',
  'Nouakchott': 'none|0',
  'Dakar': 'none|0',
  'Accra': 'none|0',
  'Abidjan': 'none|0',
  'Kano': 'none|60',
  'Abuja': 'none|60',
  'Niamey': 'none|60',
  'Bamako': 'none|0',
  'Conakry': 'none|0',
  'Freetown': 'none|0',
  'N\'Djamena': 'none|60',
  'Addis Ababa': 'none|180',
  'Mogadishu': 'none|180',
  'Dar es Salaam': 'none|180',
  'Kampala': 'none|180',
  'Johannesburg': 'none|120',
  'Cape Town': 'none|120',
  'Durban': 'none|120',
  'Maputo': 'none|120',
  'Harare': 'none|120',
  'Djibouti': 'none|180',
  'Islamabad': 'none|300',
  'Rawalpindi': 'none|300',
  'Peshawar': 'none|300',
  'Faisalabad': 'none|300',
  'Multan': 'none|300',
  'Quetta': 'none|300',
  'Delhi': 'none|330',
  'Mumbai': 'none|330',
  'Hyderabad': 'none|330',
  'Kolkata': 'none|330',
  'Chennai': 'none|330',
  'Bengaluru': 'none|330',
  'Lucknow': 'none|330',
  'Chittagong': 'none|360',
  'Kabul': 'none|270',
  'Colombo': 'none|330',
  'Male': 'none|300',
  'Kathmandu': 'none|345',
  'Surabaya': 'none|420',
  'Bandung': 'none|420',
  'Medan': 'none|420',
  'Makassar': 'none|480',
  'Banda Aceh': 'none|420',
  'Singapore': 'none|480',
  'Bandar Seri Begawan': 'none|480',
  'George Town': 'none|480',
  'Manila': 'none|480',
  'Bangkok': 'none|420',
  'Tashkent': 'none|300',
  'Almaty': 'none|300',
  'Astana': 'none|300',
  'Baku': 'none|240',
  'Bishkek': 'none|360',
  'Dushanbe': 'none|300',
  'Ashgabat': 'none|300',
  'Moscow': 'none|180',
  'Kazan': 'none|180',
  'Grozny': 'none|180',
  'Makhachkala': 'none|180',
  'Ufa': 'none|300',
  'Paris': 'eu|60',
  'Marseille': 'eu|60',
  'Brussels': 'eu|60',
  'Amsterdam': 'eu|60',
  'Berlin': 'eu|60',
  'Frankfurt am Main': 'eu|60',
  'Cologne': 'eu|60',
  'Munich': 'eu|60',
  'Vienna': 'eu|60',
  'Zurich': 'eu|60',
  'Stockholm': 'eu|60',
  'Oslo': 'eu|60',
  'Tromso': 'eu|60',
  'Copenhagen': 'eu|60',
  'Helsinki': 'eu|120',
  'Madrid': 'eu|60',
  'Barcelona': 'eu|60',
  'Rome': 'eu|60',
  'Milan': 'eu|60',
  'Athens': 'eu|120',
  'Sarajevo': 'eu|60',
  'Pristina': 'eu|60',
  'Skopje': 'eu|60',
  'Tirana': 'eu|60',
  'Belgrade': 'eu|60',
  'Sofia': 'eu|120',
  'Bucharest': 'eu|120',
  'Warsaw': 'eu|60',
  'Dublin': 'eu|0',
  'Glasgow': 'eu|0',
  'Manchester': 'eu|0',
  'Leeds': 'eu|0',
  'Bradford': 'eu|0',
  'Leicester': 'eu|0',
  'Edinburgh': 'eu|0',
  'Cardiff': 'eu|0',
  'Lisbon': 'eu|0',
  'Kyiv': 'eu|120',
  'Reykjavik': 'none|0',
  'Houston': 'us|-360',
  'Dallas': 'us|-360',
  'Detroit': 'us|-300',
  'Washington': 'us|-300',
  'Atlanta': 'us|-300',
  'Boston': 'us|-300',
  'Philadelphia': 'us|-300',
  'Miami': 'us|-300',
  'San Francisco': 'us|-480',
  'San Diego': 'us|-480',
  'Seattle': 'us|-480',
  'Denver': 'us|-420',
  'Minneapolis': 'us|-360',
  'Phoenix': 'none|-420',
  'Honolulu': 'none|-600',
  'Montreal': 'us|-300',
  'Ottawa': 'us|-300',
  'Mississauga': 'us|-300',
  'Halifax': 'us|-240',
  'Mexico City': 'none|-360',
  'Sao Paulo': 'none|-180',
  'Buenos Aires': 'none|-180',
  'Bogota': 'none|-300',
  'Lima': 'none|-300',
  'Caracas': 'none|-240',
  'Port of Spain': 'none|-240',
  'Georgetown': 'none|-240',
  'Paramaribo': 'none|-180',
  'Kingston': 'none|-300',
  'Melbourne': 'au|600',
  'Canberra': 'au|600',
  'Adelaide': 'au|570',
  'Brisbane': 'none|600',
  'Perth': 'none|480',
  'Hobart': 'au|600',
};

void main() {
  group('city directory', () {
    test('has well over a hundred cities, each unique, with a zone', () {
      expect(CityDirectory.cities.length, greaterThan(150));
      final Set<String> seen = <String>{};
      for (final PrayerLocation c in CityDirectory.cities) {
        expect(seen.add('${c.city}|${c.country}'), isTrue, reason: c.city);
        expect(c.zone, isNotNull, reason: c.city);
        expect(c.latitude, inInclusiveRange(-90, 90), reason: c.city);
        expect(c.longitude, inInclusiveRange(-180, 180), reason: c.city);
      }
    });

    test('every city zone matches the tz database table', () {
      for (final PrayerLocation c in CityDirectory.cities) {
        expect(_cityZones.containsKey(c.city), isTrue, reason: '${c.city} missing');
        expect(c.zone!.id, _cityZones[c.city], reason: c.city);
      }
      expect(_cityZones.length, CityDirectory.cities.length);
    });

    test('the cities named in the audit are present', () {
      for (final String n in <String>[
        'Makkah', 'London', 'Jakarta', 'Dhaka', 'Sydney', 'Oslo', 'Toronto',
        'Baghdad', 'Damascus', 'Johannesburg', 'Sarajevo', 'Houston',
      ]) {
        expect(CityDirectory.filter(n).map((PrayerLocation c) => c.city), contains(n));
      }
    });

    test('Oslo is far enough north to need the high-latitude rule', () {
      expect(_city('Oslo').latitude, closeTo(59.91, 0.05));
      expect(_city('Oslo').longitude, closeTo(10.75, 0.05));
    });
  });

  group('daylight-saving rules against the tz database', () {
    test('offsets one hour either side of every change, 2026-2028', () {
      for (final (int, DstRule, String, int) r in _tzRows) {
        final PrayerZone z = PrayerZone(r.$1, r.$2);
        final DateTime u = DateTime.parse(r.$3);
        expect(
          z.offsetAtUtc(u).inMinutes,
          r.$4,
          reason: '${r.$1} ${r.$2.name} at ${r.$3}',
        );
      }
    });
  });

  group('regional default method', () {
    test('former mistakes: Amman, Baghdad and Damascus get the default, not Umm al-Qura or Tehran', () {
      expect(autoMethodFor(_city('Amman')), 'muslim_world_league');
      expect(autoMethodFor(_city('Baghdad')), 'muslim_world_league');
      expect(autoMethodFor(_city('Damascus')), 'muslim_world_league');
      expect(autoMethodFor(_city('Basra')), 'muslim_world_league');
      expect(autoMethodFor(_at(31.77, 35.21)), 'muslim_world_league'); // Jerusalem
    });

    test('Arabian Peninsula keeps Umm al-Qura, Gulf states their own', () {
      for (final String n in <String>[
        'Makkah', 'Madinah', 'Riyadh', 'Jeddah', 'Dammam', 'Taif', 'Tabuk',
        'Abha', 'Muscat', 'Manama', 'Sanaa', 'Aden',
      ]) {
        expect(autoMethodFor(_city(n)), 'umm_al_qura', reason: n);
      }
      expect(autoMethodFor(_at(30.97, 41.0)), 'umm_al_qura'); // Arar
      expect(autoMethodFor(_city('Doha')), 'qatar');
      expect(autoMethodFor(_city('Dubai')), 'dubai');
      expect(autoMethodFor(_city('Kuwait City')), 'kuwait');
    });

    test('Iran keeps Tehran, including its Gulf coast; its neighbours do not', () {
      for (final String n in <String>['Tehran', 'Mashhad', 'Isfahan', 'Shiraz', 'Tabriz']) {
        expect(autoMethodFor(_city(n)), 'tehran', reason: n);
      }
      expect(autoMethodFor(_at(31.32, 48.67)), 'tehran'); // Ahvaz
      expect(autoMethodFor(_city('Ashgabat')), 'muslim_world_league');
      expect(autoMethodFor(_at(41.7, 44.8)), 'muslim_world_league'); // Tbilisi
    });

    test('Turkey, Egypt, South Asia, South-East Asia, UK, North America', () {
      expect(autoMethodFor(_city('Ankara')), 'turkey');
      expect(autoMethodFor(_at(37.07, 37.38)), 'turkey'); // Gaziantep
      expect(autoMethodFor(_city('Alexandria')), 'egyptian');
      expect(autoMethodFor(_city('Delhi')), 'karachi');
      expect(autoMethodFor(_city('Dhaka')), 'karachi');
      expect(autoMethodFor(_city('Singapore')), 'singapore');
      expect(autoMethodFor(_city('Manchester')), 'moon_sighting_committee');
      expect(autoMethodFor(_city('Houston')), 'north_america');
      expect(autoMethodFor(_city('Oslo')), 'muslim_world_league');
    });
  });

  group('the label names the method that was used', () {
    test('automatic choice is shown, with its angles and the high-latitude rule', () {
      const PrayerSettings s = PrayerSettings();
      final String l = s.label(_city('Oslo'));
      expect(l, contains('Muslim World League (auto)'));
      expect(l, contains('Fajr 18'));
      expect(l, contains('seventh of the night'));
      final String t = s.label(_city('Toronto'));
      expect(t, contains('ISNA'));
      expect(t, contains('Fajr 15'));
      expect(t, isNot(contains('seventh')));
    });
  });

  group('on-device times against an independent calculation', () {
    for (final _Golden g in _golden) {
      test('${g.city} ${g.date}', () {
        final PrayerLocation loc = _city(g.city);
        final PrayerSettings settings = PrayerSettings(
          method: g.method,
          hanafiAsr: g.hanafi,
          highLatitude: g.highLat,
        );
        final AdhanCalcPrayerRepository repo =
            AdhanCalcPrayerRepository(settings: settings);
        final List<int> p = g.date.split('-').map(int.parse).toList();
        // Midday on that civil day in the city's own zone, as a real instant.
        final DateTime noon = PrayerZone.instantOf(
          loc.zone,
          DateTime(p[0], p[1], p[2], 12),
        );
        final PrayerTimes t = repo.timingsAt(loc, noon);
        int m(DateTime d) => d.hour * 60 + d.minute;
        void near(String name, DateTime got, int want, int tol) {
          int diff = (m(got) - want).abs();
          diff = diff > 720 ? 1440 - diff : diff; // across midnight
          expect(diff, lessThanOrEqualTo(tol),
              reason: '${g.city} ${g.date} $name: app ${m(got)} min, independent $want min');
        }
        near('fajr', t.fajr, g.fajr, 2);
        near('sunrise', t.sunrise, g.sunrise, 2);
        near('dhuhr', t.dhuhr, g.dhuhr, 2);
        near('asr', t.asr, g.asr, 3);
        near('maghrib', t.maghrib, g.maghrib, 2);
        near('isha', t.isha, g.isha, 2);
      });
    }
  });
}
