/// Community-submitted places (masajid and halal food) and events.
///
/// Anyone can read them; only people signed in with a real account can add
/// them. Submissions appear immediately, labelled "unverified", and the
/// community itself keeps them honest: people confirm a place that is still
/// correct or flag one that is not, and a place flagged far more than it is
/// confirmed drops out of the public list on its own. The founder can hide
/// or remove anything from the moderation screen.
///
/// The authoritative limits live in `firestore.rules`; [PlacesPolicy]
/// mirrors them so people get a clear message instead of a silent
/// permission error.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../masjid/domain/masjid_search_service.dart';

/// What a community place is.
enum CommunityPlaceType { mosque, halalFood }

/// A mosque or halal-food place someone added from the app.
class CommunityPlace {
  const CommunityPlace({
    required this.id,
    required this.type,
    required this.name,
    required this.lat,
    required this.lon,
    required this.uid,
    this.address,
    this.phone,
    this.website,
    this.note,
    this.createdAt,
    this.confirms = 0,
    this.flags = 0,
    this.hidden = false,
  });

  final String id;
  final CommunityPlaceType type;
  final String name;
  final double lat;
  final double lon;
  final String uid;
  final String? address;
  final String? phone;
  final String? website;
  final String? note;
  final DateTime? createdAt;
  final int confirms;
  final int flags;
  final bool hidden;

  static CommunityPlace fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
    return CommunityPlace(
      id: doc.id,
      type: d['type'] == 'halal_food'
          ? CommunityPlaceType.halalFood
          : CommunityPlaceType.mosque,
      name: (d['name'] as String?) ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lon: (d['lon'] as num?)?.toDouble() ?? 0,
      uid: (d['uid'] as String?) ?? '',
      address: d['address'] as String?,
      phone: d['phone'] as String?,
      website: d['website'] as String?,
      note: d['note'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      confirms: (d['confirms'] as num?)?.toInt() ?? 0,
      flags: (d['flags'] as num?)?.toInt() ?? 0,
      hidden: d['hidden'] == true,
    );
  }
}

/// A community event pinned to a place: an iftar, a class, an open day.
class CommunityEvent {
  const CommunityEvent({
    required this.id,
    required this.title,
    required this.where,
    required this.lat,
    required this.lon,
    required this.startsAt,
    required this.uid,
    this.details,
    this.createdAt,
    this.hidden = false,
  });

  final String id;
  final String title;

  /// Where it happens, in words ("Small Heath Masjid, Birmingham").
  final String where;
  final double lat;
  final double lon;
  final DateTime startsAt;
  final String uid;
  final String? details;
  final DateTime? createdAt;
  final bool hidden;

  static CommunityEvent fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
    return CommunityEvent(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      where: (d['where'] as String?) ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lon: (d['lon'] as num?)?.toDouble() ?? 0,
      startsAt:
          (d['startsAt'] as Timestamp?)?.toDate() ?? DateTime(2000),
      uid: (d['uid'] as String?) ?? '',
      details: d['details'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      hidden: d['hidden'] == true,
    );
  }
}

/// Client-side rules, mirroring `firestore.rules`.
class PlacesPolicy {
  const PlacesPolicy._();

  static const int nameMin = 2;
  static const int nameMax = 80;
  static const int addressMax = 140;
  static const int phoneMax = 30;
  static const int websiteMax = 140;
  static const int noteMax = 200;
  static const int eventTitleMin = 4;
  static const int eventTitleMax = 100;
  static const int eventWhereMin = 2;
  static const int eventWhereMax = 100;
  static const int eventDetailsMax = 300;
  static const int reportNoteMax = 300;

  /// Minimum gap between two submissions by one person (rules enforce 60 s).
  static const Duration minGap = Duration(seconds: 65);

  /// At most this many submissions per rolling hour.
  static const int maxPerHour = 8;

  /// How far out an event may be planned.
  static const Duration maxEventAhead = Duration(days: 366);

  /// An event stays listed until a day after it starts.
  static const Duration eventGrace = Duration(days: 1);

  /// A place with at least this many flags, and more flags than confirms,
  /// drops out of the public list without any moderator having to act.
  static const int autoHideFlags = 3;

  /// Community places farther than this from the searched place are not
  /// merged into the nearby list.
  static const double nearbyRadiusMeters = 40000;

  /// Phone numbers may only contain digits, spaces and + ( ) -.
  static final RegExp phoneChars = RegExp(r'^[0-9+()\- ]+$');

  static final RegExp _webScheme = RegExp(r'^https?://', caseSensitive: false);

  /// Null when the place may be submitted, otherwise a message to show.
  static String? validatePlace({
    required String name,
    required double? lat,
    required double? lon,
    String? address,
    String? phone,
    String? website,
    String? note,
  }) {
    final String t = name.trim();
    if (t.length < nameMin) return 'Give the place its name.';
    if (t.length > nameMax) return 'Names can be at most $nameMax characters.';
    final String? pin = validatePin(lat, lon);
    if (pin != null) return pin;
    if (address != null && address.trim().length > addressMax) {
      return 'Addresses can be at most $addressMax characters.';
    }
    final String p = (phone ?? '').trim();
    if (p.isNotEmpty) {
      if (p.length > phoneMax) {
        return 'Phone numbers can be at most $phoneMax characters.';
      }
      if (!phoneChars.hasMatch(p)) {
        return 'Phone numbers can use digits, spaces and + ( ) - only.';
      }
    }
    final String w = (website ?? '').trim();
    if (w.isNotEmpty) {
      if (w.length > websiteMax) {
        return 'Website links can be at most $websiteMax characters.';
      }
      if (!_webScheme.hasMatch(w)) {
        return 'Website links must start with http:// or https://.';
      }
    }
    if (note != null && note.trim().length > noteMax) {
      return 'Notes can be at most $noteMax characters.';
    }
    return null;
  }

