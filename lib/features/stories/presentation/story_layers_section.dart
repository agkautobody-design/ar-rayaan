import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/core/open_link.dart';

import '../../../app/core/safe_url.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../quran/application/quran_providers.dart';
import '../../quran/domain/quran_models.dart';
import '../../quran/domain/quran_texts.dart';
import '../data/story_layers_repository.dart';
import '../domain/story_layers.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// "Go deeper": the layers beneath a story, each kind kept apart and
/// labelled. Renders nothing when the story has no layers file, so every
/// existing story reads exactly as before.
class StoryLayersSection extends ConsumerWidget {
  const StoryLayersSection({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<StoryLayers?> async = ref.watch(storyLayersProvider(storyId));
    final StoryLayers? layers = async.valueOrNull;
    if (layers == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('GO DEEPER', style: AppText.eyebrow),
              const SizedBox(height: 6),
              Text(
                'What lies beneath this story, kept in separate layers so you '
                'always know what you are reading.',
                style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 10),
              const ReviewBanner(),
              const SizedBox(height: 12),
              if (layers.quran.isNotEmpty)
                _LayerBlock(
                  key: const ValueKey<String>('layer-quran'),
                  title: 'Qur’an',
                  subtitle: '${layers.quran.length} passages from the app’s own text',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final LayerQuranRef r in layers.quran)
                        _QuranPassage(passage: r),
                    ],
                  ),
                ),
              if (layers.hadith.isNotEmpty)
                _LayerBlock(
                  key: const ValueKey<String>('layer-hadith'),
                  title: 'Hadith',
                  subtitle:
                      '${layers.hadith.length} from the six books, each with its grade and who graded it',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final LayerHadith h in layers.hadith)
                        _HadithCard(hadith: h),
                    ],
                  ),
                ),
              if (layers.scholarly.isNotEmpty)
                _LayerBlock(
                  key: const ValueKey<String>('layer-scholarly'),
                  title: 'What scholars wrote',
                  subtitle: 'Named works, labelled as explanation, not revelation',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final LayerScholarly s in layers.scholarly)
                        _ScholarlyCard(item: s),
                    ],
                  ),
                ),
              if (layers.differences.isNotEmpty)
                _LayerBlock(
                  key: const ValueKey<String>('layer-differences'),
                  title: 'Where scholars differ',
                  subtitle: kDisputedLabel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final LayerDifference d in layers.differences)
                        _DifferenceCard(item: d),
                    ],
                  ),
                ),
              if (layers.earlier.isNotEmpty)
                _LayerBlock(
                  key: const ValueKey<String>('layer-earlier'),
                  title: 'Earlier accounts',
                  subtitle: kEarlierBadge,
                  child: _EarlierAccounts(items: layers.earlier),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Scholar review needed" - there is no named reviewer yet.
class ReviewBanner extends StatelessWidget {
  const ReviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.sand.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.sand.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline, size: 16, color: AppColors.sand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$kReviewBanner. Every reference was checked against its source '
              'text, but no named scholar has reviewed this yet. For a ruling, '
              'ask a scholar.',
              style: AppText.bodyMuted.copyWith(fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small outlined label ("Hadith", "Disputed in the sources", ...).
class LayerChip extends StatelessWidget {
  const LayerChip({super.key, required this.text, this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final Color c = strong ? AppColors.goldLight : AppColors.sand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, letterSpacing: 0.3, color: c),
      ),
    );
  }
}

/// A collapsible block with a header at least 48 logical pixels tall.
class _LayerBlock extends StatefulWidget {
  const _LayerBlock({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  State<_LayerBlock> createState() => _LayerBlockState();
}

class _LayerBlockState extends State<_LayerBlock> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              button: true,
              expanded: _open,
              label: widget.title,
              child: FocusRing(borderRadius: 14, child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _open = !_open),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.goldLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                style: AppText.bodyMuted.copyWith(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _open ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: widget.child,
              ),
          ],
        ),
      ),
    );
  }
}

/// One passage, read from the bundled Qur'an (never copied into a pack).
class _QuranPassage extends ConsumerWidget {
  const _QuranPassage({required this.passage});

  final LayerQuranRef passage;

