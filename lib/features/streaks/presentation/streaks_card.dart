import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../elder/application/elder_mode.dart';
import '../../habits/application/return_loop.dart';
import '../application/streaks_providers.dart';
import '../domain/streak_math.dart';

/// Words for one streak, positive only. Never mentions what was lost.
String streakPhrase(StreakTrack track, int days) {
  if (days < StreakMath.minToShow) return 'Begin whenever you are ready';
  switch (track) {
    case StreakTrack.quran:
      return 'Came back to the Qur’an for $days days';
    case StreakTrack.dhikr:
      return 'Came back to dhikr for $days days';
    case StreakTrack.prayers:
      return 'Logged prayers for $days days';
    case StreakTrack.returned:
      return 'Came back $days days';
  }
}

/// The streaks card on Home. When streaks are off it is a quiet invitation
/// (with "Not now"); when on, it is a tap target that opens the Streaks
/// screen. Nothing here ever says what was lost.
class StreaksCard extends ConsumerStatefulWidget {
  const StreaksCard({super.key});

  /// Remembers "Not now" so the invitation is not shown again.
  static const String dismissedKey = 'ar.streaks.invite.dismissed';

  @override
  ConsumerState<StreaksCard> createState() => _StreaksCardState();
}

class _StreaksCardState extends ConsumerState<StreaksCard> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    try {
      _dismissed =
          ref
              .read(sharedPreferencesProvider)
              .getBool(StreaksCard.dismissedKey) ??
          false;
    } catch (_) {}
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final SharedPreferences p = ref.read(sharedPreferencesProvider);
      await p.setBool(StreaksCard.dismissedKey, true);
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
          key: const Key('streaks-invite'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('STREAKS', style: AppText.eyebrow),
              const SizedBox(height: 6),
              Text(
                'Keep a gentle record of the days you come back. One grace '
                'day each week, kept on this device, never shared unless you '
                'choose.',
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
                      key: const Key('streaks-turn-on'),
                      onPressed: () => unawaited(
                        ref.read(returnLoopEnabledProvider.notifier).set(true),
                      ),
                      child: const Text('Turn on'),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minTap),
                    child: TextButton(
                      key: const Key('streaks-not-now'),
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
    final List<StreakView> views = <StreakView>[
      for (final StreakTrack t in StreakTrack.values)
        ref.watch(streakViewProvider(t)),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        key: const Key('streaks-card'),
        padding: const EdgeInsets.all(16),
        onTap: () => context.open(AppRoutes.streaks),
        semanticsLabel: 'Streaks. Open',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text('STREAKS', style: AppText.eyebrow)),
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
            for (final StreakView v in views)
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
                        v.days >= StreakMath.minToShow
                            ? '${v.days} days'
                            : 'Begin today',
                        textAlign: TextAlign.end,
                        style: AppText.bodyMuted.copyWith(
                          fontSize: elder ? 18 : 14,
                          color: v.days >= StreakMath.minToShow
                              ? AppColors.gold
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
