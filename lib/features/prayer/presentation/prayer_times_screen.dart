import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/core/notifications/prayer_notification_scheduler.dart';
import '../../../app/core/notifications/web_notifier.dart';
import '../../../app/core/sound/sound_services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/iqamah_settings.dart';
import '../application/location_providers.dart';
import '../application/prayer_alerts.dart';
import '../application/prayer_log.dart';
import '../application/prayer_notification_plan.dart';
import '../application/prayer_providers.dart';
import '../application/prayer_repository.dart';
import '../application/prayer_settings.dart';
import '../data/aladhan_prayer_repository.dart';
import '../data/city_directory.dart';
import '../domain/prayer_times.dart';

/// Prayer Times — calculated on the device (adhan math), in the clock of
/// the chosen city. New screen designed within the locked system — pending
/// Founder approval.
class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  static const Map<String, IconData> _icons = <String, IconData>{
    'Fajr': Icons.nights_stay_outlined,
    'Sunrise': Icons.wb_twilight_outlined,
    'Dhuhr': Icons.wb_sunny_outlined,
    'Asr': Icons.light_mode_outlined,
    'Maghrib': Icons.brightness_4_outlined,
    'Isha': Icons.bedtime_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PrayerTimes> times = ref.watch(prayerTimesProvider);
    final DateTime now =
        ref.watch(nowTickerProvider).valueOrNull ?? DateTime.now();
    // Keeps OS notifications (when a platform scheduler is provided) in step.
    ref.watch(prayerNotificationSyncProvider);

