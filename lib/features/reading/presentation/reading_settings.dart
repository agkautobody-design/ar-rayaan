/// The controls for Arabic reading support: three ways of reading and the two
/// switches "Show transliteration" and "Show meaning". Used in Settings and in
/// the quick sheet on the Qur'an reader, so both change the same thing.
library;

import 'dart:async' show unawaited;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/switch_row.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../application/reading_prefs.dart';

/// What each way of reading means, in plain words.
String readingSupportLabel(ReadingSupport m) {
  switch (m) {
    case ReadingSupport.beginner:
      return 'Show everything';
    case ReadingSupport.learning:
      return 'Fade as I learn';
    case ReadingSupport.reader:
      return 'I read Arabic';
  }
}

String readingSupportHelp(ReadingSupport m) {
  switch (m) {
    case ReadingSupport.beginner:
      return 'Arabic, the Arabic in Latin letters, and the meaning, always.';
    case ReadingSupport.learning:
      return 'Like Show everything, but the Latin letters step back behind a '
          'Read it button for what you already know.';
    case ReadingSupport.reader:
      return 'Arabic and the meaning. The Latin letters are one tap away.';
  }
}

class ReadingSupportControls extends ConsumerWidget {
  const ReadingSupportControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReadingPrefs prefs = ref.watch(readingPrefsProvider);
    final ReadingPrefsController ctl = ref.read(readingPrefsProvider.notifier);
    return Column(
      key: const Key('reading-support-controls'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            for (final ReadingSupport mode in ReadingSupport.values)
              ChoiceChip(
                key: Key('reading-mode-${mode.name}'),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                label: Text(readingSupportLabel(mode)),
                selected: prefs.mode == mode,
                selectedColor: AppColors.gold.withValues(alpha: 0.35),
                onSelected: (_) => unawaited(ctl.setMode(mode)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          readingSupportHelp(prefs.mode),
          style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 6),
        SwitchRow(
          icon: Icons.translate_outlined,
          title: 'Show transliteration',
          subtitle: 'Arabic written in Latin letters, so you can read it aloud.',
          value: prefs.showTranslit,
          onChanged: (bool v) => unawaited(ctl.setShowTranslit(v)),
        ),
        SwitchRow(
          icon: Icons.menu_book_outlined,
          title: 'Show meaning',
          subtitle: 'What the Arabic says, in English.',
          value: prefs.showMeaning,
          onChanged: (bool v) => unawaited(ctl.setShowMeaning(v)),
        ),
      ],
    );
  }
}

/// The quick sheet (Qur'an reader toolbar): the same controls.
Future<void> showReadingSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0A0F18),
    builder: (BuildContext ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Reading support', style: AppText.titleMedium),
            const SizedBox(height: 12),
            const ReadingSupportControls(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
