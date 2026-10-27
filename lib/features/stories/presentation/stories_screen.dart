import '../../../app/core/scholar_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../downloads/presentation/pack_save_row.dart';
import '../../../app/core/web_offline.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/router.dart';
import '../data/stories_repository.dart';
import '../data/story_layers_repository.dart';
import '../domain/story.dart';
import '../domain/story_length.dart';
import 'source_label_chip.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// "Short reads" filter on the library (stories of about a minute or less).
final AutoDisposeStateProvider<bool> shortReadsOnlyProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  static const _collections = [
    ('prophets', 'Stories of the Prophets', 'Peace be upon them all'),
    ('women', 'Women of Islam', 'The hearts that carried the light'),
    ('seerah', 'The Seerah', 'The life of the Prophet \u0635\u0644\u0649 \u0627\u0644\u0644\u0647 \u0639\u0644\u064a\u0647 \u0648\u0633\u0644\u0645'),
    ('companions', 'The Companions', 'The generation that held the light'),
    ('ghayb', 'Al-Ghayb — The Unseen', 'Angels, jinn, the Last Day, and the 2am questions'),
    ('signs', 'Signs & the Last Day', 'What is coming, with certainty'),
    ('tales', 'Tales of the Ummah', 'Stories of the generations between'),
    ('khutbahs', 'Khutbahs', 'Sermons for the classics and for today'),
    ('modernhadith', 'Hadiths for Our Times', 'The pressures of this age, answered'),
    ('dailyduas', 'Daily Duas', 'For waking, eating, travel, hardship, and home'),
    ('newmuslim', 'The New Muslim Path', 'Thirty gentle days, one step at a time'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);
    final bool shortOnly = ref.watch(shortReadsOnlyProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: stories.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FocusableTap(
              onTap: () async {
                // Clear the content-sync cache and rebuild the library.
                final prefs = await SharedPreferences.getInstance();
                for (final k in prefs.getKeys()) {
                  if (k.startsWith('cp_') || k.startsWith('cv_')) {
                    await prefs.remove(k);
                  }
                }
                ref.invalidate(storiesProvider);
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('The library could not load.', style: AppText.body),
                const SizedBox(height: 6),
                Text('$e', textAlign: TextAlign.center,
                    style: AppText.bodyMuted.copyWith(fontSize: 12)),
                const SizedBox(height: 10),
                Text('TAP TO RETRY',
                    style: AppText.eyebrow.copyWith(color: AppColors.goldLight)),
              ]),
            ),
          ),
        ),
        data: (all) {
          final Set<String> deeper =
              ref.watch(storyIdsWithLayersProvider).valueOrNull ?? <String>{};
          final StoriesRepository repo = ref.read(storiesRepositoryProvider);
          final List<String> failedPacks = repo.failedPacks;
          Future<void> retry() async {
            final prefs = await SharedPreferences.getInstance();
            for (final k in prefs.getKeys()) {
              if (k.startsWith('cp_') || k.startsWith('cv_')) {
                await prefs.remove(k);
              }
            }
            ref.invalidate(storiesProvider);
          }
          // Head rows are cheap and few; the shelves (hundreds of story
          // cards) are built lazily, only while they are near the viewport.
          final List<Widget> head = <Widget>[
            const ScreenHeader(title: 'Stories', close: true),
            const ScholarReviewNote(
              reviewKey: 'story',
              padding: const EdgeInsets.only(bottom: 8),
            ),
            if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: FocusableTap(
                  onTap: retry,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                        'The shelves are empty — the packs did not load. '
                        '${WebOffline.needsInternet('The story library')}',
                        textAlign: TextAlign.center,
                        style: AppText.body),
                    const SizedBox(height: 8),
                    Text('TAP TO RETRY',
                        style: AppText.eyebrow
                            .copyWith(color: AppColors.goldLight)),
                  ]),
                ),
              )
            else if (failedPacks.isNotEmpty)
              // Some shelves are missing: say so plainly (no debug counter).
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: FocusableTap(
                  onTap: retry,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${failedPacks.length} of ${repo.packCount} shelves '
                        'could not load. '
                        '${WebOffline.needsInternet('The full library')}',
                        style: AppText.bodyMuted.copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 4),
                      Text('TAP TO RETRY',
                          style: AppText.eyebrow
                              .copyWith(color: AppColors.goldLight)),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'READ WITH YOUR HEART',
                style: AppText.eyebrow,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  FilterChip(
                    key: const Key('stories-short-reads'),
                    label: const Text('Short reads (about a minute)'),
                    selected: shortOnly,
                    onSelected: (bool v) =>
                        ref.read(shortReadsOnlyProvider.notifier).state = v,
                  ),
                  ActionChip(
                    key: const Key('stories-for-children'),
                    avatar: const Icon(Icons.child_care, size: 18),
                    label: const Text('For children'),
                    onPressed: () => context.open(AppRoutes.kids),
                  ),
                ],
              ),
            ),
            // What the gold badge on each card means, in the app's own words.
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '$kLabelEstablished: ${storyLabelMeaning(kLabelEstablished)}',
                style: AppText.bodyMuted.copyWith(fontSize: 12.5, height: 1.45),
              ),
            ),
            // Browser only: save the story packs for offline use.
            const PackSaveRow(
              packIds: <String>[
                'text-seerah',
                'text-prophets',
                'text-stories',
                'text-duas',
                'text-hadith',
              ],
            ),
          ];
          final List<_ShelfRow> rows = _shelfRows(
            shortOnly ? all.where((Story s) => s.isShortRead).toList() : all,
          );
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: head.length + rows.length,
            itemBuilder: (BuildContext context, int index) {
              if (index < head.length) return head[index];
              final _ShelfRow row = rows[index - head.length];
              final Story? story = row.story;
              if (story == null) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.title, style: AppText.titleMedium),
                      const SizedBox(height: 2),
                      Text(row.subtitle, style: AppText.bodyMuted),
                    ],
                  ),
                );
              }
              return _StoryCard(story: story, hasLayers: deeper.contains(story.id));
            },
          );
        },
      ),
    );
  }

  /// Flattens the shelves into one list of rows (a heading row, then one
  /// row per story) in a single pass over [all].
  static List<_ShelfRow> _shelfRows(List<Story> all) {
    final Map<String, List<Story>> grouped = <String, List<Story>>{};
    for (final Story s in all) {
      (grouped[s.collection] ??= <Story>[]).add(s);
    }
    final List<_ShelfRow> rows = <_ShelfRow>[];
    for (final (key, title, subtitle) in _collections) {
      final List<Story>? list = grouped[key];
      if (list == null || list.isEmpty) continue;
      rows.add(_ShelfRow.heading(title, subtitle));
      for (final Story s in list) {
        rows.add(_ShelfRow.story(s));
      }
    }
    return rows;
  }
}

