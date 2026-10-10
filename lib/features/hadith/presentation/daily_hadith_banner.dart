import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/content/content_sync.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';

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

  int get _dayOfYear =>
      DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _on = p.getBool('ar.dailyhadith.on') ?? true;
    _shownToday = p.getString('ar.dailyhadith.shown') == today;
    try {
      final raw = await ContentSync.load('stories/modernhadith.json');
      final list = json.decode(raw) as List<dynamic>;
      if (list.isNotEmpty && mounted) {
        setState(() => _entry =
            Map<String, dynamic>.from(list[_dayOfYear % list.length] as Map));
      }
    } catch (_) {
      // Library not reachable today — the banner rests, nothing breaks.
    }
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
    final body = (_entry!['chapters'] as List).first['body'] as String;
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
              Expanded(child: Text(kicker, style: AppText.eyebrow.copyWith(fontSize: 9.5))),
              GestureDetector(
                onTap: _toggle,
                child: Icon(
                  _on ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                  size: 15, color: AppColors.gold.withValues(alpha: 0.7)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _dismiss,
                child: Icon(Icons.close, size: 15, color: AppColors.sand.withValues(alpha: 0.6))),
            ]),
            const SizedBox(height: 6),
            Text(snippet, style: AppText.body.copyWith(height: 1.55, fontSize: 13)),
            const SizedBox(height: 4),
            Text('tap for the full entry and its sources',
                style: AppText.bodyMuted.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
