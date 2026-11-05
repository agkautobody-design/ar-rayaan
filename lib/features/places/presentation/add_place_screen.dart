import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../auth/application/auth_providers.dart';
import '../application/places_providers.dart';
import '../data/community_places_service.dart';
import '../domain/community_place.dart';

/// Add a mosque, a halal-food place or a community event to the map.
///
/// Only people signed in with an account can submit — the account is never
/// shown with what they add, it simply keeps the map honest. Submissions
/// appear immediately, labelled "unverified".
class AddPlaceScreen extends ConsumerStatefulWidget {
  const AddPlaceScreen({super.key, this.initialType = 'mosque', this.lat, this.lon});

  /// 'mosque', 'halal' or 'event'.
  final String initialType;

  /// The place the map was centred on, used as the pin unless the person
  /// taps "Use my location".
  final double? lat;
  final double? lon;

  @override
  ConsumerState<AddPlaceScreen> createState() => _AddPlaceState();
}

class _AddPlaceScreenState extends ConsumerState<AddPlaceScreen> {
  late String _type = switch (widget.initialType) {
    'halal' => 'halal',
    'event' => 'event',
    _ => 'mosque',
  };
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _note = TextEditingController();
  final _where = TextEditingController();
  final _details = TextEditingController();
  DateTime? _startsAt;
  double? _lat;
  double? _lon;
  bool _locating = false;
  bool _sending = false;

  bool get _isEvent => _type == 'event';

