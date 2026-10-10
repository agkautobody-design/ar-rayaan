import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// ELDER MODE - the whole home, simplified. Giant words, three doors,
/// nothing else. Once a family turns this on, the app opens here every time
/// until it is turned off. The young set it up; the old simply use it.
class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeState();
}

class _ElderHomeState extends State<ElderHomeScreen> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final p = await SharedPreferences.getInstance();
      await p.setBool('ar.elder.mode', true);
      if (mounted) setState(() => _count = p.getInt('ar.elder.dhikr') ?? 0);
    });
  }

  Future<void> _tap() async {
    setState(() => _count++);
    final p = await SharedPreferences.getInstance();
    await p.setInt('ar.elder.dhikr', _count);
  }

  Future<void> _exit() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ar.elder.mode', false);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
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
              TextButton(
                onPressed: _exit,
                child: Text('Exit', style: AppText.bodyMuted.copyWith(fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _tap,
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
                  Text('tap to remember Allah \u00b7 hold nothing back',
                      style: AppText.bodyMuted.copyWith(fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            for (final e in const [
              ('Daily Duas', 'Prayers for morning and evening', Icons.wb_twilight, AppRoutes.stories),
              ('For Your Heart', 'How do you feel today?', Icons.favorite_border, AppRoutes.feelings),
              ('Comfort (Sakina)', 'Rest here a while', Icons.self_improvement, AppRoutes.sakina),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => context.go(e.$4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      color: const Color(0x0F05090F),
                    ),
                    child: Row(children: [
                      Icon(e.$3, size: 34, color: AppColors.goldLight),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.$1, style: AppText.body.copyWith(
                              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.goldLight)),
                          const SizedBox(height: 2),
                          Text(e.$2, style: AppText.bodyMuted.copyWith(fontSize: 14)),
                        ],
                      )),
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
