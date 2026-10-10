import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';

class Mosque {
  final String name;
  final double lat, lon;
  final String? addr, website, phone, denomination, hours;
  final bool wheelchair;
  const Mosque({required this.name, required this.lat, required this.lon,
      this.addr, this.website, this.phone, this.denomination, this.hours,
      this.wheelchair = false});
}

double _dist(double a1, double o1, double a2, double o2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLa = rad(a2 - a1), dLo = rad(o2 - o1);
  final h = math.sin(dLa / 2) * math.sin(dLa / 2) +
      math.cos(rad(a1)) * math.cos(rad(a2)) *
          math.sin(dLo / 2) * math.sin(dLo / 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// MASAJID + TAYYIB - the community finders, per the locked design docs:
/// night map, gold pins, distance-sorted list, rich profiles from OSM,
/// honest confidence labels. Verification posts arrive with the family cloud.
class MasjidFinderScreen extends StatefulWidget {
  const MasjidFinderScreen({super.key});

  @override
  State<MasjidFinderScreen> createState() => _MasjidState();
}

class _MasjidState extends State<MasjidFinderScreen> {
  final _map = MapController();
  final _search = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Mosque> _mosques = [];
  List<Map<String, dynamic>> _foods = [];
  double _lat = 43.65, _lon = -79.38; // Toronto default until GPS grants
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        _lat = pos.latitude; _lon = pos.longitude;
      }
    } catch (_) {}
    await _fetch();
  }

  Future<void> _searchCity() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/search?q='
          '${Uri.encodeComponent(q)}&format=json&limit=1'));
      final list = json.decode(res.body) as List<dynamic>;
      if (list.isNotEmpty) {
        _lat = double.parse(list[0]['lat']);
        _lon = double.parse(list[0]['lon']);
        await _fetch();
        return;
      }
      setState(() => _error = 'Place not found');
    } catch (_) {
      setState(() => _error = 'Search failed - check connection');
    }
    setState(() => _loading = false);
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    final foodMode = _tab == 1;
    final tag = foodMode
        ? 'nwr["diet:halal"="yes"](around:6000,$_lat,$_lon);'
        : '(nwr["amenity"="place_of_worship"]["religion"="muslim"](around:6000,$_lat,$_lon););';
    final query = '[out:json][timeout:25];$tag out center 50;';
    try {
      final res = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));
      final data = json.decode(res.body) as Map<String, dynamic>;
      final els = (data['elements'] as List<dynamic>? ?? []);
      if (!foodMode) {
        final out = <Mosque>[];
        for (final e in els) {
          final m = e as Map<String, dynamic>;
          final tags = (m['tags'] as Map?)?.cast<String, dynamic>() ?? {};
          final lat = (m['lat'] ?? (m['center'] as Map?)?['lat']) as double?;
          final lon = (m['lon'] ?? (m['center'] as Map?)?['lon']) as double?;
          if (lat == null || lon == null) continue;
          String? addr = tags['addr:street'] != null
              ? '${tags['addr:housenumber'] ?? ''} ${tags['addr:street']}, '
                  '${tags['addr:city'] ?? ''}'.trim()
              : null;
          out.add(Mosque(
            name: tags['name'] ?? 'Masjid',
            lat: lat, lon: lon,
            addr: addr?.isEmpty == true ? null : addr,
            website: tags['website'] ?? tags['contact:website'],
            phone: tags['phone'] ?? tags['contact:phone'],
            denomination: tags['denomination'],
            hours: tags['opening_hours'],
            wheelchair: tags['wheelchair'] == 'yes',
          ));
        }
        out.sort((a, b) => _dist(_lat, _lon, a.lat, a.lon)
            .compareTo(_dist(_lat, _lon, b.lat, b.lon)));
        _mosques = out;
      } else {
        _foods = els.map((e) {
          final m = (e as Map)['tags'] as Map? ?? {};
          final lat = ((e)['lat'] ?? (e)['center']?['lat']);
          final lon = ((e)['lon'] ?? (e)['center']?['lon']);
          return <String, dynamic>{
            'name': m['name'] ?? 'Restaurant', 'lat': lat, 'lon': lon,
            'cuisine': m['cuisine'], 'addr': m['addr:street'],
            'phone': m['phone'], 'website': m['website'],
          };
        }).toList();
      }
      _map.move(LatLng(_lat, _lon), 14);
    } catch (_) {
      _error = 'Live search failed - check connection';
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
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
                  Expanded(child: GestureDetector(
                    onTap: () { setState(() => _tab = i); _fetch(); },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
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
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _search,
                  style: AppText.body,
                  decoration: const InputDecoration(
                      hintText: 'Search a city or area\u2026'),
                  onSubmitted: (_) => _searchCity(),
                )),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search, color: AppColors.gold),
                  onPressed: _searchCity,
                ),
                IconButton(
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
                      initialCenter: LatLng(_lat, _lon),
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.arrayaan.app',
                      ),
                      MarkerLayer(markers: [
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
                              child: const Icon(Icons.mosque,
                                  color: AppColors.goldLight, size: 22),
                            ),
                      ]),
                    ],
                  ),
                ),
              ),
            )),
            if (_loading)
              const Padding(padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(color: AppColors.gold)),
            if (_error != null)
              Padding(padding: const EdgeInsets.all(8),
                  child: Text(_error!, style: AppText.bodyMuted)),
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
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
                                style: AppText.bodyMuted.copyWith(fontSize: 11.5)),
                            const SizedBox(height: 4),
                            Text('Halal tag: from community map data \u2014 '
                                'confirm before eating, in shaa Allah',
                                style: AppText.bodyMuted.copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                  if (_tab == 0 && _mosques.isEmpty && !_loading)
                    GlassCard(child: Text(
                        'No masajid found in this area\u2019s open map data. Try a nearby city search, or contribute the mosque to OpenStreetMap so the whole ummah finds it.',
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

class _MosqueCard extends StatelessWidget {
  final Mosque m;
  final double fromLat, fromLon;
  const _MosqueCard({required this.m, required this.fromLat, required this.fromLon});

  @override
  Widget build(BuildContext context) {
    final d = _dist(fromLat, fromLon, m.lat, m.lon);
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
            Text(m.addr!, style: AppText.bodyMuted.copyWith(fontSize: 11.5)),
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
            if (m.website != null)
              TextButton(
                onPressed: () => launchUrl(Uri.parse(m.website!),
                    mode: LaunchMode.externalApplication),
                child: const Text('Website', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
              ),
            if (m.phone != null)
              TextButton(
                onPressed: () => launchUrl(Uri.parse('tel:${m.phone}')),
                child: const Text('Call', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
              ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=${m.lat},${m.lon}'),
                  mode: LaunchMode.externalApplication),
              child: const Text('Directions', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
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
    child: Text(t, style: TextStyle(fontSize: 10, color: AppColors.sand)),
  );
}