  @override
  Widget build(BuildContext context, WidgetRef wref) {
    final AsyncValue<Surah> surah = wref.watch(surahProvider(passage.surah));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const LayerChip(text: 'Qur’an', strong: true),
              Text(passage.label, style: AppText.eyebrow),
            ],
          ),
          if (passage.note != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(passage.note!, style: AppText.bodyMuted.copyWith(fontSize: 13)),
          ],
          const SizedBox(height: 6),
          surah.when(
            loading: () => const SizedBox(height: 24),
            error: (Object e, StackTrace s) => Text(
              'This passage could not be loaded.',
              style: AppText.bodyMuted,
            ),
            data: (Surah s) {
              final List<Ayah> ayahs = <Ayah>[
                for (final Ayah a in s.ayahs)
                  if (a.number >= passage.from && a.number <= passage.to) a,
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final Ayah a in ayahs) ...<Widget>[
                    Text(
                      a.arabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        height: 1.9,
                        color: Color(0xFFEAD9A8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.meta.number}:${a.number}  ${a.english}',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.sand,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'Arabic: Tanzil (Uthmani). English: ${(wref.watch(quranTextsProvider).value ?? QuranTexts.fallback).translation.short}.',
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.hadith});

  final LayerHadith hadith;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const LayerChip(text: 'Hadith', strong: true),
              Text(hadith.reference, style: AppText.eyebrow),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              LayerChip(text: 'Grade: ${hadith.grade}'),
              LayerChip(text: 'Graded by: ${hadith.grader}'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Narrated by ${hadith.narrator}. ${hadith.summary}',
            style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.sand),
          ),
          if (hadith.note != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              hadith.note!,
              style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Summary in our own words. Reference checked on sunnah.com, '
            '${hadith.verified}.',
            style: AppText.bodyMuted.copyWith(fontSize: 12),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              alignment: Alignment.centerLeft,
            ),
            onPressed: () => openLinkWithFeedback(
              context,
              SafeUrl.web(hadith.sunnahUrl),
              message: 'Could not open sunnah.com. The reference above is the '
                  'hadith to look up.',
            ),
            child: const Text(
              'Read the full text on sunnah.com',
              style: TextStyle(color: AppColors.goldLight, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScholarlyCard extends StatelessWidget {
  const _ScholarlyCard({required this.item});

  final LayerScholarly item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LayerChip(text: 'Scholarly explanation — not revelation'),
          const SizedBox(height: 6),
          Text(
            '${item.work} (${item.author}), ${item.locator}',
            style: AppText.eyebrow,
          ),
          const SizedBox(height: 4),
          Text(
            item.summary,
            style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.sand),
          ),
        ],
      ),
    );
  }
}

class _DifferenceCard extends StatelessWidget {
  const _DifferenceCard({required this.item});

  final LayerDifference item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LayerChip(text: kDisputedLabel, strong: true),
          const SizedBox(height: 6),
          Text(
            item.question,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.sand,
            ),
          ),
          const SizedBox(height: 6),
          for (final LayerView v in item.views)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(v.who, style: AppText.eyebrow),
                  Text(
                    v.view,
                    style: const TextStyle(
                        fontSize: 15, height: 1.55, color: AppColors.sand),
                  ),
                  Text(
                    'In: ${v.work}',
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          if (item.note != null)
            Text(
              item.note!,
              style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
            ),
        ],
      ),
    );
  }
}

/// Earlier accounts: the fixed badge, the three-class rule, then each item
/// under its class. Contradicted items are named and explained, not told.
class _EarlierAccounts extends StatelessWidget {
  const _EarlierAccounts({required this.items});

  final List<EarlierAccount> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const EarlierBadge(),
        const SizedBox(height: 8),
        Text(
          'These come from before the Qur’an (the Bible and Jewish or '
          'Christian tradition). Relating them is permitted (Sahih al-Bukhari '
          '3461), but we neither believe nor disbelieve them outright '
          '(Sahih al-Bukhari 4485). They are sorted into three classes: confirmed by our '
          'sources, silent (we neither believe nor disbelieve them), or '
          'contradicted, which are not told.',
          style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 10),
        for (final EarlierAccount e in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const EarlierBadge(compact: true),
                const SizedBox(height: 4),
                LayerChip(text: e.cls.label, strong: e.cls == EarlierClass.confirmed),
                const SizedBox(height: 4),
                Text(e.origin, style: AppText.eyebrow),
                Text(
                  e.claim,
                  style: const TextStyle(
                      fontSize: 15, height: 1.55, color: AppColors.sand),
                ),
                const SizedBox(height: 2),
                Text(
                  e.ruling,
                  style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                ),
                Text(
                  'Basis: ${e.basis}',
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The fixed badge: always exactly [kEarlierBadge], never reworded.
class EarlierBadge extends StatelessWidget {
  const EarlierBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.destructive.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded,
              size: compact ? 14 : 18, color: AppColors.destructive),
          const SizedBox(width: 6),
          Text(
            kEarlierBadge.toUpperCase(),
            style: TextStyle(
              fontSize: compact ? 12 : 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.destructive,
            ),
          ),
        ],
      ),
    );
  }
}
