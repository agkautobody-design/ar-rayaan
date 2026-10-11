import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/core/notifications/web_notifier.dart';
import '../../../app/core/sound/sound_services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/location_providers.dart';
import '../application/prayer_alerts.dart';
import '../application/prayer_providers.dart';
import '../application/prayer_repository.dart';
import '../data/aladhan_prayer_repository.dart';
import '../data/city_directory.dart';
import '../domain/prayer_times.dart';

/// Prayer Times — live schedule from Aladhan (O-5 approved source).
/// New screen designed within the locked system — pending Founder approval.
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

    return ScenicScaffold.pattern(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Prayer Times'),
            Expanded(
              child: times.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (Object e, _) => _ErrorState(
                  message: e is PrayerTimesException
                      ? e.message
                      : 'Connect to the internet to load today\'s prayer times.',
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
    final DateTime n = now;
    ref
        .read(firedAlertsProvider.notifier)
        .markFired('${n.year}-${n.month}-${n.day}:$prayer');
    ref.read(adhanServiceProvider.notifier).toggle();
    WebNotifier.show(
      'It is now $prayer time',
      '$prayer · ${data.locationLabel} — Ar-Rayaan',
    );
  }

  String _countdown(DateTime target) {
    final Duration d = target.difference(now);
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
    final String? alert = ref.watch(activeAlertProvider);

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
                      style: AppText.bodyMuted.copyWith(fontSize: 11),
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
                      'Tahajjud tonight',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'The last third of the night begins ${DateFormat.jm().format(data.lastThirdStart)} — '
                      '“Who calls upon Me that I may answer him?”',
                      style: AppText.bodyMuted.copyWith(
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${data.locationLabel} · ${data.methodLabel}',
          style: AppText.bodyMuted.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'TIMES ARE APPROXIMATE · CONFIRM LOCALLY',
          style: AppText.eyebrow.copyWith(
            color: AppColors.gold.withValues(alpha: 0.4),
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
  });

  final String name;
  final DateTime time;
  final IconData icon;
  final bool isNext;

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
            child: Text(
              name,
              style: AppText.body.copyWith(
                color: nameColor,
                fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
              ),
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
                  fontSize: 8,
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ref.read(prayerAlertsProvider.notifier).toggle(name);
                if (!alertOn) WebNotifier.ensurePermission();
              },
              child: Icon(
                alertOn
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                size: 18,
                color: alertOn
                    ? AppColors.gold
                    : AppColors.sand.withValues(alpha: 0.35),
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
              style: AppText.bodyMuted.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 12),
            for (final PrayerLocation c in CityDirectory.cities)
              Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(c.city, style: AppText.body),
                subtitle: c.country.isEmpty
                    ? null
                    : Text(
                        c.country,
                        style: AppText.bodyMuted.copyWith(fontSize: 11),
                      ),
                onTap: () => Navigator.of(ctx).pop(c),
              )),
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
                    style: AppText.bodyMuted.copyWith(fontSize: 10),
                  )
                else if (status == GpsStatus.unavailable)
                  Text(
                    'Location is off on this device — pick your city instead',
                    style: AppText.bodyMuted.copyWith(fontSize: 10),
                  )
                else if (status == GpsStatus.error)
                  Text(
                    'Could not get your location — pick your city instead',
                    style: AppText.bodyMuted.copyWith(fontSize: 10),
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
