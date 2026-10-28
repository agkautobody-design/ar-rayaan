import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/core/safe_url.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../prayer/application/prayer_providers.dart';
import '../../share/application/share_service.dart';
import '../../share/presentation/share_actions.dart';
import '../../prayer/application/prayer_repository.dart';
import '../domain/masjid_search_service.dart';
import '../domain/masjid_search_state.dart';
import '../../../app/theme/widgets/focus_ring.dart';

double _dist(double a1, double o1, double a2, double o2) =>
    masjidDistanceMeters(a1, o1, a2, o2);

/// MASAJID + TAYYIB - the community finders, per the locked design docs:
/// night map, gold pins, distance-sorted list, rich profiles from OSM,
/// honest confidence labels. Verification posts arrive with the family cloud.
class MasjidFinderScreen extends ConsumerStatefulWidget {
  const MasjidFinderScreen({super.key});

  @override
  ConsumerState<MasjidFinderScreen> createState() => _MasjidState();
}

class _MasjidState extends ConsumerState<MasjidFinderScreen> {
  final _map = MapController();
  final _search = TextEditingController();
  bool _loading = false;
  String? _error;
  // True when the last network call (map search or city lookup) failed. Kept
  // apart from [_error] so a failure is never shown as "none found".
  bool _failed = false;
  // Short, reportable reason for the last failure; and whether the shown
  // results came from the Nominatim backup.
  String? _failReason;
  bool _usedBackup = false;
  final http.Client _client = http.Client();
  // What Retry repeats: the city lookup (true) or the map search (false).
  bool _retryIsCitySearch = false;
  List<Mosque> _mosques = [];
  List<Map<String, dynamic>> _foods = [];
  // Starts at the location saved for Prayer Times (GPS fix or chosen city).
  late double _lat, _lon;
  int _tab = 0;
  int _requestId = 0; // newest request wins; older answers are dropped

  // False until the person sets a place (their saved location, a device fix
  // they asked for, or a city they searched). Nothing is searched, and no
  // permission is requested, before that.
  bool _hasPlace = false;

  @override
  void initState() {
    super.initState();
    final PrayerLocation saved = ref.read(prayerLocationProvider);
    _lat = saved.latitude;
    _lon = saved.longitude;
    // Only a location the person set is used. The app's stand-in is never
    // searched, and the device is asked only when the person taps the
    // "Use my location" button.
    _hasPlace = saved.isSet;
    // Deferred a microtask so the first frame is not built while loading.
    if (_hasPlace) scheduleMicrotask(_fetch);
  }