  @override
  void initState() {
    super.initState();
    _lat = widget.lat;
    _lon = widget.lon;
  }

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _name, _address, _phone, _website, _note, _where, _details,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
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
        if (!mounted) return;
        setState(() {
          _lat = pos.latitude;
          _lon = pos.longitude;
        });
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permission was not given.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not get your location. Search a city on the '
              'map screen first, then come back.')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickStart() async {
    final DateTime now = DateTime.now();
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(PlacesPolicy.maxEventAhead),
    );
    if (day == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _startsAt = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final CommunityPlacesService? svc =
        ref.read(communityPlacesServiceProvider);
    if (svc == null || _sending) return;
    setState(() => _sending = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      if (_isEvent) {
        await svc.submitEvent(
          title: _name.text,
          where: _where.text,
          lat: _lat ?? 0,
          lon: _lon ?? 0,
          startsAt: _startsAt ?? DateTime(2000),
          details: _details.text,
        );
      } else {
        await svc.submitPlace(
          type: _type == 'halal'
              ? CommunityPlaceType.halalFood
              : CommunityPlaceType.mosque,
          name: _name.text,
          lat: _lat ?? 0,
          lon: _lon ?? 0,
          address: _address.text,
          phone: _phone.text,
          website: _website.text,
          note: _note.text,
        );
      }
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
          content: Text('Added — jazakAllahu khairan. It shows as '
              '"unverified" until the community confirms it.')));
      Navigator.of(context).pop();
    } on PlacesRejected catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not add it. Check your connection and try '
              'again.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = ref.watch(communityPlacesEnabledProvider);
    final signedIn = ref.watch(authStateProvider).value != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(children: [
            const ScreenHeader(title: 'Add to the map', close: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  if (!enabled)
                    GlassCard(
                      child: Text(
                        'Community additions need the app\u2019s cloud, which '
                        'this build does not carry.',
                        style: AppText.bodyMuted.copyWith(height: 1.45),
                      ),
                    )
                  else if (!signedIn)
                    GlassCard(
                      key: const Key('add-place-signin'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in to add to the map',
                            style: AppText.body
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Only people with an account can add places and '
                            'events — this is what keeps the map honest. Your '
                            'account is never shown next to what you add.',
                            style: AppText.bodyMuted.copyWith(height: 1.45),
                          ),
                          const SizedBox(height: 10),
                          GoldButton(
                            label: 'Sign in',
                            trailing: const Icon(Icons.login, size: 18),
                            onPressed: () => context.open(AppRoutes.login),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _typePicker(),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field(_name,
                              key: 'add-place-name',
                              hint: _isEvent
                                  ? 'Event title'
                                  : _type == 'halal'
                                      ? 'Name of the place'
                                      : 'Name of the masjid'),
                          if (_isEvent) ...[
                            const SizedBox(height: 8),
                            _field(_where,
                                key: 'add-event-where',
                                hint: 'Where it happens'),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              key: const Key('add-event-when'),
                              onPressed: _pickStart,
                              icon: const Icon(Icons.event, size: 16),
                              label: Text(_startsAt == null
                                  ? 'Pick date and time'
                                  : DateFormat('EEE d MMM, HH:mm')
                                      .format(_startsAt!)),
                            ),
                            const SizedBox(height: 8),
                            _field(_details,
                                key: 'add-event-details',
                                hint: 'Details (optional)',
                                lines: 3),
                          ] else ...[
                            const SizedBox(height: 8),
                            _field(_address,
                                key: 'add-place-address',
                                hint: 'Address (optional)'),
                            const SizedBox(height: 8),
                            _field(_phone,
                                key: 'add-place-phone',
                                hint: 'Phone (optional)'),
                            const SizedBox(height: 8),
                            _field(_website,
                                key: 'add-place-website',
                                hint: 'Website, starting with https:// (optional)'),
                            const SizedBox(height: 8),
                            _field(_note,
                                key: 'add-place-note',
                                hint: _type == 'halal'
                                    ? 'A short note, e.g. "fully halal, '
                                        'owner-run" (optional)'
                                    : 'A short note, e.g. "jumuah 1:30pm" '
                                        '(optional)',
                                lines: 2),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: Row(children: [
                        Icon(
                          _lat != null
                              ? Icons.location_on
                              : Icons.location_off,
                          color: AppColors.goldLight,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lat != null
                                ? 'Pin set (${_lat!.toStringAsFixed(4)}, '
                                    '${_lon!.toStringAsFixed(4)})'
                                : 'No pin yet — the place needs its spot on '
                                    'the map.',
                            style: AppText.bodyMuted.copyWith(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          key: const Key('add-place-locate'),
                          onPressed: _locating ? null : _useMyLocation,
                          child: Text(
                            _locating ? 'Locating…' : 'Use my location',
                            style: const TextStyle(
                                color: AppColors.goldLight, fontSize: 12),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'It appears on the map straight away, labelled '
                      '\u201cunverified\u201d, until others confirm it. '
                      'Anything false or harmful can be reported and removed.',
                      style: AppText.bodyMuted
                          .copyWith(fontSize: 12, height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    GoldButton(
                      key: const Key('add-place-submit'),
                      label: _sending
                          ? 'Adding…'
                          : _isEvent
                              ? 'Add this event'
                              : 'Add this place',
                      trailing: const Icon(Icons.add_location_alt, size: 18),
                      onPressed: _sending ? null : _submit,
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _typePicker() {
    const List<(String, String)> types = <(String, String)>[
      ('mosque', 'Masjid'),
      ('halal', 'Halal food'),
      ('event', 'Event'),
    ];
    return Row(children: [
      for (final (String value, String label) in types)
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _type = value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _type == value
                      ? AppColors.gold
                      : AppColors.sand.withValues(alpha: 0.2),
                ),
              ),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                      fontSize: 12.5,
                      color: _type == value
                          ? AppColors.goldLight
                          : AppColors.sand)),
            ),
          ),
        ),
    ]);
  }

  Widget _field(TextEditingController c,
      {required String key, required String hint, int lines = 1}) {
    return Semantics(
      label: hint,
      child: TextField(
        key: Key(key),
        controller: c,
        style: AppText.body,
        maxLines: lines,
        maxLength: 300,
        decoration: InputDecoration(hintText: hint, counterText: ''),
      ),
    );
  }
}
