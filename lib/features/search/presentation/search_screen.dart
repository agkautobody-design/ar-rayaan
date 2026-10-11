import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../stories/data/stories_repository.dart';
import '../../stories/domain/story.dart';

/// FIND ANYTHING — one search across every shelf: stories, duas, hadiths,
/// khutbahs, by title, meaning, or theme. The answer to "I can't find it."
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchState();
}

class _SearchState extends ConsumerState<SearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Find Anything', close: true),
              TextField(
                autofocus: true,
                style: AppText.body,
                decoration: const InputDecoration(
                  hintText: 'Search every shelf — a name, a meaning, a theme\u2026',
                  prefixIcon: Icon(Icons.search, color: AppColors.gold),
                ),
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 14),
              if (_q.length < 2)
                GlassCard(child: Text(
                    'Try \\"Yusuf\\", \\"anxiety\\", \\"gratitude\\", \\"how to pray\\", \\"Arafah\\" — every story, dua, sermon, and guide answers here.',
                    style: AppText.bodyMuted.copyWith(height: 1.6)))
              else
                stories.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.gold)),
                  error: (e, _) => Text('Could not search right now.',
                      style: AppText.bodyMuted),
                  data: (all) {
                    final hits = all.where((s) =>
                        s.title.toLowerCase().contains(_q) ||
                        s.subtitle.toLowerCase().contains(_q) ||
                        (s.chapters.isNotEmpty && s.chapters.first.body
                            .toLowerCase().contains(_q))).toList();
                    if (hits.isEmpty) {
                      return GlassCard(child: Text(
                          'Nothing on the shelves matches \\"\$_q\\" yet — ask H\u0101di, he may know.',
                          style: AppText.bodyMuted));
                    }
                    return Column(children: [
                      Text('\${hits.length} FOUND', style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      for (final s in hits.take(30))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            onTap: () => context.go(
                                AppRoutes.storyReader, extra: s),
                            child: Row(children: [
                              const Icon(Icons.auto_stories_outlined,
                                  size: 17, color: AppColors.goldLight),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.title, style: AppText.body.copyWith(
                                      fontSize: 13.5, fontWeight: FontWeight.w600)),
                                  Text(s.kicker,
                                      style: AppText.bodyMuted.copyWith(fontSize: 10)),
                                ],
                              )),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.gold, size: 16),
                            ]),
                          ),
                        ),
                    ]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
