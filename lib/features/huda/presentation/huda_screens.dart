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
import '../../downloads/presentation/pack_save_row.dart';
import '../domain/guide_glossary.dart';

class Guide {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final List<String> steps;
  final List<String> sources;
  final String? madhhabNote;

  /// Show the Qiyam/Ruku/Sujud/Julus strip (only guides of the prayer's
  /// own movements set this in guides.json).
  final bool showPositions;

  /// Optional "GO DEEPER" block: keys why / evidence / commonMistakes.
  /// Comes from the guide's own JSON — nothing is hard-coded per title.
  final Map<String, String>? goDeeper;

  const Guide({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.sources,
    this.madhhabNote,
    this.showPositions = false,
    this.goDeeper,
  });

  factory Guide.fromJson(Map<String, dynamic> j) => Guide(
        id: j['id'] as String,
        category: j['category'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        steps: (j['steps'] as List<dynamic>).cast<String>(),
        sources: (j['sources'] as List<dynamic>).cast<String>(),
        madhhabNote: j['madhhabNote'] as String?,
        showPositions: j['showPositions'] as bool? ?? false,
        goDeeper: (j['goDeeper'] as Map<String, dynamic>?)
            ?.map((String k, dynamic v) => MapEntry<String, String>(k, '$v')),
      );
}

/// The heading a guide is filed under. The shipped pack files the Nikah and
/// the New Baby guides under "The Last Day" (a data label shared with the
/// funeral guides), which read as a wrong title on those two pages. Relabel
/// them here without touching the checksummed pack.
String guideCategoryLabel(String id, String category) =>
    (id == 'huda-nikah' || id == 'huda-baby') ? 'Family & Life Events' : category;

final guidesProvider = FutureProvider<List<Guide>>((ref) {
  // A remote pack that does not parse falls back to the bundled one.
  return ContentSync.loadParsed<List<Guide>>('guides/guides.json', (raw) {
    final list = json.decode(raw) as List<dynamic>;
    return list.map((e) => Guide.fromJson(e as Map<String, dynamic>)).toList();
  });
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
            final String c = guideCategoryLabel(g.id, g.category);
            if (!cats.contains(c)) cats.add(c);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Huda', close: true),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text('GUIDES IN THE PROPHET\u2019S WAY', style: AppText.eyebrow),
              ),
              // Browser only: save the guides for offline use.
              const PackSaveRow(packIds: <String>['text-guides']),
              for (final cat in cats) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                  child: Text(cat.toUpperCase(), style: AppText.eyebrow),
                ),
                for (final g in all.where((x) => guideCategoryLabel(x.id, x.category) == cat))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      blur: false,
                      onTap: () =>
                          context.go(
                        '${AppRoutes.hudaGuide}?id=${Uri.encodeQueryComponent(g.id)}',
                        extra: g,
                      ),
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

/// Route-level wrapper for /huda/guide. It resolves the guide from its id
/// (the `?id=` query parameter) via [guidesProvider], so the page survives
/// a browser reload or a deep link — navigation `extra` is only a fast
/// path and is lost on reload.
class GuideRouteScreen extends ConsumerWidget {
  const GuideRouteScreen({super.key, this.guideId, this.guide});

  final String? guideId;
  final Guide? guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Guide? given = guide;
    if (given != null) return GuideScreen(guide: given);
    final AsyncValue<List<Guide>> guides = ref.watch(guidesProvider);
    return guides.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (Object e, StackTrace _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('Could not load this guide.', style: AppText.bodyMuted),
        ),
      ),
      data: (List<Guide> all) {
        for (final Guide g in all) {
          if (g.id == guideId) return GuideScreen(guide: g);
        }
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Huda', close: true),
              Text('That guide could not be found.', style: AppText.bodyMuted),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.huda),
                child: const Text('Back to all guides'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GuideScreen extends StatelessWidget {
  final Guide guide;
  const GuideScreen({super.key, required this.guide});

  /// "Words in this guide": plain, literal glosses for the terms the guide
  /// uses (see guide_glossary.dart). Empty when the guide uses none.
  List<Widget> _glossaryBlock() {
    final List<GlossaryEntry> words = glossaryFor(<String>[
      guide.title,
      guide.subtitle,
      ...guide.steps,
      if (guide.madhhabNote != null) guide.madhhabNote!,
      ...?guide.goDeeper?.values,
    ].join('\n'));
    if (words.isEmpty) return const <Widget>[];
    return <Widget>[
      const SizedBox(height: 12),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('WORDS IN THIS GUIDE', style: AppText.eyebrow),
            const SizedBox(height: 6),
            for (final GlossaryEntry w in words)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${w.term} — ${w.gloss}',
                  style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.4),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          ScreenHeader(
            title: guideCategoryLabel(guide.id, guide.category),
            close: true,
          ),
          const SizedBox(height: 6),
          Text(
            guide.title,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(guide.subtitle, style: AppText.bodyMuted),
          ..._glossaryBlock(),
          if (guide.showPositions) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Expanded(child: _Pos(label: 'Qiyam', detail: 'standing')),
                  Expanded(child: _Pos(label: 'Ruku', detail: 'bowing')),
                  Expanded(child: _Pos(label: 'Sujud', detail: 'prostration')),
                  Expanded(child: _Pos(label: 'Julus', detail: 'sitting')),
                ],
              ),
            ),
          ],
          if (guide.goDeeper != null && guide.goDeeper!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('GO DEEPER', style: AppText.eyebrow),
                const SizedBox(height: 6),
                Text(
                  <String>[
                    if (guide.goDeeper!['why'] != null)
                      'WHY: ${guide.goDeeper!['why']}',
                    if (guide.goDeeper!['evidence'] != null)
                      'EVIDENCE: ${guide.goDeeper!['evidence']}',
                    if (guide.goDeeper!['commonMistakes'] != null)
                      'COMMON MISTAKES: ${guide.goDeeper!['commonMistakes']}',
                  ].join('\n'),
                  style: AppText.bodyMuted.copyWith(height: 1.6, fontSize: 12),
                ),
              ]),
            ),
          ],
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
                      fontSize: 12,
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

class _Pos extends StatelessWidget {
  final String label;
  final String detail;
  const _Pos({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 44, height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Text(label[0],
            style: const TextStyle(color: AppColors.goldLight, fontSize: 18)),
      ),
      const SizedBox(height: 3),
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.sand)),
      Text(detail,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.sand)),
    ]);
  }
}
