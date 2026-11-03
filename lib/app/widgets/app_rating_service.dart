import 'package:flutter/material.dart' hide Text;
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/widgets/gold_button.dart';
import '../../app/theme/widgets/tr_text.dart';

/// Shows an in-app rating prompt after the user has had 5 positive sessions.
/// Respects platform guidelines (max 3 requests per year).
class AppRatingService {
  static const String _launchCountKey = 'app_rating_launch_count';
  static const String _lastPromptKey = 'app_rating_last_prompt';
  static const String _hasRatedKey = 'app_rating_has_rated';
  static const int _minLaunches = 5;
  static const int _minDaysBetweenPrompts = 90;

  /// Set when the check has run this app session. Home rebuilds fire
  /// maybePrompt again and again; without this, the launch counter climbs
  /// several steps in a single session and the dialog can appear on a
  /// person's very first open.
  static bool _checkedThisSession = false;

  static Future<void> maybePrompt(BuildContext context) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    final prefs = await SharedPreferences.getInstance();

    // Already rated
    if (prefs.getBool(_hasRatedKey) ?? false) return;

    // Never interrupt the first-run onboarding (the router's first-run
    // gate key, set when onboarding completes).
    if (!(prefs.getBool('ar.onboarded.v1') ?? false)) return;

    // Check launch count
    final launches = (prefs.getInt(_launchCountKey) ?? 0) + 1;
    await prefs.setInt(_launchCountKey, launches);
    if (launches < _minLaunches) return;

    // Check cooldown
    final lastPrompt = prefs.getInt(_lastPromptKey);
    if (lastPrompt != null) {
      final daysSince = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastPrompt),
      ).inDays;
      if (daysSince < _minDaysBetweenPrompts) return;
    }

    // Show custom dialog first
    if (context.mounted) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _RatingDialog(),
      );

      if (result == true) {
        await prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        }
      }
    }
  }

  static Future<void> markRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
  }
}

class _RatingDialog extends StatelessWidget {
  const _RatingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.night,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 48, color: AppColors.gold),
            const SizedBox(height: 16),
            const Text('Enjoying Ar-Rayaan?', style: AppText.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Your rating helps us reach more Muslims around the world.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GoldButton(
              onPressed: () => Navigator.pop(context, true),
              label: 'Rate 5 Stars',
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