  /// Null when the pin is usable.
  static String? validatePin(double? lat, double? lon) {
    if (lat == null || lon == null) {
      return 'Set where the place is: use your location or search a city '
          'on the map screen first.';
    }
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      return 'That pin is not on the map. Please set the location again.';
    }
    return null;
  }

  /// Null when the event may be submitted, otherwise a message to show.
  static String? validateEvent({
    required String title,
    required String where,
    required double? lat,
    required double? lon,
    required DateTime? startsAt,
    String? details,
    DateTime? now,
  }) {
    final String t = title.trim();
    if (t.length < eventTitleMin) return 'Give the event a title.';
    if (t.length > eventTitleMax) {
      return 'Titles can be at most $eventTitleMax characters.';
    }
    final String w = where.trim();
    if (w.length < eventWhereMin) return 'Say where the event happens.';
    if (w.length > eventWhereMax) {
      return 'The place name can be at most $eventWhereMax characters.';
    }
    final String? pin = validatePin(lat, lon);
    if (pin != null) return pin;
    final DateTime n = now ?? DateTime.now();
    if (startsAt == null) return 'Pick when the event starts.';
    if (startsAt.isBefore(n.subtract(eventGrace))) {
      return 'That start time has already passed.';
    }
    if (startsAt.isAfter(n.add(maxEventAhead))) {
      return 'Events can be at most a year ahead.';
    }
    if (details != null && details.trim().length > eventDetailsMax) {
      return 'Details can be at most $eventDetailsMax characters.';
    }
    return null;
  }

  /// Report reasons, with the words the person sees.
  static const Map<String, String> reportReasons = <String, String>{
    'closed': 'Closed down or no longer there',
    'wrong_location': 'Shown in the wrong place',
    'not_halal': 'Not actually halal',
    'correction': 'Wrong name, hours or other detail',
    'spam': 'Spam or advertising',
    'inappropriate': 'Inappropriate or unsafe',
    'other': 'Something else',
  };

  /// Whether a place still shows in the public list.
  static bool visible(CommunityPlace p) {
    if (p.hidden) return false;
    return !(p.flags >= autoHideFlags && p.flags > p.confirms);
  }

  /// Whether an event still shows (not hidden, not over).
  static bool eventVisible(CommunityEvent e, {DateTime? now}) {
    if (e.hidden) return false;
    final DateTime n = now ?? DateTime.now();
    return e.startsAt.isAfter(n.subtract(eventGrace));
  }

  /// Community places of [type] near (lat, lon), nearest first.
  static List<CommunityPlace> nearby(
    Iterable<CommunityPlace> places, {
    required CommunityPlaceType type,
    required double lat,
    required double lon,
  }) {
    final List<CommunityPlace> out = places
        .where((p) =>
            p.type == type &&
            visible(p) &&
            masjidDistanceMeters(lat, lon, p.lat, p.lon) <= nearbyRadiusMeters)
        .toList();
    out.sort((a, b) => masjidDistanceMeters(lat, lon, a.lat, a.lon)
        .compareTo(masjidDistanceMeters(lat, lon, b.lat, b.lon)));
    return out;
  }

  /// Upcoming events, soonest first. When a place is set, anything farther
  /// than [nearbyRadiusMeters] is left out.
  static List<CommunityEvent> upcoming(
    Iterable<CommunityEvent> events, {
    double? lat,
    double? lon,
    DateTime? now,
  }) {
    final List<CommunityEvent> out = events.where((e) {
      if (!eventVisible(e, now: now)) return false;
      if (lat != null && lon != null) {
        return masjidDistanceMeters(lat, lon, e.lat, e.lon) <=
            nearbyRadiusMeters;
      }
      return true;
    }).toList();
    out.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return out;
  }

  /// Decides whether another submission is allowed given the times of the
  /// person's recent writes (most recent last). Null when allowed,
  /// otherwise how long to wait.
  static Duration? waitBeforeNextWrite(List<DateTime> recent, DateTime now) {
    if (recent.isNotEmpty) {
      final Duration sinceLast = now.difference(recent.last);
      if (sinceLast < minGap) return minGap - sinceLast;
    }
    final DateTime hourAgo = now.subtract(const Duration(hours: 1));
    final List<DateTime> inHour =
        recent.where((t) => t.isAfter(hourAgo)).toList()
          ..sort();
    if (inHour.length >= maxPerHour) {
      return inHour.first.add(const Duration(hours: 1)).difference(now);
    }
    return null;
  }

  /// The target id a report for an OpenStreetMap place uses, so one person
  /// can report a given map place only once. Safe for a Firestore doc id.
  static String osmTargetId(String name, double lat, double lon) {
    final String slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final String short =
        slug.length > 40 ? slug.substring(0, 40) : slug;
    return 'osm-$short-${lat.toStringAsFixed(3)}-${lon.toStringAsFixed(3)}';
  }
}
