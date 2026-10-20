import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../hadi/grounding/corpus.dart';
import '../../hadi/grounding/passage.dart';
import '../../sakina/presentation/widgets/need_help_button.dart';

/// Elder Care - a gentle, large-type room: big buttons, big words.
class ElderCareScreen extends ConsumerStatefulWidget {
  const ElderCareScreen({super.key});
  @override
  ConsumerState<ElderCareScreen> createState() => _ElderCareState();
}

class _ElderCareState extends ConsumerState<ElderCareScreen> {
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

  Future<void> _confirmReset() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Start the count again?'),
        content: const Text('The count will go back to 0.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start again'),
          ),
        ],
      ),
    );
    if (ok == true) await _reset();
  }

  @override
  Widget build(BuildContext context) {
    final Passage? kursi =
        ref.watch(hadiCorpusProvider).valueOrNull?.resolve('q:2:255');
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
                Text('tap to count',
                    style: AppText.bodyMuted.copyWith(fontSize: 14)),
              ]),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _confirmReset,
              child: Text('Start the count again',
                  style: AppText.bodyMuted.copyWith(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 10),
          const Center(child: NeedHelpNowButton(large: true)),
          const SizedBox(height: 14),
          if (kursi != null)
            GlassCard(
              child: Column(children: [
                Text('AYAT AL-KURSI \u00b7 ${kursi.reference.toUpperCase()}',
                    style: AppText.eyebrow.copyWith(fontSize: 12)),
                const SizedBox(height: 10),
                Text(
                  kursi.arabic ?? '',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 26, height: 2,
                      color: Color(0xFFEAD9A8)),
                ),
                const SizedBox(height: 8),
                Text(kursi.english,
                    textAlign: TextAlign.center,
                    style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.6)),
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
