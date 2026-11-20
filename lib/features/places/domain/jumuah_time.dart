/// Jumu'ah (Friday prayer) times shown on masjid results.
///
/// Two sources, never mixed up:
///  * the OpenStreetMap `service_times` tag, when a mapper filled it in
///    (shown as written, labelled "from open map data");
///  * a time a signed-in person added from the app (labelled "added by a
///    community member"). Each person has one entry per masjid, so one
///    careless edit can never overwrite someone else's; the newest entry
///    is the one shown.
///
/// Nothing here guesses a time. A masjid with neither source shows
/// "not listed" and an Add button.
library;

/// One person's Jumu'ah time for one masjid.
class JumuahEntry {
  const JumuahEntry({
    required this.key,
    required this.text,
    required this.uid,
    this.createdAt,
  });

  /// The masjid: [PlacesPolicy.osmTargetId] for a map result, the place id
  /// for a community-added masjid.
  final String key;
  final String text;
  final String uid;
  final DateTime? createdAt;
}

class JumuahPolicy {
  const JumuahPolicy._();

  static const int textMax = 60;

  /// At least one clock time: 1:15, 13:15, 1pm, 1:15 PM.
  static final RegExp _clock = RegExp(
    r'(\b[01]?\d|\b2[0-3]):[0-5]\d|\b(1[0-2]|[1-9])\s?(am|pm)\b',
    caseSensitive: false,
  );

  /// Letters, digits, spaces and the few marks a time list needs.
  static final RegExp _chars = RegExp(r"^[A-Za-z0-9 :.,&;/+()'\-]+$");

  /// Null when [text] may be submitted, otherwise a message to show.
  static String? validate(String text) {
    final String t = text.trim();
    if (t.isEmpty) return 'Type the Jumu’ah time, e.g. 1:30 PM.';
    if (t.length > textMax) {
      return 'Keep it to $textMax characters, e.g. 1:00 PM and 2:00 PM.';
    }
    if (!_chars.hasMatch(t)) {
      return 'Use only letters, numbers and : . , & - in the time.';
    }
    if (!_clock.hasMatch(t)) {
      return 'Include a clock time, e.g. 1:30 PM or 13:30.';
    }
    return null;
  }

  /// The Friday part of an OpenStreetMap `service_times` value, or null.
  /// The value is opening_hours style ("Fr 13:15; Su 10:00"); only the
  /// Friday rules are kept, as written.
  static String? fromServiceTimes(String? raw) {
    if (raw == null) return null;
    final List<String> friday = raw
        .split(';')
        .map((s) => s.trim())
        .where((s) => RegExp(r'^(Fr|Friday)\b').hasMatch(s))
        .toList();
    if (friday.isEmpty) return null;
    final String out = friday.join('; ');
    if (out.length > 80 || !_clock.hasMatch(out)) return null;
    return out;
  }

  /// Newest entry per masjid key.
  static Map<String, JumuahEntry> newestByKey(Iterable<JumuahEntry> all) {
    final Map<String, JumuahEntry> out = <String, JumuahEntry>{};
    for (final JumuahEntry e in all) {
      final JumuahEntry? cur = out[e.key];
      final DateTime a = e.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime b =
          cur?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (cur == null || a.isAfter(b)) out[e.key] = e;
    }
    return out;
  }
}
