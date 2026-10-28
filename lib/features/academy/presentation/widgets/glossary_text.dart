import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../../app/theme/widgets/tr_text.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/glass_card.dart';
import '../../domain/glossary.dart';
import '../../../../app/theme/widgets/named_sheet.dart';

/// Lesson text in which the glossary words (taqwa, nisab, riba, qada, tawaf
/// ...) are underlined and tap open a short plain meaning. Under the text a
/// row of buttons lists the same words, so each one is also a full-size
/// target and is read out by a screen reader.
///
/// The meanings are the plain, widely agreed ones in `domain/glossary.dart`;
/// the sheet says they are not rulings.
class GlossaryText extends StatefulWidget {
  const GlossaryText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends State<GlossaryText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];
  List<InlineSpan> _spans = const <InlineSpan>[];

  @override
  void initState() {
    super.initState();
    _rebuildSpans();
  }

  @override
  void didUpdateWidget(GlossaryText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _rebuildSpans();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _rebuildSpans() {
    _disposeRecognizers();
    final String t = widget.text;
    final List<InlineSpan> spans = <InlineSpan>[];
    int at = 0;
    for (final GlossaryMatch m in findGlossaryTerms(t)) {
      if (m.start > at) spans.add(TextSpan(text: t.substring(at, m.start)));
      final TapGestureRecognizer r = TapGestureRecognizer()
        ..onTap = () => showGlossarySheet(context, m.entry);
      _recognizers.add(r);
      spans.add(
        TextSpan(
          text: t.substring(m.start, m.end),
          recognizer: r,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: AppColors.gold,
          ),
        ),
      );
      at = m.end;
    }
    if (at < t.length) spans.add(TextSpan(text: t.substring(at)));
    _spans = spans;
  }

  @override
  Widget build(BuildContext context) {
    final List<GlossaryEntry> entries = glossaryEntriesIn(widget.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(TextSpan(style: widget.style, children: _spans)),
        if (entries.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Text('WORDS IN THIS STEP', style: AppText.eyebrow),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: <Widget>[
              for (final GlossaryEntry e in entries)
                ActionChip(
                  key: Key('glossary-${e.term}'),
                  label: Text(e.term, style: const TextStyle(fontSize: 14)),
                  onPressed: () => showGlossarySheet(context, e),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The meaning of one glossary word, in a bottom sheet.
Future<void> showGlossarySheet(BuildContext context, GlossaryEntry e) {
  return showNamedSheet<void>(
    label: 'Word meaning',
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        strong: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(e.term, style: AppText.titleMedium),
            const SizedBox(height: 8),
            Text(
              e.definition,
              key: const Key('glossary-definition'),
              style: AppText.body.copyWith(height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              'A plain meaning of the word, not a ruling. For a ruling, ask '
              'a scholar.',
              style: AppText.caption,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
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
