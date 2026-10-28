/// Duʿa & Adhkar school — the teaching wrapper over the adhkar module.
/// The adhkar CONTENT is owned by features/adhkar (formats, doesn't
/// duplicate); this screen adds the pedagogy: what the words mean,
/// when the Prophet ﷺ taught them, and a memory nudge that routes to
/// the module itself.
library;

import '../../../app/core/scholar_review.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/core/content_loader.dart';
import '../../reading/presentation/arabic_block.dart';
import '../../share/application/share_service.dart';
import '../../share/presentation/share_actions.dart';

/// One lesson of the Dua school. The data is in `assets/academy/dua_lessons.json`
/// (moved there unchanged from this file), so the Arabic is in a registry.
class DuaLesson {
  const DuaLesson({
    required this.title,
    required this.arabic,
    required this.meaning,
    required this.when,
    required this.source,
    this.translit,
    this.translitSource,
  });

  final String title;
  final String arabic;
  final String meaning;
  final String when;
  final String source;

  /// Latin-letter reading of [arabic], only where it was checked against a
  /// named source ([translitSource]); null otherwise.
  final String? translit;
  final String? translitSource;

  static List<DuaLesson> parse(String raw) {
    try {
      final Object? top = json.decode(raw);
      if (top is! Map || top['lessons'] is! List) return const <DuaLesson>[];
      final List<DuaLesson> out = <DuaLesson>[];
      for (final Object? e in top['lessons'] as List<Object?>) {
        if (e is! Map) continue;
        final Object? t = e['title'];
        final Object? a = e['arabic'];
        final Object? m = e['meaning'];
        final Object? w = e['when'];
        final Object? s = e['source'];
        if (t is! String || a is! String || m is! String || w is! String || s is! String) {
          continue;
        }
        final Object? tl = e['translit'];
        final Object? ts = e['translitSource'];
        out.add(DuaLesson(
          title: t,
          arabic: a,
          meaning: m,
          when: w,
          source: s,
          translit: tl is String && tl.trim().isNotEmpty ? tl : null,
          translitSource: ts is String && ts.trim().isNotEmpty ? ts : null,
        ));
      }
      return out;
    } catch (_) {
      return const <DuaLesson>[];
    }
  }
}

const String kDuaLessonsAsset = 'assets/academy/dua_lessons.json';

final FutureProvider<List<DuaLesson>> duaLessonsProvider =
    FutureProvider<List<DuaLesson>>((Ref ref) async {
      return DuaLesson.parse(await ContentLoader.loadString(kDuaLessonsAsset));
    });

class DuaSchoolScreen extends ConsumerWidget {
  const DuaSchoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DuaLesson> lessons =
        ref.watch(duaLessonsProvider).valueOrNull ?? const <DuaLesson>[];
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'Duʿa & Adhkar'),
              const ScholarReviewNote(
                reviewKey: 'school.dua',
                padding: EdgeInsets.only(bottom: 8),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'A dua you understand is worth more than a hundred recited blindly. Learn the meaning here; practice inside the Dhikr & Duʿa module, anchored to your prayer times. [Content pending scholar review.]',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ),
              for (final DuaLesson l in lessons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(l.title,
                            style: AppText.titleMedium
                                .copyWith(color: AppColors.gold)),
                        const SizedBox(height: 8),
                        // Arabic, then transliteration, then the labelled meaning.
                        ArabicBlock(
                          key: Key('dua-lesson-block-${l.title}'),
                          arabic: l.arabic,
                          translit: l.translit,
                          translitSource: l.translitSource,
                          needsReview: true,
                          meaning: l.meaning,
                          arabicSize: 22,
                        ),
                        const SizedBox(height: 8),
                        Text('When: ${l.when}',
                            style: AppText.caption),
                        Text('Source: ${l.source}',
                            style: AppText.caption
                                .copyWith(color: AppColors.gold)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ShareButton(
                            doc: ShareDoc.dua(
                              title: l.title,
                              arabic: l.arabic,
                              translit: l.translit,
                              translitSource: l.translitSource,
                              meaning: l.meaning,
                              when: l.when,
                              source: l.source,
                              reviewKey: 'school.dua',
                            ),
                            subject: 'this dua',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              GlassCard(
                onTap: () => context.go('/adhkar'),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.wb_sunny_outlined, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Open Dhikr & Duʿa to practice',
                          style: AppText.body),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.gold),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
