import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/notifications/prayer_notification_scheduler.dart';
import '../../../app/core/notifications/web_notifier.dart';
import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../prayer/application/alert_permission.dart';
import '../../prayer/application/prayer_alerts.dart';

/// An invitation, shown once, to turn on a reminder at each prayer time.
/// Never an operating-system prompt at launch: the person taps "Turn on" and
/// only then does the phone or browser ask. "Not now" is remembered. Hidden
/// where notifications cannot work at all, and once any alert is on.
class NotifyInvite extends ConsumerStatefulWidget {
  const NotifyInvite({super.key});

  /// Remembers the person's answer ("done") so the card never nags.
  static const String prefKey = 'ar.notify.invite';

  @override
  ConsumerState<NotifyInvite> createState() => _NotifyInviteState();
}

class _NotifyInviteState extends ConsumerState<NotifyInvite> {
  bool _hidden = false;
  bool _busy = false;

  SharedPreferences? _prefs() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  Future<void> _remember() async {
    try {
      await _prefs()?.setString(NotifyInvite.prefKey, 'done');
    } catch (_) {}
  }

  Future<void> _turnOn() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await ref.read(prayerAlertsProvider.notifier).enableAll();
    final String note = await askAlertPermission(
      ref,
      'Reminders are on for all five prayers',
    );
    await _remember();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(note), duration: const Duration(seconds: 7)),
      );
    if (mounted) setState(() => _hidden = true);
  }

  Future<void> _notNow() async {
    await _remember();
    if (mounted) setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final bool canNotify =
        ref.watch(prayerNotificationSchedulerProvider).supported ||
        WebNotifier.isSupported;
    if (!canNotify) return const SizedBox.shrink();
    if (ref.watch(prayerAlertsProvider).isNotEmpty) {
      return const SizedBox.shrink();
    }
    if (_prefs()?.getString(NotifyInvite.prefKey) == 'done') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Be reminded at each prayer time?',
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Turn on notifications and Ar-Rayaan will remind you when '
                'Fajr, Dhuhr, Asr, Maghrib and Isha arrive. You can change '
                'any of them later on the Prayer Times page.',
                style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton(
                    key: const Key('notify-invite-on'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                    ),
                    onPressed: _busy ? null : _turnOn,
                    child: Text('Turn on'),
                  ),
                  TextButton(
                    key: const Key('notify-invite-later'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.gold,
                    ),
                    onPressed: _busy ? null : _notNow,
                    child: Text('Not now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
