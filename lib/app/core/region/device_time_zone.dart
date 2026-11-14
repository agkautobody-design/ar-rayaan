import 'device_time_zone_stub.dart'
    if (dart.library.js_interop) 'device_time_zone_web.dart';

/// The device's IANA time zone ("America/Toronto"), or null where it cannot
/// be read (the phone apps, which use the device region instead).
String? deviceTimeZone() {
  try {
    return platformTimeZone();
  } catch (_) {
    return null;
  }
}

/// The country a time zone belongs to, for the countries whose help lines
/// the app lists. Null for anything else (the device language decides).
///
/// A browser's language is often "en-US" whatever country the person is in,
/// so on the web the time zone is the better guess: someone in Toronto was
/// shown United States help lines.
String? countryForTimeZone(String? tz) {
  if (tz == null || tz.isEmpty) return null;
  final String? exact = _exact[tz];
  if (exact != null) return exact;
  if (tz.startsWith('Australia/')) return 'AU';
  return null;
}

/// The time zone's country, or null.
String? deviceTimeZoneCountry() => countryForTimeZone(deviceTimeZone());

const Map<String, String> _exact = <String, String>{
  // Canada
  'America/Toronto': 'CA', 'America/Montreal': 'CA', 'America/Vancouver': 'CA',
  'America/Edmonton': 'CA', 'America/Winnipeg': 'CA', 'America/Halifax': 'CA',
  'America/St_Johns': 'CA', 'America/Regina': 'CA', 'America/Moncton': 'CA',
  'America/Whitehorse': 'CA', 'America/Yellowknife': 'CA',
  'America/Iqaluit': 'CA', 'America/Glace_Bay': 'CA', 'America/Goose_Bay': 'CA',
  'America/Swift_Current': 'CA', 'America/Dawson_Creek': 'CA',
  'America/Fort_Nelson': 'CA', 'America/Thunder_Bay': 'CA',
  'America/Nipigon': 'CA', 'America/Rainy_River': 'CA',
  'America/Rankin_Inlet': 'CA', 'America/Resolute': 'CA',
  'America/Cambridge_Bay': 'CA', 'America/Inuvik': 'CA',
  'America/Atikokan': 'CA', 'America/Blanc-Sablon': 'CA',
  'America/Creston': 'CA', 'America/Dawson': 'CA',
  // United States
  'America/New_York': 'US', 'America/Chicago': 'US', 'America/Denver': 'US',
  'America/Los_Angeles': 'US', 'America/Phoenix': 'US',
  'America/Anchorage': 'US', 'America/Detroit': 'US', 'America/Boise': 'US',
  'America/Indiana/Indianapolis': 'US', 'America/Kentucky/Louisville': 'US',
  'America/Juneau': 'US', 'America/Adak': 'US', 'America/Nome': 'US',
  'America/Sitka': 'US', 'America/Menominee': 'US', 'Pacific/Honolulu': 'US',
  // Europe
  'Europe/London': 'GB', 'Europe/Belfast': 'GB', 'Europe/Dublin': 'IE',
  'Europe/Istanbul': 'TR',
  // Oceania
  'Pacific/Auckland': 'NZ', 'Pacific/Chatham': 'NZ',
  // Middle East and Asia
  'Asia/Riyadh': 'SA', 'Asia/Dubai': 'AE', 'Asia/Qatar': 'QA',
  'Asia/Kuala_Lumpur': 'MY', 'Asia/Kuching': 'MY', 'Asia/Jakarta': 'ID',
  'Asia/Makassar': 'ID', 'Asia/Jayapura': 'ID', 'Asia/Pontianak': 'ID',
  'Asia/Karachi': 'PK', 'Asia/Dhaka': 'BD', 'Asia/Kolkata': 'IN',
  'Asia/Calcutta': 'IN',
  // Africa
  'Africa/Cairo': 'EG', 'Africa/Johannesburg': 'ZA', 'Africa/Lagos': 'NG',
};
