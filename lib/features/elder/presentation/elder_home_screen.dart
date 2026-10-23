import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../sakina/presentation/widgets/need_help_button.dart';
import '../application/elder_mode.dart';

/// ELDER MODE - the whole home, simplified. Giant words, three doors,
/// nothing else. Once a family turns this on, the app opens here every time
/// until it is turned off. The young set it up; the old simply use it.
class ElderHomeScreen extends ConsumerStatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  ConsumerState<ElderHomeScreen> createState() => _ElderHomeState();
}

class _ElderHomeState extends ConsumerState<ElderHomeScreen> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final p = await SharedPreferences.getInstance();
      // Being on this screen IS Elder Mode: the whole app follows (text size
      // and tap size, see AccessibilityScope).
      if (mounted) await ref.read(elderModeProvider.notifier).set(true);
      if (mounted) setState(() => _count = p.getInt('ar.elder.dhikr') ?? 0);
    });
  }

  Future<void> _tap() async {
    setState(() => _count++);
    final p = await SharedPreferences.getInstance();
    await p.setInt('ar.elder.dhikr', _count);
  }

  Future<void> _exit() async {
    await ref.read(elderModeProvider.notifier).set(false);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    // Elder Mode is already big. On a narrow phone or at the largest system
    // text the door rows give their width to the words (no chevron, a
    // smaller icon) so a word is never broken in the middle.
    final bool tight = MediaQuery.sizeOf(context).width < 400 ||
        MediaQuery.textScalerOf(context).scale(14) > 18;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(children: [
              const Icon(Icons.wb_sunny_outlined, color: AppColors.goldLight, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text('As-salamu alaikum',
                  style: AppText.body.copyWith(fontSize: 20, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 10),
            // Always visible, always the same words: how to leave.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _exit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(72, 56),
                  foregroundColor: AppColors.goldLight,
                ),
                child: Text('Turn off Elder Mode',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 14),
            const Center(child: NeedHelpNowButton(large: true)),
            const SizedBox(height: 14),
            FocusableTap(
              onTap: _tap,
              borderRadius: 22,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 34),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: 1.6),
                  color: const Color(0x1405090F),
                ),
                child: Column(children: [
                  Text('$_count',
                      style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 88,
                          color: AppColors.goldLight)),
                  const SizedBox(height: 6),
                  Text('SUBHAN ALLAH', style: AppText.eyebrow.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('tap to remember Allah',
                      style: AppText.bodyMuted.copyWith(fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            for (final e in const [
              ('Qur\u2019an', 'Read and listen', Icons.menu_book_outlined, AppRoutes.quran),
              ('Prayer times', 'When to pray today', Icons.access_time, AppRoutes.prayerTimes),
              ('Daily Duas', 'Prayers for morning and evening', Icons.wb_twilight, AppRoutes.adhkar),
              ('For Your Heart', 'How do you feel today?', Icons.favorite_border, AppRoutes.feelings),
              ('Comfort (Sakina)', 'Rest here a while', Icons.self_improvement, AppRoutes.sakina),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FocusableTap(
                  onTap: () => context.open(e.$4),
                  borderRadius: 16,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: tight ? 12 : 18, vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      color: const Color(0x0F05090F),
                    ),
                    child: Row(children: [
                      Icon(e.$3, size: tight ? 28 : 34, color: AppColors.goldLight),
                      SizedBox(width: tight ? 12 : 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.$1, style: AppText.body.copyWith(
                              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.goldLight)),
                          const SizedBox(height: 2),
                          Text(e.$2, style: AppText.bodyMuted.copyWith(fontSize: 14)),
                        ],
                      )),
                      if (!tight)
                        const Icon(Icons.chevron_right, color: AppColors.gold, size: 28),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
