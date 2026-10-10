import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';

class FinLesson {
  final String id, title, kicker, subtitle;
  final String body;
  final String familyQuestion;
  const FinLesson({required this.id, required this.title, required this.kicker,
      required this.subtitle, required this.body, required this.familyQuestion});
  factory FinLesson.fromJson(Map<String, dynamic> j) => FinLesson(
      id: j['id'], title: j['title'], kicker: j['kicker'], subtitle: j['subtitle'],
      body: (j['chapters'] as List).first['body'] as String,
      familyQuestion: j['familyQuestion']);
}

final rayaanLessonsProvider = FutureProvider<List<FinLesson>>((ref) async {
  final raw = await rootBundle.loadString('assets/finance/rayaan_stocks.json');
  final d = json.decode(raw) as Map<String, dynamic>;
  return (d['lessons'] as List<dynamic>)
      .map((e) => FinLesson.fromJson(e as Map<String, dynamic>)).toList();
});

/// RAYAAN STOCKS — the halal financial learning module. Teaches the market
/// as fact: what a stock is, how to read a company, the three screens,
/// purification, market forces, crypto's line, the scholars' day-trading
/// difference, and the trader's craft. Live prices arrive with a market key.
class RayaanStocksScreen extends ConsumerWidget {
  const RayaanStocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(rayaanLessonsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: lessons.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(
                child: Text('Could not load the course.', style: AppText.bodyMuted)),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                const ScreenHeader(title: 'Rayaan Stocks', close: true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: GestureDetector(
                    onTap: () => context.go('/finance/floor'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.candlestick_chart_outlined, color: AppColors.goldLight, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('THE TRADING FLOOR', style: AppText.eyebrow.copyWith(color: AppColors.goldLight)),
                          Text('Practice with \$100,000 paper money \u00b7 budget \u00b7 Hajj savings',
                              style: AppText.bodyMuted.copyWith(fontSize: 10.5)),
                        ])),
                        const Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
                      ]),
                    ),
                  ),
                ),
                Padding(padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text('WEALTH, TAUGHT AS FACT', style: AppText.eyebrow)),
                Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                    child: Text(
                        'The complete halal investment course: stocks, screens, purification, crypto\u2019s line, day trading\u2019s difference, and the trader\u2019s craft. Knowledge first; live market data arrives with a data key \u2014 this course teaches you what to do with it when it does.',
                        style: AppText.bodyMuted)),
                for (final l in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      onTap: () => context.go('/finance/rayaan/${l.id}'),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.4)),
                          ),
                          child: Text('${list.indexOf(l) + 1}',
                              style: TextStyle(color: AppColors.goldLight, fontSize: 15)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.kicker.split('· ').last.toUpperCase(),
                                style: AppText.eyebrow.copyWith(fontSize: 9)),
                            Text(l.title, style: AppText.body.copyWith(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(l.subtitle, style: AppText.bodyMuted.copyWith(fontSize: 11)),
                          ],
                        )),
                        const Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
                      ]),
                    ),
                  ),
                const SizedBox(height: 6),
                GlassCard(strong: true, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('THE HALAL LAW OF THIS MODULE', style: AppText.eyebrow),
                    const SizedBox(height: 8),
                    Text(
                        'No short-selling \u00b7 no margin or leverage \u00b7 no futures \u00b7 no weapons, alcohol, gambling, riba-lending, pork, or adult-content revenue \u00b7 debts under the ~30% screen \u00b7 interest under 5%, purified by giving \u00b7 zakat 2.5% yearly \u00b7 a conscience screen for what your heart cannot carry. Educational \u2014 for real portfolios, consult a qualified Sharia advisor.',
                        style: AppText.bodyMuted.copyWith(height: 1.6, fontSize: 12)),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FinLessonScreen extends ConsumerWidget {
  final String lessonId;
  const FinLessonScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(rayaanLessonsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: lessons.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: Text('Could not load the lesson.', style: AppText.bodyMuted)),
        data: (list) {
          final l = list.where((x) => x.id == lessonId).firstOrNull;
          if (l == null) return Center(
              child: Text('Lesson not found.', style: AppText.bodyMuted));
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  ScreenHeader(title: l.kicker, close: true),
                  const SizedBox(height: 8),
                  Text(l.title, style: const TextStyle(fontFamily: 'PlayfairDisplay',
                      fontSize: 26, color: AppColors.goldLight)),
                  const SizedBox(height: 4),
                  Text(l.subtitle, style: AppText.bodyMuted),
                  const SizedBox(height: 16),
                  GlassCard(child: Text(l.body,
                      style: AppText.body.copyWith(height: 1.75, fontSize: 14.5))),
                  const SizedBox(height: 12),
                  GlassCard(strong: true, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SIT TOGETHER', style: AppText.eyebrow),
                      const SizedBox(height: 6),
                      Text(l.familyQuestion,
                          style: AppText.body.copyWith(height: 1.6, fontSize: 14)),
                    ],
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
