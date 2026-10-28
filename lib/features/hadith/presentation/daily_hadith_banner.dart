import '../../../app/core/scholar_review.dart';
import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/content/content_sync.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../domain/daily_hadith.dart' show dayOfYear;
import '../../../app/theme/widgets/focus_ring.dart';

/// THE DAILY HADITH — the app's heartbeat. Every day the same hadith on
/// every device (day-of-year over the living library, which the daily cron
/// keeps growing). A gold banner greets the first open of each day; a tap
/// walks into the library; the bell toggles the greeting.
class DailyHadithBanner extends StatefulWidget {
  const DailyHadithBanner({super.key});

  @override
  State<DailyHadithBanner> createState() => _DailyHadithBannerState();
}

class _DailyHadithBannerState extends State<DailyHadithBanner> {
  Map<String, dynamic>? _entry;
  bool _on = true;
  bool _shownToday = false;

  // Shared, DST-safe day-of-year (UTC date arithmetic).
  int get _dayOfYear => dayOfYear(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _on = p.getBool('ar.dailyhadith.on') ?? true;
    _shownToday = p.getString('ar.dailyhadith.shown') == today;
    } catch (_) {
      _on = true;
      _shownToday = false;
    }
    try {
      final list = await ContentSync.loadParsed<List<dynamic>>(
        'stories/modernhadith.json',
        (String raw) {
          final l = json.decode(raw) as List<dynamic>;
          // Parse today's entry here so a drifted remote pack is rejected
          // (and the bundled one used) instead of failing in build().
          if (l.isNotEmpty) {
            _bodyOf(Map<String, dynamic>.from(l[_dayOfYear % l.length] as Map));
          }
          return l;
        },
      );
      if (list.isNotEmpty && mounted) {
        setState(() => _entry =
            Map<String, dynamic>.from(list[_dayOfYear % list.length] as Map));
      }
    } catch (_) {
      // Storage or library unreachable (offline, first run, test harness) —
      // the banner rests, nothing breaks, no async gap escapes.
    }
  }

  /// The first chapter's body; throws if the entry is not shaped like one.
  static String _bodyOf(Map<String, dynamic> entry) {
    final chapters = entry['chapters'] as List<dynamic>;
    final first = chapters.first as Map<String, dynamic>;
    return first['body'] as String;
  }

  Future<void> _dismiss() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ar.dailyhadith.shown',
        DateTime.now().toIso8601String().substring(0, 10));
    if (mounted) setState(() => _shownToday = true);
  }

  Future<void> _toggle() async {
    final p = await SharedPreferences.getInstance();
    _on = !_on;
    await p.setBool('ar.dailyhadith.on', _on);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_on || _shownToday || _entry == null) return const SizedBox.shrink();
    final body = _bodyOf(_entry!);
    final kicker = _entry!['kicker'] as String? ?? 'HADITH FOR TODAY';
    final snippet = body.length > 190 ? '${body.substring(0, 190)}\u2026' : body;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: GlassCard(
        strong: true,
        onTap: () => context.go(AppRoutes.stories),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(kicker, style: AppText.eyebrow.copyWith(fontSize: 12))),
              Semantics(
                button: true,
                label: _on
                    ? 'Turn off the daily hadith greeting'
                    : 'Turn on the daily hadith greeting',
                child: FocusableTap(
                  onTap: _toggle,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                        _on ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                        size: 18, color: AppColors.gold.withValues(alpha: 0.7)),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Dismiss today\'s hadith',
                child: FocusableTap(
                  onTap: _dismiss,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.close, size: 18, color: AppColors.sand.withValues(alpha: 0.6)),
                  )),
              ),
            ]),
            const SizedBox(height: 6),
            Text(snippet, style: AppText.body.copyWith(height: 1.55, fontSize: 13)),
            const SizedBox(height: 4),
            Text('tap for the full entry and its sources',
                style: AppText.bodyMuted.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            ScholarReviewNote(
              reviewKey: storyReviewKey(
                  'modernhadith', _entry!['id'] as String? ?? ''),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
