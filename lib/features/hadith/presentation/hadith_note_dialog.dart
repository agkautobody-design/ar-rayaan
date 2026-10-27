import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// The small dialog for writing a private note on a hadith. Pops the text
/// (possibly empty, which removes the note) or null when cancelled.
class HadithNoteDialog extends StatefulWidget {
  const HadithNoteDialog({super.key, required this.initial});

  final String initial;

  @override
  State<HadithNoteDialog> createState() => _HadithNoteDialogState();
}

class _HadithNoteDialogState extends State<HadithNoteDialog> {
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
      title: Text('Your note', style: AppText.titleMedium),
      content: TextField(
        key: const Key('hadith-note-field'),
        controller: _c,
        autofocus: true,
        minLines: 1,
        maxLines: 5,
        style: AppText.body,
        decoration: const InputDecoration(
          hintText: 'Write a reflection (kept on this device only)',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('hadith-note-save'),
          onPressed: () => Navigator.of(context).pop(_c.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
