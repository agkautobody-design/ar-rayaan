import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';

/// Elder Care - a gentle, large-type room: big buttons, big words.
class ElderCareScreen extends StatefulWidget {
  const ElderCareScreen({super.key});
  @override
  State<ElderCareScreen> createState() => _ElderCareState();
}

class _ElderCareState extends State<ElderCareScreen> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final p = await SharedPreferences.getInstance();
      if (mounted) setState(() => _count = p.getInt('ar.elder.dhikr') ?? 0);
    });
  }

  Future<void> _tap() async {
    setState(() => _count++);
    final p = await SharedPreferences.getInstance();
    await p.setInt('ar.elder.dhikr', _count);
  }

  Future<void> _reset() async {
    setState(() => _count = 0);
    final p = await SharedPreferences.getInstance();
    await p.setInt('ar.elder.dhikr', 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const ScreenHeader(title: 'Elder Care', close: true),
          Center(child: Text('BIG WORDS \u00b7 GENTLE HEARTS', style: AppText.eyebrow)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _tap,
            onLongPress: _reset,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
              ),
              child: Column(children: [
                Text('$_count',
                    style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 64,
                        color: AppColors.goldLight)),
                const SizedBox(height: 4),
                Text('SUBHAN ALLAH', style: AppText.eyebrow.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('tap to count \u00b7 hold to reset',
                    style: AppText.bodyMuted.copyWith(fontSize: 11)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(children: [
              Text('AYAT AL-KURSI \u2014 THE PROTECTION',
                  style: AppText.eyebrow.copyWith(fontSize: 12)),
              const SizedBox(height: 10),
              Text(
                '\u0627\u0644\u0644\u0651\u064e\u0647\u064f \u0644\u0627 \u0625\u0650\u0644\u064e\u0647\u064e \u0625\u0650\u0644\u0651\u064e\u0627 \u0647\u064f\u0648\u064e \u0627\u0644\u062d\u064e\u064a\u064f\u0651 \u0627\u0644\u0642\u064e\u064a\u064f\u0651\u0648\u0645\u064f',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 26, height: 2,
                    color: Color(0xFFEAD9A8)),
              ),
              const SizedBox(height: 6),
              Text('Hold to it morning and evening.',
                  textAlign: TextAlign.center, style: AppText.bodyMuted),
            ]),
          ),
          const SizedBox(height: 12),
          for (final e in const [
            ('Morning & Evening Duas', Icons.wb_sunny_outlined, AppRoutes.stories),
            ('For Your Heart \u00b7 how do you feel?', Icons.favorite_border, AppRoutes.feelings),
            ('Comfort Rooms (Sakina)', Icons.self_improvement, AppRoutes.sakina),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                onTap: () => context.go(e.$3),
                child: Row(children: [
                  Icon(e.$2, size: 26, color: AppColors.goldLight),
                  const SizedBox(width: 14),
                  Expanded(child: Text(e.$1,
                      style: AppText.body.copyWith(fontSize: 17, fontWeight: FontWeight.w600))),
                  const Icon(Icons.chevron_right, color: AppColors.gold, size: 22),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
