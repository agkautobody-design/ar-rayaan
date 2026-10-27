import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../elder/application/elder_mode.dart';
import '../domain/tracking_math.dart';

/// An optional, kind invitation ("A small step today?"). It can always be
/// dismissed, and once dismissed it stays away for the rest of that day. It
/// is never red, never a count of anything, and never a push notification.
class GentleNudge extends ConsumerStatefulWidget {
  const GentleNudge({required this.text, super.key});

  final String text;

  /// The day (`yyyy-mm-dd`) on which the person last said "Not now".
  static const String dismissedKey = 'ar.tracking.nudge.day';

  @override
  ConsumerState<GentleNudge> createState() => _GentleNudgeState();
}

class _GentleNudgeState extends ConsumerState<GentleNudge> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    try {
      final String? day = ref
          .read(sharedPreferencesProvider)
          .getString(GentleNudge.dismissedKey);
      _hidden = day == TrackingMath.stamp(DateTime.now());
    } catch (_) {}
  }

  Future<void> _dismiss() async {
    setState(() => _hidden = true);
    try {
      final SharedPreferences p = ref.read(sharedPreferencesProvider);
      await p.setString(
        GentleNudge.dismissedKey,
        TrackingMath.stamp(DateTime.now()),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final bool elder = ref.watch(elderModeProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        key: const Key('log-nudge'),
        children: <Widget>[
          Expanded(
            child: Text(
              widget.text,
              style: AppText.body.copyWith(
                fontSize: elder ? 18 : 14,
                color: AppColors.gold,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: elder ? 64 : 48),
            child: TextButton(
              key: const Key('log-nudge-dismiss'),
              onPressed: () => unawaited(_dismiss()),
              child: const Text('Not now'),
            ),
          ),
        ],
      ),
    );
  }
}