  Future<void> _locate() async {
    var got = false;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 25));
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition()
            .timeout(const Duration(seconds: 25));
        _lat = pos.latitude;
        _lon = pos.longitude;
        got = true;
        if (!mounted) return;
      }
    } catch (_) {}
    if (!mounted) return;
    if (got) {
      _hasPlace = true;
      await _fetch();
      return;
    }
    setState(() => _error = _hasPlace
        ? 'Could not get your location - showing your last place'
        : 'Could not get your location - search a city instead');
    if (_hasPlace) await _fetch();
  }

  Future<void> _searchCity() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _failed = false;
      _failReason = null;
    });
    try {
      final res = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/search?q='
          '${Uri.encodeComponent(q)}&format=json&limit=1'))
          .timeout(const Duration(seconds: 10));
      final list = json.decode(res.body) as List<dynamic>;
      if (list.isNotEmpty) {
        _lat = double.parse(list[0]['lat'] as String);
        _lon = double.parse(list[0]['lon'] as String);
        _hasPlace = true;
        await _fetch();
        return;
      }
      if (!mounted) return;
      setState(() => _error = 'Place not found');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _retryIsCitySearch = true;
        _failReason = e is TimeoutException ? 'timed out' : 'place lookup failed';
      });
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _fetch() async {
    if (!_hasPlace) return; // no place yet: nothing to search
    final int id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _failed = false;
      _failReason = null;
      _usedBackup = false;
    });
    final bool foodMode = _tab == 1;
    try {
      final MapSearchOutcome out = await searchNearby(
        client: _client,
        lat: _lat,
        lon: _lon,
        food: foodMode,
      );
      if (!mounted || id != _requestId) return; // a newer search took over
      if (foodMode) {
        _foods = out.foods;
      } else {
        _mosques = out.mosques;
      }
      _usedBackup = out.fromBackup;
      try {
        _map.move(LatLng(_lat, _lon), 14);
      } catch (_) {
        // Map not laid out yet; the results still show.
      }
    } catch (e) {
      if (!mounted || id != _requestId) return;
      _failed = true;
      _retryIsCitySearch = false;
      _failReason = e is MapSearchFailure ? e.reason : 'unexpected error';
    }
    if (!mounted || id != _requestId) return;
    setState(() => _loading = false);
  }

  Future<void> _openMapSearch(bool food) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Opening your map\u2026')));
    // launchUrl is called straight from the tap, before any await, so the
    // browser does not treat it as a blocked pop-up.
    bool ok = await _openExternal(
      masjidFallbackMapUri(lat: _lat, lon: _lon, food: food),
      external: !kIsWeb,
    );
    if (!ok && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      ok = await _openExternal(
        masjidGeoUri(lat: _lat, lon: _lon, food: food),
      );
    }
    if (!ok) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'This device would not open the map. Check your connection or '
            'try a browser.',
          ),
        ),
      );
    }
  }

  void _retrySearch() {
    if (_retryIsCitySearch) {
      _searchCity();
    } else {
      _fetch();
    }
  }

  @override
  void dispose() {
    _client.close();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool food = _tab == 1;
    final MasjidPhase phase = masjidPhaseFor(
      hasPlace: _hasPlace,
      loading: _loading,
      failed: _failed,
      resultCount: food ? _foods.length : _mosques.length,
    );
    final String? status = masjidStatusText(phase, food: food);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(children: [
            ScreenHeader(title: _tab == 0 ? 'Masajid' : 'Tayyib Food', close: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                for (var i = 0; i < 2; i++)
                  Expanded(child: FocusableTap(
                    onTap: () { setState(() => _tab = i); _fetch(); },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _tab == i
                            ? AppColors.gold : AppColors.sand.withValues(alpha: 0.2)),
                      ),
                      child: Text(i == 0 ? 'Masajid' : 'Halal Food',
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                              fontSize: 12.5,
                              color: _tab == i ? AppColors.goldLight : AppColors.sand)),
                    ),
                  )),
              ]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Privacy: searching sends your approximate location to '
                'OpenStreetMap services (Overpass, with Nominatim as a backup, and '
                'map tiles).',
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: Semantics(label: 'Search a city or area\u2026', child: TextField(
                  controller: _search,
                  style: AppText.body,
                  decoration: const InputDecoration(
                      hintText: 'Search a city or area\u2026'),
                  onSubmitted: (_) => _searchCity(),
                ))),
                const SizedBox(width: 8),
                IconButton(tooltip: 'Search this place',
                  icon: const Icon(Icons.search, color: AppColors.gold),
                  onPressed: _searchCity,
                ),
                IconButton(tooltip: 'Use my location',
                  icon: const Icon(Icons.my_location, color: AppColors.gold),
                  onPressed: _locate,
                ),
              ]),
            ),
            Expanded(child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                      Color(0xB305090F), BlendMode.darken),
                  child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      // Before a place is set, a world view (not a guessed city).
                      initialCenter: _hasPlace
                          ? LatLng(_lat, _lon)
                          : const LatLng(21.4225, 39.8262),
                      initialZoom: _hasPlace ? 13 : 2,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.arrayaan.app',
                      ),
                      // Required by the OpenStreetMap tile and data licence.
                      const SimpleAttributionWidget(
                        source: Text('OpenStreetMap contributors'),
                      ),
                      MarkerLayer(markers: [
                        if (_hasPlace)
                          Marker(
                            point: LatLng(_lat, _lon),
                            child: const Icon(Icons.person_pin_circle,
                                color: Color(0xFFE8C96A), size: 30),
                          ),
                        for (final m in _tab == 0
                            ? _mosques
                                .map((m) => <String, dynamic>{
                                    'name': m.name, 'lat': m.lat, 'lon': m.lon})
                                .toList()
                            : _foods)
                          if (m['lat'] != null && m['lon'] != null)
                            Marker(
                              point: LatLng(m['lat'] as double, m['lon'] as double),
                              child: Icon(
                                  _tab == 0 ? Icons.mosque : Icons.restaurant,
                                  color: AppColors.goldLight, size: 22),
                            ),
                      ]),
                    ],
                  ),
                ),
              ),
            )),
            if (_error != null)
              Padding(padding: const EdgeInsets.all(8),
                  child: Text(_error!, style: AppText.bodyMuted)),
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (phase == MasjidPhase.loading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.gold),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(status ?? '', style: AppText.bodyMuted),
                        ),
                      ]),
                    ),
                  if (_failed && !_loading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                phase == MasjidPhase.failed
                                    ? status ?? ''
                                    : phase == MasjidPhase.needsPlace
                                        ? 'Could not look up that place. Check '
                                            'your connection and try again.'
                                        : 'Could not refresh from the map '
                                            'service. Showing the earlier '
                                            'results.',
                                style: AppText.bodyMuted.copyWith(height: 1.45),
                              ),
                            ),
                            if (_failReason != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Reason: $_failReason',
                                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 4, children: [
                              OutlinedButton.icon(
                                onPressed: _retrySearch,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Try again'),
                              ),
                              if (_hasPlace)
                                TextButton(
                                  onPressed: () => _openMapSearch(food),
                                  child: const Text('Open map search instead'),
                                ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  if (_usedBackup && !_loading &&
                      (_tab == 0 ? _mosques : _foods).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Showing results from a backup source - may be '
                        'incomplete.',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ),
                  if (_tab == 0)
                    for (final m in _mosques)
                      _MosqueCard(m: m, fromLat: _lat, fromLon: _lon)
                  else
                    for (final f in _foods)
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['name'] as String,
                                style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                            Text(f['cuisine'] != null
                                ? '${f['cuisine']} \u00b7 ' +
                                    '${(_dist(_lat, _lon, (f['lat'] ?? _lat) as double, (f['lon'] ?? _lon) as double) / 1000).toStringAsFixed(1)} km'
                                : '${(_dist(_lat, _lon, (f['lat'] ?? _lat) as double, (f['lon'] ?? _lon) as double) / 1000).toStringAsFixed(1)} km away',
                                style: AppText.bodyMuted.copyWith(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                                '${f['only'] == true ? 'Tagged fully halal' : 'Tagged halal'}'
                                ' in community map data \u2014 confirm before eating, in shaa Allah',
                                style: AppText.bodyMuted.copyWith(fontSize: 12)),
                            if (f['lat'] is double && f['lon'] is double)
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                // Name, cuisine, street, the "tagged halal,
                                // confirm before eating" line, an OSM link
                                // and the map credit. No distance or phone.
                                child: ShareButton(
                                  doc: ShareDoc.halalPlace(
                                    name: f['name'] as String,
                                    cuisine: f['cuisine']?.toString(),
                                    address: f['addr']?.toString(),
                                    lat: f['lat'] as double,
                                    lon: f['lon'] as double,
                                    fullyHalal: f['only'] == true,
                                  ),
                                  subject: 'this restaurant',
                                ),
                              ),
                          ],
                        ),
                      ),
                  if (!_hasPlace)
                    GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                            'Set a place to search: tap \u201cUse my location\u201d '
                            '(your device is asked only when you tap it) or search '
                            'a city above.',
                            style: AppText.bodyMuted))
                  else if (phase == MasjidPhase.empty)
                    GlassCard(child: Text(status ?? '',
                        style: AppText.bodyMuted)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Opens [u] outside the app. A device with nothing to open it with, or a
/// browser that refuses, must not surface as an unhandled error.
Future<bool> _openExternal(Uri u, {bool external = true}) async {
  try {
    return await launchUrl(
      u,
      mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    return false;
  }
}

class _MosqueCard extends StatelessWidget {
  final Mosque m;
  final double fromLat, fromLon;
  const _MosqueCard({required this.m, required this.fromLat, required this.fromLon});

  @override
  Widget build(BuildContext context) {
    final d = _dist(fromLat, fromLon, m.lat, m.lon);
    // Website and phone are free text from OpenStreetMap: only a clean
    // http(s) address or a plain phone number is ever opened.
    final Uri? site = SafeUrl.web(m.website);
    final Uri? call = SafeUrl.tel(m.phone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(m.name,
                style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5))),
            Text('${(d / 1000).toStringAsFixed(1)} km',
                style: AppText.body.copyWith(color: AppColors.goldLight, fontSize: 12.5)),
          ]),
          if (m.addr != null)
            Text(m.addr!, style: AppText.bodyMuted.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: [
            if (m.denomination != null)
              _chip(m.denomination!),
            if (m.wheelchair) _chip('wheelchair access'),
            if (m.hours != null) _chip(m.hours!),
            _chip('from open map data \u2014 verify'),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            if (site != null)
              TextButton(
                onPressed: () => _openExternal(site),
                child: const Text('Website', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
              ),
            if (call != null)
              TextButton(
                onPressed: () => _openExternal(call, external: false),
                child: const Text('Call', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
              ),
            TextButton(
              onPressed: () => _openExternal(Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=${m.lat},${m.lon}')),
              child: const Text('Directions', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
            ),
            const Spacer(),
            // Name, address, an OpenStreetMap link to the place and the map
            // credit. No distance, phone, hours or anything about you.
            ShareButton(
              doc: ShareDoc.mosque(
                name: m.name,
                address: m.addr,
                lat: m.lat,
                lon: m.lon,
              ),
              subject: 'this masjid',
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
    ),
    child: Text(t, style: TextStyle(fontSize: 12, color: AppColors.sand)),
  );
}
