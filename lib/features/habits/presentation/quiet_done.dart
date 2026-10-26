import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../elder/application/elder_mode.dart';
import '../../share/presentation/share_actions.dart';
import '../application/habits_providers.dart';
import '../application/return_loop.dart';

/// Kill switch for the quiet completion cards. See docs/product/return_loop.md.
const bool kQuietDoneEnabled = true;

/// The one line shown. Plain words, not a ruling and not a du'a.
const String kQuietDoneText = 'Done. May it be accepted.';

/// Remembers which moments were already shown, so a card appears once per
/// set / surah per day (and the first lesson only once, ever).
class QuietDoneGate {
  const QuietDoneGate._();

  static const String key = 'ar.quietdone.seen';

  /// True the first time it is asked for [moment] ([day] is null for "ever").
  /// Marks it seen. Returns false when storage is unavailable, so a broken
  /// device shows nothing rather than repeating.
  static Future<bool> claim(
    SharedPreferences prefs,
    String moment, {
    DateTime? day,
  }) async {
    final String id = day == null
        ? moment
        : '$moment|${FastingLogController.stamp(day)}';
    final List<String> seen = prefs.getStringList(key) ?? <String>[];
    if (seen.contains(id)) return false;
    // Day-stamped entries are pruned so the list stays tiny.
    final List<String> forever = seen
        .where((String s) => !s.contains('|'))
        .toList();
    final List<String> daily = seen
        .where((String s) => s.contains('|'))
        .toList();
    final List<String> keep = daily.length > 40
        ? daily.sublist(daily.length - 40)
        : daily;
    final List<String> next = <String>[...forever, ...keep, id];
    return prefs.setStringList(key, next);
  }
}

/// The calm card body: one line, an optional "came back" line, one button.
/// No points, no confetti, no ranking. When [shareText] is given there is
/// also a quiet "Share" button; it only opens a preview, nothing is sent
/// until the person confirms there.
class QuietDoneCard extends ConsumerWidget {
  const QuietDoneCard({this.onClose, this.shareText, super.key});

  final VoidCallback? onClose;

  /// The milestone line to preview and share ("I completed ...").
  final String? shareText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool elder = ref.watch(elderModeProvider);
    final String? returned = ref.watch(returnMessageProvider);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
      child: GlassCard(
        strong: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.gold,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                kQuietDoneText,
                key: const Key('quiet-done-text'),
                style: AppText.titleMedium.copyWith(
                  fontSize: elder ? 26 : null,
                ),
                textAlign: TextAlign.center,
              ),
              if (returned != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  returned,
                  key: const Key('quiet-done-returned'),
                  style: AppText.bodyMuted.copyWith(fontSize: elder ? 20 : 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              if (shareText != null) ...<Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: elder ? 64 : 48),
                  child: OutlinedButton.icon(
                    key: const Key('quiet-done-share'),
                    onPressed: () => unawaited(
                      showSharePreview(
                        context,
                        text: shareText!,
                        subject: 'this milestone',
                      ),
                    ),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: Text(
                      'Share this',
                      style: TextStyle(fontSize: elder ? 20 : null),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: elder ? 64 : 48),
                child: FilledButton(
                  key: const Key('quiet-done-close'),
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(fontSize: elder ? 20 : null),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the card once for [moment] (see [QuietDoneGate.claim]). Never
/// throws and never blocks the screen it is called from.
Future<void> showQuietDone(
  BuildContext context,
  WidgetRef ref, {
  required String moment,
  bool oncePerDay = true,
  String? shareText,
}) async {
  if (!kQuietDoneEnabled) return;
  try {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final bool fresh = await QuietDoneGate.claim(
      prefs,
      moment,
      day: oncePerDay ? DateTime.now() : null,
    );
    if (!fresh || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheet) => QuietDoneCard(shareText: shareText),
    );
  } catch (_) {}
}
