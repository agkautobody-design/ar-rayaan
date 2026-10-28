import 'dart:async' show unawaited;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../elder/application/elder_mode.dart';
import '../../habits/application/return_loop.dart';
import '../application/tracking_providers.dart';
import '../domain/encouragement.dart';
import '../domain/tracking_math.dart';
import 'gentle_nudge.dart';

/// The words for one total, as a plain sentence. Never a run, never a loss;
/// an empty period simply says so and invites, without any judgement.
String totalSentence(TrackingTrack track, LogPeriod period, int n) {
  final String when = switch (period) {
    LogPeriod.week => 'this week',
    LogPeriod.month => 'this month',
    LogPeriod.allTime => 'in all',
  };
  if (n <= 0) {
    return 'Nothing logged $when. Start whenever you like.';
  }
  switch (track) {
    case TrackingTrack.prayers:
      final String times = n == 1 ? 'once' : '$n times';
      return 'You have prayed $times $when.';
    case TrackingTrack.quran:
      return 'You read the Qur’an on $n ${n == 1 ? 'day' : 'days'} $when.';
    case TrackingTrack.dhikr:
      return 'You made dhikr on $n ${n == 1 ? 'day' : 'days'} $when.';
    case TrackingTrack.fasting:
      return 'You fasted on $n ${n == 1 ? 'day' : 'days'} $when.';
    case TrackingTrack.lessons:
      return 'You learned on $n ${n == 1 ? 'day' : 'days'} $when.';
    case TrackingTrack.all:
      return 'You logged something on $n ${n == 1 ? 'day' : 'days'} $when.';
  }
}

/// The short right-hand text of a row on the Home card.
String _weekShort(TrackingTrack t, int n) =>
    n <= 0 ? '–' : '$n ${n == 1 ? t.unitOne : t.unitMany} this week';

/// The My log card on Home. When the log is off it is a quiet invitation
/// (with "Not now"); when on, it is a tap target that opens My log. Nothing
/// here ever says what was not done.
class TrackingCard extends ConsumerStatefulWidget {
  const TrackingCard({super.key});

  /// Remembers "Not now" so the invitation is not shown again.
  static const String dismissedKey = 'ar.tracking.invite.dismissed';

  /// The key an earlier release used for the same choice.
  static const String legacyDismissedKey = 'ar.streaks.invite.dismissed';

  @override
  ConsumerState<TrackingCard> createState() => _TrackingCardState();
}

class _TrackingCardState extends ConsumerState<TrackingCard> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    try {
      final SharedPreferences p = ref.read(sharedPreferencesProvider);
      _dismissed =
          (p.getBool(TrackingCard.dismissedKey) ?? false) ||
          (p.getBool(TrackingCard.legacyDismissedKey) ?? false);
    } catch (_) {}
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final SharedPreferences p = ref.read(sharedPreferencesProvider);
      await p.setBool(TrackingCard.dismissedKey, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!kReturnLoopEnabled) return const SizedBox.shrink();
    final bool on = ref.watch(returnLoopEnabledProvider);
    final bool elder = ref.watch(elderModeProvider);
    final double minTap = elder ? 64 : 48;
    if (!on) {
      if (_dismissed) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          key: const Key('my-log-invite'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('MY LOG', style: AppText.eyebrow),
              const SizedBox(height: 6),
              Text(
                'Keep a private log of what you read, remember and learn. It '
                'adds up your week, your month and all time. It stays on this '
                'device and is never shared.',
                style: AppText.body.copyWith(
                  fontSize: elder ? 18 : 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minTap),
                    child: FilledButton(
                      key: const Key('my-log-turn-on'),
                      onPressed: () => unawaited(
                        ref.read(returnLoopEnabledProvider.notifier).set(true),
                      ),
                      child: const Text('Turn on'),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minTap),
                    child: TextButton(
                      key: const Key('my-log-not-now'),
                      onPressed: () => unawaited(_dismiss()),
                      child: const Text('Not now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    final List<TrackingView> shown = <TrackingView>[
      for (final TrackingTrack t in TrackingTrack.values)
        if (t != TrackingTrack.all)
          if (ref.watch(trackingViewProvider(t)).total(LogPeriod.allTime) > 0)
            ref.watch(trackingViewProvider(t)),
    ];
    final Encouragement e = ref.watch(encouragementProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        key: const Key('my-log-card'),
        padding: const EdgeInsets.all(16),
        onTap: () => context.open(AppRoutes.tracking),
        semanticsLabel: 'My log. Open',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text('MY LOG', style: AppText.eyebrow)),
                Text(
                  'Open',
                  style: AppText.bodyMuted.copyWith(
                    fontSize: 12,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (e.text != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  e.text!,
                  key: const Key('my-log-card-message'),
                  style: AppText.body.copyWith(fontSize: elder ? 18 : 14),
                ),
              ),
            for (final TrackingView v in shown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        v.track.label,
                        style: AppText.body.copyWith(
                          fontSize: elder ? 18 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _weekShort(v.track, v.total(LogPeriod.week)),
                        textAlign: TextAlign.end,
                        style: AppText.bodyMuted.copyWith(
                          fontSize: elder ? 18 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (e.nudge != null) GentleNudge(text: e.nudge!),
          ],
        ),
      ),
    );
  }
}
