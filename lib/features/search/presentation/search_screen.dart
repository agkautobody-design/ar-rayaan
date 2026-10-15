import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/domain/adhkar_models.dart';
import '../../hadith/application/hadith_providers.dart';
import '../../hadith/domain/hadith_models.dart';
import '../../stories/data/stories_repository.dart';
import '../../stories/domain/story.dart';

/// FIND ANYTHING — one search across every shelf: the 11 story packs
/// (Prophets, Seerah, Khutbahs, Daily Duas, Modern Hadith…), the Forty
/// Hadith of an-Nawawi, and the Hisn al-Muslim adhkar.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchState();
}

class _Hit {
  const _Hit({
    required this.shelf,
    required this.title,
    required this.kicker,
    required this.icon,
    required this.open,
  });

  final String shelf;
  final String title;
  final String kicker;
  final IconData icon;
  final void Function() open;
}

class _SearchState extends ConsumerState<SearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(storiesProvider);
    final hadithAsync = ref.watch(hadithCollectionProvider);
    final adhkarAsync = ref.watch(adhkarSetsProvider);
    final loading = storiesAsync.isLoading ||
        hadithAsync.isLoading ||
        adhkarAsync.isLoading;

    final stories = storiesAsync.value ?? const <Story>[];
    final hadiths = hadithAsync.value ?? const <Hadith>[];
    final sets = adhkarAsync.value ?? const <AdhkarSet>[];

    final hits = <_Hit>[];
    if (_q.length >= 2) {
      for (final s in stories) {
        if (s.title.toLowerCase().contains(_q) ||
            s.subtitle.toLowerCase().contains(_q) ||
            s.kicker.toLowerCase().contains(_q) ||
            (s.chapters.isNotEmpty &&
                s.chapters.first.body.toLowerCase().contains(_q))) {
          hits.add(_Hit(
            shelf: 'STORY',
            title: s.title,
            kicker: s.kicker,
            icon: Icons.auto_stories_outlined,
            open: () => context.go(AppRoutes.storyReader, extra: s),
          ));
        }
      }
      for (final h in hadiths) {
        if (h.english.toLowerCase().contains(_q) ||
            h.arabic.contains(_q)) {
          hits.add(_Hit(
            shelf: 'HADITH',
            title: 'Hadith ${h.number} — an-Nawawi 40',
            kicker: h.english.length > 90
                ? '${h.english.substring(0, 90)}…'
                : h.english,
            icon: Icons.format_quote_outlined,
            open: () => context.push(AppRoutes.hadith),
          ));
        }
      }
      for (final set in sets) {
        for (final d in set.items) {
          final t = d.translation ?? '';
          if (t.toLowerCase().contains(_q) || d.arabic.contains(_q)) {
            hits.add(_Hit(
              shelf: 'DHIKR',
              title: set.titleEn,
              kicker: t.length > 90 ? '${t.substring(0, 90)}…' : t,
              icon: Icons.volunteer_activism_outlined,
              open: () => context.push(AppRoutes.adhkar),
            ));
          }
        }
      }
    }

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
                  hintText: 'Search every shelf — a name, a meaning, a theme…',
                  prefixIcon: Icon(Icons.search, color: AppColors.gold),
                ),
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 14),
              if (_q.length < 2)
                GlassCard(
                    child: Text(
                        'Try "Yusuf", "patience", "before sleep", "Bismillah" — the story packs, the Forty Hadith, and the adhkar all answer here.',
                        style: AppText.bodyMuted.copyWith(height: 1.6)))
              else if (loading)
                const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.gold))
              else if (hits.isEmpty)
                GlassCard(
                    child: Text(
                        'Nothing on any shelf matches "$_q" yet — ask Hādi, he may know.',
                        style: AppText.bodyMuted))
              else
                Column(children: [
                  Text('${hits.length} FOUND', style: AppText.eyebrow),
                  const SizedBox(height: 8),
                  for (final h in hits.take(40))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        onTap: h.open,
                        child: Row(children: [
                          Icon(h.icon, size: 17, color: AppColors.goldLight),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.shelf,
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 9, letterSpacing: 1.5),
                              ),
                              Text(h.title,
                                  style: AppText.body.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                              Text(h.kicker,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.bodyMuted
                                      .copyWith(fontSize: 10.5)),
                            ],
                          )),
                          const Icon(Icons.chevron_right,
                              color: AppColors.gold, size: 16),
                        ]),
                      ),
                    ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
