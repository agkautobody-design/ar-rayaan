import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/core/content/content_sync.dart';

class Guide {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final List<String> steps;
  final List<String> sources;
  final String? madhhabNote;

  const Guide({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.sources,
    this.madhhabNote,
  });

  factory Guide.fromJson(Map<String, dynamic> j) => Guide(
        id: j['id'] as String,
        category: j['category'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        steps: (j['steps'] as List<dynamic>).cast<String>(),
        sources: (j['sources'] as List<dynamic>).cast<String>(),
        madhhabNote: j['madhhabNote'] as String?,
      );
}

final guidesProvider = FutureProvider<List<Guide>>((ref) async {
  final raw = await ContentSync.load('guides/guides.json');
  final list = json.decode(raw) as List<dynamic>;
  return list.map((e) => Guide.fromJson(e as Map<String, dynamic>)).toList();
});

class HudaScreen extends ConsumerWidget {
  const HudaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guides = ref.watch(guidesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: guides.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Text('Could not load the guides.', style: AppText.bodyMuted),
        ),
        data: (all) {
          final cats = <String>[];
          for (final g in all) {
            if (!cats.contains(g.category)) cats.add(g.category);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Huda', close: true),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text('GUIDES IN THE PROPHET\u2019S WAY', style: AppText.eyebrow),
              ),
              for (final cat in cats) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                  child: Text(cat.toUpperCase(), style: AppText.eyebrow),
                ),
                for (final g in all.where((x) => x.category == cat))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      onTap: () =>
                          context.go(AppRoutes.hudaGuide, extra: g),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.title, style: AppText.titleMedium),
                          const SizedBox(height: 3),
                          Text(g.subtitle, style: AppText.bodyMuted),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class GuideScreen extends StatelessWidget {
  final Guide guide;
  const GuideScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          ScreenHeader(title: guide.category, close: true),
          const SizedBox(height: 6),
          Text(
            guide.title,
            style: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(guide.subtitle, style: AppText.bodyMuted),
          const SizedBox(height: 18),
          for (var i = 0; i < guide.steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      guide.steps[i],
                      style: AppText.body.copyWith(height: 1.55, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
            if (i < guide.steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 4, bottom: 8),
                child: Container(
                  width: 1,
                  height: 10,
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
          if (guide.madhhabNote != null) ...[
            GlassCard(
              strong: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MADHHAB NOTE', style: AppText.eyebrow),
                  const SizedBox(height: 6),
                  Text(
                    guide.madhhabNote!,
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SOURCES', style: AppText.eyebrow),
                const SizedBox(height: 6),
                for (final s in guide.sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(s, style: AppText.bodyMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
