import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/quran_marks_controller.dart';
import '../application/quran_providers.dart';
import '../domain/quran_marks.dart';
import '../domain/quran_models.dart';
import '../domain/quran_texts.dart';
import 'ayah_actions_sheet.dart';

/// Everything the person saved in the Qur'an: bookmarks, notes and
/// collections. Stored on this device only.
class QuranBookmarksScreen extends ConsumerStatefulWidget {
  const QuranBookmarksScreen({super.key});

  @override
  ConsumerState<QuranBookmarksScreen> createState() =>
      _QuranBookmarksScreenState();
}

class _QuranBookmarksScreenState extends ConsumerState<QuranBookmarksScreen> {
  /// null = all saved ayahs.
  String? _collectionId;

  Ayah? _ayahAt(List<Surah> all, int surah, int ayah) {
    if (surah < 1 || surah > all.length) return null;
    final List<Ayah> list = all[surah - 1].ayahs;
    if (ayah < 1 || ayah > list.length) return null;
    return list[ayah - 1];
  }

  Future<void> _open(AyahMark m) async {
    await ref
        .read(readingPositionProvider.notifier)
        .save(ReadingPosition(surah: m.surah, ayah: m.ayah));
    if (mounted) context.push(AppRoutes.surah(m.surah));
  }

  Future<void> _export(QuranMarks marks, List<Surah> all) async {
    final String text = exportMarks(
      marks,
      collectionId: _collectionId,
      credit: (ref.read(quranTextsProvider).value ?? QuranTexts.fallback)
          .shareCreditLine,
      lookup: (int s, int a) {
        final Ayah? ay = _ayahAt(all, s, a);
        if (ay == null) return null;
        return (
          arabic: ay.arabic,
          english: ay.english,
          surahName: all[s - 1].meta.transliteration,
        );
      },
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Copied as text')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final QuranMarks marks = ref.watch(quranMarksProvider);
    final AsyncValue<List<Surah>> all = ref.watch(quranAllProvider);
    if (_collectionId != null && marks.collection(_collectionId!) == null) {
      _collectionId = null;
    }
    final List<AyahMark> items = marks.list(collectionId: _collectionId);

    return ScenicScaffold.pattern(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const ScreenHeader(title: 'Bookmarks & notes'),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  _Chip(
                    label: 'All',
                    selected: _collectionId == null,
                    onTap: () => setState(() => _collectionId = null),
                  ),
                  for (final QuranCollection c in marks.collections)
                    _Chip(
                      label: c.name,
                      selected: _collectionId == c.id,
                      onTap: () => setState(() => _collectionId = c.id),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_collectionId != null)
                    TextButton.icon(
                      onPressed: () async {
                        final String id = _collectionId!;
                        setState(() => _collectionId = null);
                        await ref
                            .read(quranMarksProvider.notifier)
                            .deleteCollection(id);
                      },
                      icon: const Icon(Icons.folder_delete_outlined,
                          color: AppColors.gold),
                      label: const Text('Delete collection'),
                    ),
                  TextButton.icon(
                    onPressed: items.isEmpty || all.valueOrNull == null
                        ? null
                        : () => _export(marks, all.valueOrNull!),
                    icon: const Icon(Icons.copy, color: AppColors.gold),
                    label: const Text('Copy as text'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Nothing saved yet. Open a surah and tap the '
                          'bookmark under an ayah, or the ⋯ button for a '
                          'note or a collection.',
                          style: AppText.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int i) {
                        final AyahMark m = items[i];
                        final List<Surah>? surahs = all.valueOrNull;
                        final Ayah? ayah =
                            surahs == null ? null : _ayahAt(surahs, m.surah, m.ayah);
                        final String name = surahs == null
                            ? 'Surah ${m.surah}'
                            : surahs[m.surah - 1].meta.transliteration;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Semantics(
                            button: true,
                            label: 'Open $name ayah ${m.ayah}',
                            child: GlassCard(
                              onTap: () => _open(m),
                              blur: false,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '$name ${m.surah}:${m.ayah}',
                                          style: AppText.body.copyWith(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Edit note or collections',
                                        constraints: const BoxConstraints(
                                          minWidth: 48,
                                          minHeight: 48,
                                        ),
                                        onPressed: ayah == null
                                            ? null
                                            : () => showAyahActions(
                                                  context,
                                                  surahName: name,
                                                  surah: m.surah,
                                                  ayah: ayah,
                                                ),
                                        icon: const Icon(Icons.more_horiz,
                                            color: AppColors.gold),
                                      ),
                                    ],
                                  ),
                                  if (ayah != null) ...<Widget>[
                                    Text(
                                      ayah.arabic,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right,
                                      style: AppText.arabicLarge
                                          .copyWith(fontSize: 20, height: 1.8),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ayah.english,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.bodyMuted,
                                    ),
                                  ],
                                  if (m.note.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 6),
                                    Text('Your note: ${m.note}',
                                        style: AppText.caption
                                            .copyWith(color: AppColors.gold)),
                                  ],
                                  if (m.collections.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 6),
                                    Text(
                                      m.collections
                                          .map((String id) =>
                                              marks.collection(id)?.name ?? '')
                                          .where((String n) => n.isNotEmpty)
                                          .join(' · '),
                                      style: AppText.caption,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.gold.withValues(alpha: 0.25),
      ),
    );
  }
}