class _ShelfRow {
  const _ShelfRow.heading(this.title, this.subtitle) : story = null;
  _ShelfRow.story(this.story)
      : title = '',
        subtitle = '';

  final String title;
  final String subtitle;
  final Story? story;
}

/// One story on a shelf. No backdrop blur: with hundreds of cards each blur
/// is its own compositing layer; the translucent fill and gold border look
/// the same on this dark background.
class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.hasLayers});

  final Story story;
  final bool hasLayers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        blur: false,
        onTap: () => context.open(AppRoutes.storyReader, extra: story),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            // On a narrow phone or at large text the honesty label and the
            // marks would squeeze the title into a sliver, so they drop under
            // the text instead of beside it.
            final bool stack = box.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(14) > 18;
            final List<Widget> marks = _marks();
            return Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 20,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(story.title, style: AppText.titleMedium),
                      Text(
                        '${story.readMinutes} min read',
                        style: AppText.caption,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        story.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMuted,
                      ),
                      if (stack) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...marks,
                            SourceLabelChip(label: story.sourceLabel),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!stack) ...[
                  const SizedBox(width: 10),
                  for (final Widget m in marks)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: m,
                    ),
                  SourceLabelChip(label: story.sourceLabel),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// The small information marks (deeper section, weak narration, unverified
  /// chapters). They are labels, not buttons.
  List<Widget> _marks() => <Widget>[
        if (hasLayers)
          const Tooltip(
            message: 'Has a Go deeper section',
            child: Icon(
              Icons.layers_outlined,
              size: 18,
              color: AppColors.goldLight,
              semanticLabel: 'Has a Go deeper section',
            ),
          ),
        if (story.hasWeakNarration)
          const Tooltip(
            message: 'Cites a weak (daif) narration',
            child: Icon(
              Icons.warning_amber_outlined,
              size: 18,
              color: Colors.orangeAccent,
              semanticLabel: 'Cites a weak narration',
            ),
          ),
        if (story.hasUnverified && !isUnverifiedLabel(story.sourceLabel))
          const Tooltip(
            message: 'Contains unverified chapters',
            child: Icon(
              Icons.report_gmailerrorred_outlined,
              size: 18,
              color: Colors.orangeAccent,
              semanticLabel: 'Contains unverified chapters',
            ),
          ),
      ];
}
