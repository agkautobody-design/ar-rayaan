/// Q&A bank — 12 curated questions with sourced answers, for the
/// moments Hadi says 'let me point you to a qualified scholar' and the
/// user wants the answer now. Every answer carries its source.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/core/content/content_sync.dart';
import 'dart:convert';

class QaEntry {
  const QaEntry({required this.q, required this.a, required this.s});

  final String q;
  final String a;
  final String s;

  factory QaEntry.fromJson(Map<String, dynamic> j) =>
      QaEntry(q: j['q'] as String, a: j['a'] as String, s: j['s'] as String);
}

final qaBankProvider = FutureProvider<List<QaEntry>>((ref) async {
  final String raw = await ContentSync.load('qa/qa_bank.json');
  final List<dynamic> list = json.decode(raw)['questions'] as List<dynamic>;
  return <QaEntry>[for (final dynamic e in list) QaEntry.fromJson(Map<String, dynamic>.from(e as Map))];
});

class QaBankScreen extends ConsumerWidget {
  const QaBankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = ref.watch(qaBankProvider);
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: bank.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(
                child: Text('The answers could not load.',
                    style: AppText.bodyMuted)),
            data: (entries) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: <Widget>[
                const ScreenHeader(title: 'Q&A', close: true),
                Text('الأسئلة',
                    style: AppText.arabic.copyWith(
                        fontSize: 28, color: AppColors.gold)),
                const SizedBox(height: 6),
                Text(
                  '${entries.length} curated questions — sourced answers for the questions every Muslim asks',
                  style: AppText.bodyMuted,
                ),
                const SizedBox(height: 18),
                for (final QaEntry e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      strong: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(e.q, style: AppText.titleMedium),
                          const SizedBox(height: 8),
                          Text(e.a, style: AppText.body.copyWith(
                              height: 1.65, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(e.s, style: AppText.bodyMuted.copyWith(
                              fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                Text(
                  'For questions beyond this bank, ask Hadi — he will point you to a qualified scholar, or your local masjid. These answers are starting points, not final rulings for your situation.',
                  style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
