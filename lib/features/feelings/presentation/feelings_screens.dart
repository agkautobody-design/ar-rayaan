import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/content/content_sync.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../stories/data/stories_repository.dart';
import '../../stories/domain/story.dart';

class Feeling {
  final String id;
  final String feeling;
  final String line;
  final DuaBlock dua;
  final List<FeelingItem> items;

  const Feeling({
    required this.id,
    required this.feeling,
    required this.line,
    required this.dua,
    required this.items,
  });

  factory Feeling.fromJson(Map<String, dynamic> j) => Feeling(
        id: j['id'] as String,
        feeling: j['feeling'] as String,
        line: j['line'] as String,
        dua: DuaBlock.fromJson(j['dua'] as Map<String, dynamic>),
        items: (j['items'] as List<dynamic>)
            .map((e) => FeelingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DuaBlock {
  final String arabic;
  final String body;
  final String source;
  const DuaBlock({required this.arabic, required this.body, required this.source});

  factory DuaBlock.fromJson(Map<String, dynamic> j) => DuaBlock(
        arabic: j['arabic'] as String,
        body: j['body'] as String,
        source: j['source'] as String,
      );
}

class FeelingItem {
  final String storyId;
  final String title;
  final String why;
  const FeelingItem({required this.storyId, required this.title, required this.why});

  factory FeelingItem.fromJson(Map<String, dynamic> j) => FeelingItem(
        storyId: j['storyId'] as String,
        title: j['title'] as String,
        why: j['why'] as String,
      );
}

final feelingsProvider = FutureProvider<List<Feeling>>((ref) async {
  final raw = await ContentSync.load('feelings/feelings.json');
  return (json.decode(raw) as List)
      .map((e) => Feeling.fromJson(e as Map<String, dynamic>))
      .toList();
});

class FeelingsScreen extends ConsumerWidget {
  const FeelingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feelings = ref.watch(feelingsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: feelings.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Text('Could not load.', style: AppText.bodyMuted),
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const ScreenHeader(title: 'For Your Heart', close: true),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('HOW ARE YOU FEELING RIGHT NOW?', style: AppText.eyebrow),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'The deen meets you where you are. Choose what is true — the dua, the stories, and the words that carry it come next.',
                style: AppText.bodyMuted,
              ),
            ),
            for (final f in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  onTap: () => context.go('${AppRoutes.feelings}/${f.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.feeling,
                        style: AppText.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(f.line, style: AppText.bodyMuted),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FeelingScreen extends ConsumerWidget {
  final String feelingId;
  const FeelingScreen({super.key, required this.feelingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feelings = ref.watch(feelingsProvider);
    final stories = ref.watch(storiesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: feelings.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Text('Could not load.', style: AppText.bodyMuted),
        ),
        data: (list) {
          final f = list.where((x) => x.id == feelingId).firstOrNull;
          if (f == null) {
            return Center(child: Text('Not found.', style: AppText.bodyMuted));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              ScreenHeader(title: f.feeling, close: true),
              const SizedBox(height: 8),
              Text(f.line, style: AppText.bodyMuted),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      f.dua.arabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 24,
                        height: 1.9,
                        color: Color(0xFFEAD9A8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      f.dua.body,
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(height: 1.6, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      f.dua.source,
                      style: AppText.bodyMuted.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('CARRY IT WITH THESE', style: AppText.eyebrow),
              const SizedBox(height: 8),
              stories.when(
                loading: () => const SizedBox(height: 40),
                error: (e, _) => const SizedBox.shrink(),
                data: (all) => Column(
                  children: [
                    for (final item in f.items)
                      Builder(builder: (ctx) {
                        final story = all
                            .where((s) => s.id == item.storyId)
                            .firstOrNull;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            onTap: story == null
                                ? null
                                : () => context.go(
                                      AppRoutes.storyReader,
                                      extra: story,
                                    ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_stories_outlined,
                                  size: 18,
                                  color: story == null
                                      ? AppColors.sand.withValues(alpha: 0.3)
                                      : AppColors.goldLight,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: AppText.body.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(item.why, style: AppText.bodyMuted),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GlassCard(
                strong: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SIT TOGETHER', style: AppText.eyebrow),
                    const SizedBox(height: 6),
                    Text(
                      'Which of these carried you — and who in your house needs the same dua tonight?',
                      style: AppText.body.copyWith(height: 1.55, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
