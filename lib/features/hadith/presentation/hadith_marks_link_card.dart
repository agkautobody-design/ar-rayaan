import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/whole_word_text.dart';
import '../application/hadith_marks_controller.dart';
import '../domain/hadith_marks.dart';

/// Hadith bookmarks and notes are kept by the Hadith screen (see
/// [HadithMarksController]), not in the general Notes list. This card sits on
/// the Notes screen and opens the Hadith screen showing only what was saved,
/// so a bookmark or note made there is never "missing" from where people look.
class HadithMarksLinkCard extends ConsumerWidget {
  const HadithMarksLinkCard({super.key});

  /// What the card says for [marks]. Pure, so it is easy to test.
  static String summary(HadithMarks marks) {
    final int saved = marks.list().length;
    if (saved == 0) {
      return 'Nothing yet. Bookmark or add a note on any of the Forty Hadith.';
    }
    final String hadith = saved == 1 ? '1 hadith' : '$saved hadith';
    final int notes = marks.noteCount;
    if (notes == 0) return hadith;
    return notes == 1 ? '$hadith, 1 note' : '$hadith, $notes notes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HadithMarks marks = ref.watch(hadithMarksProvider);
    void open() => context.push(AppRoutes.hadithSaved());
    return Semantics(
      button: true,
      label: 'Hadith bookmarks and notes. ${summary(marks)}',
      excludeSemantics: true,
      onTap: open,
      child: GlassCard(
        onTap: open,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.bookmarks_outlined,
              color: AppColors.gold,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  WholeWordText(
                    'Hadith bookmarks & notes',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(summary(marks), style: AppText.caption),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.gold.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
