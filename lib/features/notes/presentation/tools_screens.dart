import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../hadith/presentation/hadith_marks_link_card.dart';
import '../../quran/presentation/quran_marks_link_card.dart';
import '../../sakina/domain/crisis_detector.dart';
import '../../sakina/presentation/widgets/need_help_button.dart';
import '../application/notes_controller.dart';
import '../domain/notes.dart';

/// On-device notes — private by design, nothing ever leaves the device.
///
/// A note needs a title OR a body: a note with only a body is kept (its title
/// is made from the first line). Tap a note to edit it; delete asks no
/// question but offers Undo.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  /// Opens the editor for a new note ([existing] null) or for [existing].
  Future<void> _edit({NoteItem? existing}) async {
    final ({String title, String body})? result =
        await showDialog<({String title, String body})>(
      context: context,
      builder: (BuildContext ctx) => _NoteEditor(existing: existing),
    );
    if (result == null || !mounted) return;
    final NotesController ctl = ref.read(notesProvider.notifier);
    final NoteItem? saved = existing == null
        ? await ctl.add(title: result.title, body: result.body)
        : await ctl.edit(
            existing.at,
            title: result.title,
            body: result.body,
          );
    if (!mounted) return;
    if (saved == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Write a title or a few words, then save.'),
        ),
      );
      return;
    }
    // A note is private and is never blocked. But if the words in it say
    // someone may be in danger, the help lines are offered right away.
    final CrisisKind? kind = CrisisDetector.detect(
      '${saved.title} ${saved.body}',
    );
    if (kind != null && mounted) {
      await showNeedHelpSheet(
        context,
        kind: kind,
        intro:
            'Your note is saved, and only you can see it. It sounds '
            'like things may be very hard. If you are in danger, call '
            'your local emergency number. These lines are free to talk '
            'to.',
      );
    }
  }

  Future<void> _delete(NoteItem n) async {
    final NotesController ctl = ref.read(notesProvider.notifier);
    final int index =
        ref.read(notesProvider).indexWhere((NoteItem x) => x.at == n.at);
    await ctl.remove(n.at);
    if (!mounted) return;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => ctl.restore(n, index < 0 ? 0 : index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<NoteItem> notes = ref.watch(notesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add a note',
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF0A0F18),
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        children: [
          const ScreenHeader(title: 'Notes', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text('ON THIS DEVICE ONLY', style: AppText.eyebrow),
                ),
                const NeedHelpNowButton(),
              ],
            ),
          ),
          // Ayah and hadith notes live with the Qur'an reader and the Hadith
          // screen; link to them from here.
          const QuranMarksLinkCard(),
          const SizedBox(height: 10),
          const HadithMarksLinkCard(),
          const SizedBox(height: 10),
          if (notes.isEmpty)
            GlassCard(
              child: Text(
                'No notes yet. Tap + to write your first — an ayah that moved you, a dua to remember, a lesson from a story.',
                style: AppText.bodyMuted,
              ),
            )
          else
            for (final NoteItem n in notes)
              Padding(
                key: ValueKey<String>(n.at),
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  onTap: () => _edit(existing: n),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n.title, style: AppText.titleMedium),
                          ),
                          IconButton(
                            key: ValueKey<String>('note-delete-${n.at}'),
                            tooltip: 'Delete note "${n.title}"',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            onPressed: () => _delete(n),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.sand,
                            ),
                          ),
                        ],
                      ),
                      if (n.body.isNotEmpty && n.body != n.title) ...[
                        const SizedBox(height: 4),
                        Text(
                          n.body,
                          style: AppText.bodyMuted.copyWith(height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// The note editor: a title box and a body box. Pops the typed text; the
/// caller decides what is saved (see `buildNote`).
class _NoteEditor extends StatefulWidget {
  const _NoteEditor({this.existing});

  final NoteItem? existing;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _body =
      TextEditingController(text: widget.existing?.body ?? '');

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0F18),
      title: Text(
        widget.existing == null ? 'New note' : 'Edit note',
        style: AppText.titleMedium,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(label: 'Title (optional)', child: TextField(
              key: const Key('note-title-field'),
              controller: _title,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Title (optional)'),
            )),
            const SizedBox(height: 8),
            Semantics(label: 'Your note…', child: TextField(
              key: const Key('note-body-field'),
              controller: _body,
              style: AppText.body,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(hintText: 'Your note…'),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('note-save'),
          onPressed: () => Navigator.pop(
            context,
            (title: _title.text, body: _body.text),
          ),
          child: const Text(
            'Save',
            style: TextStyle(color: AppColors.goldLight),
          ),
        ),
      ],
    );
  }
}
