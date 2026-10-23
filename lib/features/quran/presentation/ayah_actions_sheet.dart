import 'package:flutter/material.dart';
import '../../share/presentation/share_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../application/quran_marks_controller.dart';
import '../domain/quran_marks.dart';
import '../domain/quran_models.dart';

/// The text copied for one ayah: Arabic, the translation, the reference and
/// where both texts come from. Nothing is reworded.
String ayahShareText(String surahName, int surah, Ayah ayah) {
  return '${ayah.arabic}\n\n${ayah.english}\n\n'
      '— $surahName $surah:${ayah.number}\n'
      'Arabic: Tanzil Uthmani (tanzil.net). Translation: Saheeh International, '
      'via Tanzil. Shared from Ar-Rayaan.';
}

/// More actions for one ayah: note, collections, copy.
Future<void> showAyahActions(
  BuildContext context, {
  required String surahName,
  required int surah,
  required Ayah ayah,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.navy,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) =>
        AyahActionsSheet(surahName: surahName, surah: surah, ayah: ayah),
  );
}

class AyahActionsSheet extends ConsumerWidget {
  const AyahActionsSheet({
    required this.surahName,
    required this.surah,
    required this.ayah,
    super.key,
  });

  final String surahName;
  final int surah;
  final Ayah ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuranMarks marks = ref.watch(quranMarksProvider);
    final AyahMark? mark = marks.of(surah, ayah.number);
    final QuranMarksController ctl = ref.read(quranMarksProvider.notifier);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: <Widget>[
            Text('$surahName $surah:${ayah.number}', style: AppText.titleMedium),
            const SizedBox(height: 8),
            _Action(
              icon: (mark?.bookmarked ?? false)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              label: (mark?.bookmarked ?? false)
                  ? 'Remove bookmark'
                  : 'Bookmark this ayah',
              onTap: () => ctl.toggleBookmark(surah, ayah.number),
            ),
            _Action(
              icon: Icons.edit_note,
              label: (mark?.note.isNotEmpty ?? false)
                  ? 'Edit your note'
                  : 'Add a private note',
              onTap: () async {
                final String? text = await showDialog<String>(
                  context: context,
                  builder: (BuildContext ctx) =>
                      _NoteDialog(initial: mark?.note ?? ''),
                );
                if (text != null) await ctl.setNote(surah, ayah.number, text);
              },
            ),
            if ((mark?.note.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 0, 8),
                child: Text(mark!.note, style: AppText.bodyMuted),
              ),
            _Action(
              icon: Icons.copy,
              label: 'Copy Arabic and translation',
              onTap: () async {
                await copyWithFeedback(
                  context,
                  ayahShareText(surahName, surah, ayah),
                  message: 'Copied',
                );
              },
            ),
            const SizedBox(height: 8),
            Text('COLLECTIONS', style: AppText.eyebrow),
            if (marks.collections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Make a collection to group ayahs, for example "For '
                  'reflection" or "To memorise".',
                  style: AppText.bodyMuted,
                ),
              ),
            for (final QuranCollection c in marks.collections)
              CheckboxListTile(
                value: mark?.collections.contains(c.id) ?? false,
                activeColor: AppColors.gold,
                contentPadding: EdgeInsets.zero,
                title: Text(c.name, style: AppText.body),
                onChanged: (_) => ctl.toggleInCollection(surah, ayah.number, c.id),
              ),
            _Action(
              icon: Icons.add,
              label: 'New collection',
              onTap: () async {
                final String? name = await showDialog<String>(
                  context: context,
                  builder: (BuildContext ctx) => const _NoteDialog(
                    initial: '',
                    title: 'New collection',
                    hint: 'Name',
                    maxLines: 1,
                  ),
                );
                if (name == null || name.trim().isEmpty) return;
                final String id = await ctl.createCollection(name);
                if (id.isNotEmpty) {
                  await ctl.toggleInCollection(surah, ayah.number, id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppText.body)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.initial,
    this.title = 'Your note',
    this.hint = 'Write a reflection (kept on this device only)',
    this.maxLines = 5,
  });

  final String initial;
  final String title;
  final String hint;
  final int maxLines;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(widget.title, style: AppText.titleMedium),
      content: TextField(
        controller: _c,
        autofocus: true,
        minLines: 1,
        maxLines: widget.maxLines,
        style: AppText.body,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_c.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