    return ScenicScaffold.pattern(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Prayer Times'),
            Expanded(
              child: times.when(
                skipLoadingOnReload: true,
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (Object e, _) => _ErrorState(
                  message: e is PrayerTimesException
                      ? e.message
                      : 'Could not work out today\'s prayer times. Try again, or pick your city.',
                  onRetry: () => ref.invalidate(prayerTimesProvider),
                ),
                data: (PrayerTimes data) => _Schedule(data: data, now: now),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Schedule extends ConsumerStatefulWidget {
  const _Schedule({required this.data, required this.now});

  final PrayerTimes data;
  final DateTime now;

  @override
  ConsumerState<_Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends ConsumerState<_Schedule> {
  PrayerTimes get data => widget.data;
  DateTime get now => widget.now;

  /// A toggled prayer's time just arrived — fire the full alert once:
  /// in-app banner (via provider state), adhan sound, browser notification.
  void _onAlert(String? prayer) {
    if (prayer == null) return;
    ref
        .read(firedAlertsProvider.notifier)
        .markFired(alertKey(data.wallClock(now), prayer));
    ref.read(alertBannerProvider.notifier).show(prayer);
    ref.read(adhanServiceProvider.notifier).playAdhan();
    WebNotifier.show(
      'It is now $prayer time',
      '$prayer · ${data.locationLabel} — Ar-Rayaan',
    );
  }

  String _countdown(DateTime target) {
    final Duration d = target.difference(data.wallClock(now));
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    if (h > 0) return 'in ${h}h ${m}m';
    return 'in ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeAlertProvider, (_, String? next) => _onAlert(next));
    final (String nextName, DateTime nextTime) = data.nextPrayer(now);
    final bool adhanPlaying = ref.watch(adhanServiceProvider);
    final String? alert = ref.watch(alertBannerProvider);
    final IqamahSettings iqamah = ref.watch(iqamahProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // O-11: location — GPS or manual city, fully offline after choice.
        const _LocationCard(),
        const SizedBox(height: 16),
        if (alert != null) ...[
          GlassCard(
            strong: true,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'It is now $alert time',
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      ref.read(alertBannerProvider.notifier).dismiss(),
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.sand.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Hero: next prayer countdown
        GlassCard(
          strong: true,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            children: [
              Text('NEXT PRAYER', style: AppText.eyebrow),
              const SizedBox(height: 10),
              Text(
                nextName,
                style: AppText.displayMedium.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat.jm().format(nextTime),
                style: AppText.body.copyWith(
                  color: AppColors.goldLight,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _countdown(nextTime),
                  style: AppText.label.copyWith(color: AppColors.goldLight),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Adhan — real Mecca recording, plays on demand.
        GlassCard(
          onTap: () => ref.read(adhanServiceProvider.notifier).toggle(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  adhanPlaying
                      ? Icons.stop_circle_outlined
                      : Icons.play_arrow_rounded,
                  size: 18,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adhanPlaying ? 'Adhan playing…' : 'Listen to the Adhan',
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'The call to prayer · Masjid al-Haram',
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.volume_up_outlined,
                size: 16,
                color: AppColors.gold.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Full schedule
        GlassCard(
          child: Column(
            children: [
              for (int i = 0; i < data.ordered.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: AppColors.gold.withValues(alpha: 0.1),
                    indent: 64,
                  ),
                _PrayerRow(
                  name: data.ordered[i].$1,
                  time: data.ordered[i].$2,
                  icon:
                      PrayerTimesScreen._icons[data.ordered[i].$1] ??
                      Icons.schedule,
                  isNext: data.ordered[i].$1 == nextName,
                  iqamah: iqamah.iqamahFor(
                    data.ordered[i].$1,
                    data.ordered[i].$2,
                  ),
                  jumuah: data.ordered[i].$1 == 'Dhuhr' &&
                          data.dhuhr.weekday == DateTime.friday
                      ? iqamah.jumuahTime
                      : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tahajjud — the last third of the night (Bukhari 1145).
        GlassCard(
          child: Row(
            children: [
              const Text('🌌', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.wallClock(now).isBefore(data.fajr)
                          ? 'Tahajjud (tonight, until Fajr)'
                          : 'Tahajjud tonight',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'The last third of the night begins ${DateFormat.jm().format(data.lastThirdStartFor(now))} — '
                      '“Who calls upon Me that I may answer him?”',
                      style: AppText.bodyMuted.copyWith(
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PrayerLogCard(data: data, now: now),
        const SizedBox(height: 16),
        const _IqamahCard(),
        const SizedBox(height: 16),
        const _NotificationCard(),
        const SizedBox(height: 24),
        Text(
          '${data.locationLabel} · ${data.methodLabel}',
          style: AppText.bodyMuted.copyWith(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        if (data.zone != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Times are on the local clock of ${data.locationLabel}, '
              'not your device\u2019s.',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        Center(
          child: TextButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF0B1424),
              builder: (_) => const _MethodSheet(),
            ),
            icon: const Icon(Icons.tune, size: 14),
            label: const Text('Calculation method & Asr',
                style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'TIMES ARE APPROXIMATE · CONFIRM LOCALLY',
          style: AppText.eyebrow.copyWith(
            color: AppColors.gold.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PrayerRow extends ConsumerWidget {
  const _PrayerRow({
    required this.name,
    required this.time,
    required this.icon,
    required this.isNext,
    this.iqamah,
    this.jumuah,
  });

  final String name;
  final DateTime time;
  final IconData icon;
  final bool isNext;

  /// The mosque congregation time the user entered, if any.
  final DateTime? iqamah;

  /// Friday only: the Jumu'ah time the user entered (HH:mm).
  final String? jumuah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color nameColor = isNext
        ? AppColors.goldLight
        : AppColors.sand.withValues(alpha: 0.9);
    final bool alertable = PrayerAlertController.alertable.contains(name);
    final bool alertOn = ref.watch(
      prayerAlertsProvider.select((s) => s.contains(name)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNext
                  ? AppColors.gold.withValues(alpha: 0.18)
                  : AppColors.gold.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: isNext ? 0.5 : 0.2),
              ),
            ),
            child: Icon(icon, size: 17, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.body.copyWith(
                    color: nameColor,
                    fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (iqamah != null)
                  Text(
                    'Iqamah ${DateFormat.jm().format(iqamah!)}',
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
                if (jumuah != null)
                  Text(
                    "Jumu'ah $jumuah",
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          if (isNext)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'NEXT',
                style: AppText.eyebrow.copyWith(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: AppColors.goldLight,
                ),
              ),
            ),
          Text(
            DateFormat.jm().format(time),
            style: AppText.body.copyWith(
              color: nameColor,
              fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (alertable) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: alertOn
                  ? 'Turn off the $name alert'
                  : 'Turn on the $name alert',
              onPressed: () async {
                final PrayerNotificationScheduler scheduler = ref.read(
                  prayerNotificationSchedulerProvider,
                );
                await ref.read(prayerAlertsProvider.notifier).toggle(name);
                if (alertOn) return;
                // Turning an alert on is the moment to ask for permission.
                unawaited(WebNotifier.ensurePermission());
                if (scheduler.supported) {
                  unawaited(scheduler.requestPermission());
                }
              },
              icon: Icon(
                alertOn
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                size: 20,
                color: alertOn
                    ? AppColors.gold
                    : AppColors.sand.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// O-11 location card — GPS fix or manual city pick; persists across visits.
class _LocationCard extends ConsumerWidget {
  const _LocationCard();

  Future<void> _pickCity(BuildContext context, WidgetRef ref) async {
    final PrayerLocation? chosen = await showModalBottomSheet<PrayerLocation>(
      context: context,
      backgroundColor: AppColors.night,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          children: [
            Text('Choose your city', style: AppText.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Times are calculated on your device — no internet needed.',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final PrayerLocation c in CityDirectory.cities)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(c.city, style: AppText.body),
                subtitle: c.country.isEmpty
                    ? null
                    : Text(
                        c.country,
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      ),
                onTap: () => Navigator.of(ctx).pop(c),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      await ref
          .read(prayerLocationControllerProvider.notifier)
          .setLocation(chosen);
    }
  }

  Future<void> _useGps(WidgetRef ref) async {
    await ref.read(prayerLocationControllerProvider.notifier).useGps();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PrayerLocation loc = ref.watch(prayerLocationControllerProvider);
    final GpsStatus status = ref
        .read(prayerLocationControllerProvider.notifier)
        .gpsStatus;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.place_outlined,
            size: 18,
            color: AppColors.gold.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.country.isEmpty ? loc.city : loc.label,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (status == GpsStatus.denied)
                  Text(
                    'Location permission denied — pick your city instead',
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  )
                else if (status == GpsStatus.unavailable)
                  Text(
                    'Location is off on this device — pick your city instead',
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  )
                else if (status == GpsStatus.error)
                  Text(
                    'Could not get your location — pick your city instead',
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: status == GpsStatus.locating
                ? null
                : () => _useGps(ref),
            icon: const Icon(Icons.my_location, size: 14),
            label: Text(
              status == GpsStatus.locating ? 'Locating…' : 'GPS',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
          ),
          TextButton.icon(
            onPressed: () => _pickCity(context, ref),
            icon: const Icon(Icons.location_city, size: 14),
            label: const Text('City', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.gold.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppText.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: AppText.label.copyWith(color: AppColors.goldLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pick the calculation convention and the Asr school.
class _MethodSheet extends ConsumerWidget {
  const _MethodSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PrayerSettings settings = ref.watch(prayerSettingsProvider);
    final PrayerSettingsController ctrl =
        ref.read(prayerSettingsProvider.notifier);
    final PrayerLocation loc = ref.watch(prayerLocationProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: <Widget>[
            Text('ASR', style: AppText.eyebrow),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.hanafiAsr,
              onChanged: ctrl.setHanafiAsr,
              activeThumbColor: AppColors.gold,
              title: Text('Hanafi Asr', style: AppText.body),
              subtitle: Text(
                settings.hanafiAsr
                    ? 'Shadow twice the object\u2019s length (later Asr)'
                    : 'Standard: Shafi\u2019i, Maliki, Hanbali',
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text('CALCULATION METHOD', style: AppText.eyebrow),
            const SizedBox(height: 4),
            Text(
              'Your mosque\u2019s timetable is the reference — pick the method '
              'that matches it.',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
            for (final PrayerMethodOption m in kPrayerMethods)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => ctrl.setMethod(m.key),
                leading: Icon(
                  settings.method == m.key
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.gold,
                  size: 20,
                ),
                title: Text(m.label, style: AppText.body),
                subtitle: Text(
                  m.key == 'auto'
                      ? '${m.detail} — now: ${kPrayerMethods.firstWhere((PrayerMethodOption o) => o.key == autoMethodFor(loc)).label}'
                      : m.detail,
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
            Text(
              'Angles for the regional presets follow the list the AlAdhan '
              'prayer-times API publishes for each authority '
              '(api.aladhan.com/v1/methods).',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text('HIGH LATITUDES', style: AppText.eyebrow),
            const SizedBox(height: 4),
            Text(
              'Far from the equator, twilight may never end in summer. This '
              'chooses how the night is shared out so Fajr and Isha stay '
              'sensible.',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
            for (final HighLatitudeOption r in kHighLatitudeRules)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => ctrl.setHighLatitude(r.key),
                leading: Icon(
                  settings.highLatitude == r.key
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.gold,
                  size: 20,
                ),
                title: Text(r.label, style: AppText.body),
                subtitle: Text(
                  r.detail,
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            Text('MINUTE OFFSETS', style: AppText.eyebrow),
            const SizedBox(height: 4),
            Text(
              'If your mosque\u2019s timetable differs by a few minutes, nudge '
              'a time here (up to $kMaxOffsetMinutes either way). It moves the '
              'time on screen and the notification together.',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
            for (final String name in kOffsetPrayers)
              Row(
                children: [
                  Expanded(child: Text(name, style: AppText.body)),
                  IconButton(
                    tooltip: 'One minute earlier for $name',
                    onPressed: () =>
                        ctrl.setOffset(name, settings.offsetFor(name) - 1),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: AppColors.gold,
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      settings.offsetFor(name) == 0
                          ? '0 min'
                          : '${settings.offsetFor(name) > 0 ? '+' : ''}${settings.offsetFor(name)} min',
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(color: AppColors.gold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'One minute later for $name',
                    onPressed: () =>
                        ctrl.setOffset(name, settings.offsetFor(name) + 1),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: AppColors.gold,
                  ),
                ],
              ),
            if (settings.hasOffsets)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: ctrl.clearOffsets,
                  child: Text(
                    'Reset all offsets',
                    style: AppText.bodyMuted.copyWith(color: AppColors.gold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The five-prayer log. Quiet by design: no streaks, no totals, and an
/// "Excused" mark that counts for nothing and asks for nothing.
class _PrayerLogCard extends ConsumerStatefulWidget {
  const _PrayerLogCard({required this.data, required this.now});

  final PrayerTimes data;
  final DateTime now;

  @override
  ConsumerState<_PrayerLogCard> createState() => _PrayerLogCardState();
}

class _PrayerLogCardState extends ConsumerState<_PrayerLogCard> {
  /// 0 = today, 1 = yesterday, ... up to 6.
  int _back = 0;

  static IconData _iconFor(PrayerMark? m) => switch (m) {
    PrayerMark.prayed => Icons.check_circle,
    PrayerMark.prayedLate => Icons.timelapse,
    PrayerMark.missed => Icons.replay,
    PrayerMark.excused => Icons.remove_circle_outline,
    null => Icons.radio_button_unchecked,
  };

  Future<void> _choose(String day, String prayer) async {
    final PrayerMark? current = ref.read(prayerLogProvider).markFor(day, prayer);
    final PrayerMark? picked = await showModalBottomSheet<PrayerMark>(
      context: context,
      backgroundColor: AppColors.night,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(prayer, style: AppText.titleMedium),
              ),
            ),
            for (final PrayerMark m in PrayerMark.values)
              ListTile(
                key: Key('mark-${m.name}'),
                leading: Icon(
                  _iconFor(m),
                  color: current == m ? AppColors.gold : AppColors.sand,
                ),
                title: Text(m.label, style: AppText.body),
                subtitle: m == PrayerMark.excused
                    ? Text(
                        'Not counted and never added to your make-up list. '
                        'Use it for any day prayer was not required of you or '
                        'not possible. For your own situation, ask a scholar.',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      )
                    : m == PrayerMark.missed
                    ? Text(
                        'Adds one to the Qada counter on My Journey. How a '
                        'missed prayer is made up is for your scholar.',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      )
                    : null,
                trailing: current == m
                    ? const Icon(Icons.check, color: AppColors.gold, size: 18)
                    : null,
                onTap: () => Navigator.of(ctx).pop(m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(prayerLogProvider.notifier).mark(day, prayer, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PrayerLogState log = ref.watch(prayerLogProvider);
    final DateTime wall = widget.data.wallClock(widget.now);
    final DateTime shown = DateTime(wall.year, wall.month, wall.day - _back);
    final String day = PrayerLogController.dayKey(shown);
    final String title = _back == 0
        ? 'Today'
        : _back == 1
        ? 'Yesterday'
        : DateFormat.MMMEd().format(shown);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'YOUR PRAYERS · ${title.toUpperCase()}',
                  style: AppText.eyebrow.copyWith(color: AppColors.gold),
                ),
              ),
              IconButton(
                tooltip: 'Earlier day',
                visualDensity: VisualDensity.compact,
                onPressed: _back < 6 ? () => setState(() => _back++) : null,
                icon: const Icon(Icons.chevron_left, size: 22),
                color: AppColors.gold,
              ),
              IconButton(
                tooltip: 'Later day',
                visualDensity: VisualDensity.compact,
                onPressed: _back > 0 ? () => setState(() => _back--) : null,
                icon: const Icon(Icons.chevron_right, size: 22),
                color: AppColors.gold,
              ),
            ],
          ),
          Text(
            'A private note to yourself on this device. No streaks, no totals.',
            style: AppText.bodyMuted.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          for (final (String prayer, DateTime time) in widget.data.prayers)
            Builder(
              builder: (BuildContext context) {
                final PrayerMark? mark = log.markFor(day, prayer);
                // Today's later prayers cannot be marked yet.
                final bool future = _back == 0 && time.isAfter(wall);
                return ListTile(
                  key: Key('log-$prayer'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  enabled: !future,
                  leading: Icon(
                    _iconFor(mark),
                    size: 22,
                    color: mark == null
                        ? AppColors.sand.withValues(alpha: 0.4)
                        : AppColors.gold,
                  ),
                  title: Text(prayer, style: AppText.body),
                  subtitle: Text(
                    future
                        ? 'at ${DateFormat.jm().format(time)}'
                        : (mark?.label ?? 'Tap to note it'),
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
                  onTap: future ? null : () => _choose(day, prayer),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Mosque congregation times typed in by the user (see [IqamahSettings]).
class _IqamahCard extends ConsumerStatefulWidget {
  const _IqamahCard();

  @override
  ConsumerState<_IqamahCard> createState() => _IqamahCardState();
}

class _IqamahCardState extends ConsumerState<_IqamahCard> {
  bool _open = false;

  Future<void> _pickJumuah(IqamahSettings cur) async {
    final (int, int)? parsed = IqamahSettings.parseTime(cur.jumuahTime);
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: parsed?.$1 ?? 13, minute: parsed?.$2 ?? 0),
      helpText: "Jumu'ah prayer time at your mosque",
    );
    if (t == null || !mounted) return;
    await ref
        .read(iqamahProvider.notifier)
        .setJumuah(IqamahSettings.formatTime(t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final IqamahSettings cur = ref.watch(iqamahProvider);
    final IqamahController ctrl = ref.read(iqamahProvider.notifier);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "MOSQUE TIMES · IQAMAH AND JUMU'AH",
                    style: AppText.eyebrow.copyWith(color: AppColors.gold),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.gold,
                ),
              ],
            ),
          ),
          if (!_open)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                cur.isEmpty
                    ? 'Add your mosque\u2019s iqamah gaps and Jumu\u2019ah time '
                          'and they appear beside each prayer.'
                    : 'Shown beside each prayer above. Tap to change.',
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
            ),
          if (_open) ...[
            const SizedBox(height: 6),
            Text(
              'You enter these yourself from your mosque\u2019s notice board or '
              'website; Ar-Rayaan does not fetch mosque timetables. Iqamah is '
              'set as minutes after the adhan time shown.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 8),
            for (final String p in IqamahController.prayers)
              Row(
                children: [
                  Expanded(child: Text(p, style: AppText.body)),
                  IconButton(
                    tooltip: 'Iqamah $p, 5 minutes earlier',
                    onPressed: () => ctrl.setMinutes(p, cur.minutesFor(p) - 5),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: AppColors.gold,
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      cur.minutesFor(p) == 0
                          ? 'not set'
                          : '+${cur.minutesFor(p)} min',
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(color: AppColors.gold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Iqamah $p, 5 minutes later',
                    onPressed: () => ctrl.setMinutes(p, cur.minutesFor(p) + 5),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: AppColors.gold,
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    cur.jumuahTime == null
                        ? "Jumu'ah time: not set"
                        : "Jumu'ah time: ${cur.jumuahTime}",
                    style: AppText.body,
                  ),
                ),
                TextButton(
                  onPressed: () => _pickJumuah(cur),
                  child: Text(
                    cur.jumuahTime == null ? 'Set' : 'Change',
                    style: AppText.bodyMuted.copyWith(color: AppColors.gold),
                  ),
                ),
                if (cur.jumuahTime != null)
                  TextButton(
                    onPressed: () => ctrl.setJumuah(null),
                    child: Text(
                      'Clear',
                      style: AppText.bodyMuted.copyWith(color: AppColors.gold),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// What the phone itself will do: notify with the app closed, and what the
/// user can do to make that reliable.
class _NotificationCard extends ConsumerStatefulWidget {
  const _NotificationCard();

  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard>
    with WidgetsBindingObserver {
  ExactAlarmStatus _exact = ExactAlarmStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the system settings screen re-checks the permission.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final ExactAlarmStatus s = await ref
        .read(prayerNotificationSchedulerProvider)
        .exactAlarmStatus();
    if (mounted) setState(() => _exact = s);
  }

  Future<void> _openBatteryHelp() async {
    try {
      await launchUrl(
        Uri.parse('https://dontkillmyapp.com'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // No browser available; the text above still explains.
    }
  }

  @override
  Widget build(BuildContext context) {
    final PrayerNotificationScheduler scheduler = ref.watch(
      prayerNotificationSchedulerProvider,
    );
    final int lead = ref.watch(notificationLeadProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHONE NOTIFICATIONS',
            style: AppText.eyebrow.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 6),
          if (!scheduler.supported)
            Text(
              'In a browser, alerts only work while this page is open. The '
              'Android and iPhone apps can notify you at each prayer time you '
              'switch on (the bell) even when the app is closed.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            )
          else ...[
            Text(
              'A notification arrives at each prayer time you switched on '
              '(the bell), even with the app closed, in your phone\u2019s '
              'alert sound. The full adhan plays here in the app. The text '
              'shows only the prayer name, never your place.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text('Also remind me before', style: AppText.label),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final int m in NotificationLeadController.options)
                  ChoiceChip(
                    key: Key('lead-$m'),
                    label: Text(m == 0 ? 'No' : '$m min'),
                    selected: lead == m,
                    onSelected: (_) =>
                        ref.read(notificationLeadProvider.notifier).set(m),
                  ),
              ],
            ),
            if (_exact == ExactAlarmStatus.denied) ...[
              const SizedBox(height: 10),
              Text(
                'Android is not letting Ar-Rayaan set exact alarms, so '
                'notifications may arrive a few minutes late. Allow '
                '\u201cAlarms & reminders\u201d for the app to fix this.',
                style: AppText.bodyMuted.copyWith(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.goldLight,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await scheduler.openExactAlarmSettings();
                },
                icon: const Icon(Icons.alarm, size: 16),
                label: const Text('Allow exact alarms'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldLight,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Some phone makers stop apps from waking up in the background. '
              'If a notification does not arrive, exempt Ar-Rayaan from '
              'battery optimisation in your phone\u2019s settings.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
            TextButton(
              onPressed: _openBatteryHelp,
              child: Text(
                'Steps for your phone brand (dontkillmyapp.com)',
                style: AppText.bodyMuted.copyWith(color: AppColors.gold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
