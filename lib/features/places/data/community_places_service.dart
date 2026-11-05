import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/community_place.dart';

/// A write the policy refused before it left the device, or that needs a
/// signed-in account first. [message] is safe to show to the person.
class PlacesRejected implements Exception {
  const PlacesRejected(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Community places and events — public read, account-only write.
///
/// Submissions appear at once, labelled "unverified". Firestore rules
/// enforce the real-account requirement, field shapes, server timestamps,
/// a 60-second gap between submissions and the block list; this service
/// mirrors them so the person gets a clear message first.
class CommunityPlacesService {
  CommunityPlacesService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _places =>
      _db.collection('community_places');
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('community_events');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('place_reports');
  DocumentReference<Map<String, dynamic>> _rateDoc(String uid) =>
      _db.collection('places_rate').doc(uid);

  /// Most recent submissions kept; the screens filter by distance.
  static const int placesLimit = 200;
  static const int eventsLimit = 100;
  static const int reportsLimit = 100;

  // ---- reads -------------------------------------------------------------

  /// Newest community places, whatever their state — the screens decide
  /// what to show ([PlacesPolicy.visible], [PlacesPolicy.nearby]).
  Stream<List<CommunityPlace>> places() => _places
      .orderBy('createdAt', descending: true)
      .limit(placesLimit)
      .snapshots()
      .map((s) => s.docs.map(CommunityPlace.fromDoc).toList());

  /// Events that have not ended (the day after the start still shows).
  Stream<List<CommunityEvent>> events() {
    final DateTime cutoff =
        DateTime.now().subtract(PlacesPolicy.eventGrace);
    return _events
        .where('startsAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('startsAt')
        .limit(eventsLimit)
        .snapshots()
        .map((s) => s.docs.map(CommunityEvent.fromDoc).toList());
  }

  /// Reports queue — readable by founders only (the rules say so).
  Stream<QuerySnapshot<Map<String, dynamic>>> reports() => _reports
      .orderBy('createdAt', descending: true)
      .limit(reportsLimit)
      .snapshots();

  /// True when the signed-in account has a founder document (created in the
  /// Firebase console by hand — never from the app).
  Future<bool> isFounder() async {
    final User? u = _auth.currentUser;
    if (u == null || u.isAnonymous) return false;
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection('founders').doc(u.uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // ---- writes --------------------------------------------------------------

  /// Submissions need a real account: anonymous sign-ins do not count, so
  /// abuse can be tied to an account and blocked.
  User _requireAccount() {
    final User? u = _auth.currentUser;
    if (u == null || u.isAnonymous) {
      throw const PlacesRejected(
        'Sign in with an account to add to the map — this keeps the map '
        'honest. Your account is never shown with what you add.',
      );
    }
    return u;
  }

  static const String _recentKey = 'ar.places.recent';

  Future<List<DateTime>> _recentWrites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_recentKey) ?? const <String>[])
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .toList();
    } catch (_) {
      return <DateTime>[];
    }
  }

  Future<void> _checkAllowedToWrite() async {
    final Duration? wait =
        PlacesPolicy.waitBeforeNextWrite(await _recentWrites(), DateTime.now());
    if (wait != null) {
      throw PlacesRejected(
        'Please wait ${wait.inSeconds + 1} seconds before adding again.',
      );
    }
  }

  Future<void> _noteWrite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final DateTime hourAgo =
          DateTime.now().subtract(const Duration(hours: 1));
      final Iterable<DateTime> kept =
          (await _recentWrites()).where((t) => t.isAfter(hourAgo));
      await prefs.setStringList(
        _recentKey,
        <String>[
          ...kept.map((t) => t.toIso8601String()),
          DateTime.now().toIso8601String(),
        ],
      );
    } catch (_) {}
  }

  static String? _clean(String? s) {
    final String t = (s ?? '').trim();
    return t.isEmpty ? null : t;
  }

  /// Adds a mosque or halal-food place. It appears immediately with an
  /// "unverified" label.
  Future<String> submitPlace({
    required CommunityPlaceType type,
    required String name,
    required double lat,
    required double lon,
    String? address,
    String? phone,
    String? website,
    String? note,
  }) async {
    final String? problem = PlacesPolicy.validatePlace(
      name: name,
      lat: lat,
      lon: lon,
      address: address,
      phone: phone,
      website: website,
      note: note,
    );
    if (problem != null) throw PlacesRejected(problem);
    await _checkAllowedToWrite();
    final User u = _requireAccount();
    final DocumentReference<Map<String, dynamic>> ref = _places.doc();
    final WriteBatch batch = _db.batch();
    batch.set(ref, <String, dynamic>{
      'type': type == CommunityPlaceType.halalFood ? 'halal_food' : 'mosque',
      'name': name.trim(),
      'lat': lat,
      'lon': lon,
      if (_clean(address) != null) 'address': _clean(address),
      if (_clean(phone) != null) 'phone': _clean(phone),
      if (_clean(website) != null) 'website': _clean(website),
      if (_clean(note) != null) 'note': _clean(note),
      'uid': u.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'confirms': 0,
      'flags': 0,
      'hidden': false,
    });
    batch.set(_rateDoc(u.uid), <String, dynamic>{
      'lastWriteAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await _noteWrite();
    return ref.id;
  }

  /// Adds a community event. It shows until a day after it starts.
  Future<String> submitEvent({
    required String title,
    required String where,
    required double lat,
    required double lon,
    required DateTime startsAt,
    String? details,
  }) async {
    final String? problem = PlacesPolicy.validateEvent(
      title: title,
      where: where,
      lat: lat,
      lon: lon,
      startsAt: startsAt,
      details: details,
    );
    if (problem != null) throw PlacesRejected(problem);
    await _checkAllowedToWrite();
    final User u = _requireAccount();
    final DocumentReference<Map<String, dynamic>> ref = _events.doc();
    final WriteBatch batch = _db.batch();
    batch.set(ref, <String, dynamic>{
      'title': title.trim(),
      'where': where.trim(),
      'lat': lat,
      'lon': lon,
      'startsAt': Timestamp.fromDate(startsAt),
      if (_clean(details) != null) 'details': _clean(details),
      'uid': u.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'hidden': false,
    });
    batch.set(_rateDoc(u.uid), <String, dynamic>{
      'lastWriteAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await _noteWrite();
    return ref.id;
  }

  /// "Still correct" ([kind] = confirm) or "there is a problem"
  /// ([kind] = flag). One vote per person per place; voting again switches
  /// it. The place's counters move in the same transaction, as the rules
  /// require.
  Future<void> vote({
    required String placeId,
    required String kind,
  }) async {
    if (kind != 'confirm' && kind != 'flag') {
      throw const PlacesRejected('Unknown vote.');
    }
    final User u = _requireAccount();
    final DocumentReference<Map<String, dynamic>> placeRef =
        _places.doc(placeId);
    final DocumentReference<Map<String, dynamic>> voteRef =
        placeRef.collection('votes').doc(u.uid);
    await _db.runTransaction((tx) async {
      final DocumentSnapshot<Map<String, dynamic>> voteSnap =
          await tx.get(voteRef);
      final String? old = voteSnap.data()?['kind'] as String?;
      if (old == kind) return; // tapping the same vote again changes nothing
      int dConfirms = 0, dFlags = 0;
      if (old == 'confirm') dConfirms -= 1;
      if (old == 'flag') dFlags -= 1;
      if (kind == 'confirm') dConfirms += 1;
      if (kind == 'flag') dFlags += 1;
      tx.set(voteRef, <String, dynamic>{
        'kind': kind,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(placeRef, <String, dynamic>{
        'confirms': FieldValue.increment(dConfirms),
        'flags': FieldValue.increment(dFlags),
      });
    });
  }

  /// Sends a correction or report. One per person per target (the document
  /// id enforces it). Only founders can read these.
  Future<void> report({
    required String targetType,
    required String targetId,
    required String name,
    required String reason,
    String? note,
  }) async {
    if (!PlacesPolicy.reportReasons.containsKey(reason)) {
      throw const PlacesRejected('Unknown reason.');
    }
    final String n = (note ?? '').trim();
    if (n.length > PlacesPolicy.reportNoteMax) {
      throw const PlacesRejected('Notes can be at most 300 characters.');
    }
    final User u = _requireAccount();
    await _reports.doc('${u.uid}_$targetId').set(<String, dynamic>{
      'targetType': targetType,
      'targetId': targetId,
      'name': name.trim(),
      'reason': reason,
      if (n.isNotEmpty) 'note': n,
      'uid': u.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---- founder only (the rules refuse anyone else) -------------------------

  Future<void> setPlaceHidden(String placeId, bool hidden) =>
      _places.doc(placeId).update(<String, dynamic>{'hidden': hidden});

  Future<void> deletePlace(String placeId) => _places.doc(placeId).delete();

  Future<void> setEventHidden(String eventId, bool hidden) =>
      _events.doc(eventId).update(<String, dynamic>{'hidden': hidden});

  Future<void> deleteEvent(String eventId) => _events.doc(eventId).delete();

  /// Blocks an account from submitting or voting. Their existing places are
  /// NOT removed automatically — hide or delete them from the list above.
  Future<void> blockUser(String uid) =>
      _db.collection('places_blocked').doc(uid).set(<String, dynamic>{
        'at': FieldValue.serverTimestamp(),
      });

  Future<void> unblockUser(String uid) =>
      _db.collection('places_blocked').doc(uid).delete();

  Stream<QuerySnapshot<Map<String, dynamic>>> blocked() =>
      _db.collection('places_blocked').snapshots();
}
