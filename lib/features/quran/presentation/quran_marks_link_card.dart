import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/whole_word_text.dart';
import '../application/quran_marks_controller.dart';
import '../domain/quran_marks.dart';

/// Ayah bookmarks and notes are kept by the Qur'an reader (see
/// [QuranMarksController]), not in the general Notes list or the saved
/// stories. This card sits on those You-tab screens and opens the Qur'an
/// bookmarks page, so a bookmark or note made in the reader is never
/// "missing" from where people look for it.
class QuranMarksLinkCard extends ConsumerWidget {
  const QuranMarksLinkCard({super.key});

  /// What the card says for [marks]. Pure, so it is easy to test.
  static String summary(QuranMarks marks) {
    final List<AyahMark> all = marks.list();
    if (all.isEmpty) {
      return 'Nothing yet. Bookmark or add a note on any ayah in the Qur\u2019an.';
    }
    final int notes = all
        .where((AyahMark m) => m.note.trim().isNotEmpty)
        .length;
    final String ayahs = all.length == 1 ? '1 ayah' : '${all.length} ayahs';
    if (notes == 0) return ayahs;
    return notes == 1 ? '$ayahs, 1 note' : '$ayahs, $notes notes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuranMarks marks = ref.watch(quranMarksProvider);
    return Semantics(
      button: true,
      label: 'Qur\u2019an bookmarks and notes. ${summary(marks)}',
      excludeSemantics: true,
      onTap: () => context.push(AppRoutes.quranBookmarks),
      child: GlassCard(
        onTap: () => context.push(AppRoutes.quranBookmarks),
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
                    'Qur\u2019an bookmarks & notes',
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
