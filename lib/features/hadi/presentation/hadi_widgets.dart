import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import 'hadi_markdown.dart';

/// A reply laid out from its basic Markdown, selectable (long-press to copy)
/// and right to left when it is written in Arabic or Urdu.
class HadiRichText extends StatelessWidget {
  const HadiRichText({required this.text, required this.style, super.key});

  final String text;
  final TextStyle style;

  /// The reply as styled runs: bold and italic from the markup, list markers
  /// as text, a line break (or two) between blocks.
  static List<InlineSpan> spansFor(String text, TextStyle style) {
    final List<InlineSpan> out = <InlineSpan>[];
    final List<MdBlock> blocks = HadiMarkdown.parse(text);
    for (int i = 0; i < blocks.length; i++) {
      final MdBlock b = blocks[i];
      if (i > 0) out.add(TextSpan(text: b.blankBefore ? '\n\n' : '\n'));
      if (b.marker.isNotEmpty) out.add(TextSpan(text: '${b.marker}  '));
      for (final MdSpan s in b.spans) {
        out.add(
          TextSpan(
            text: s.text,
            style: s.bold || s.italic
                ? style.copyWith(
                    fontWeight: s.bold ? FontWeight.w700 : null,
                    fontStyle: s.italic ? FontStyle.italic : null,
                  )
                : null,
          ),
        );
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final bool rtl = HadiMarkdown.isMostlyRtl(text);
    // A selectable text field reaches a screen reader as an empty edit box on
    // the web. The reply's words are given as the label of a plain text node
    // instead, and the field itself stays out of the reading order.
    return Semantics(
      container: true,
      label: HadiMarkdown.plain(text),
      textDirection: rtl ? TextDirection.rtl : null,
      child: ExcludeSemantics(
        child: SelectableText.rich(
          TextSpan(style: style, children: spansFor(text, style)),
          textDirection: rtl ? TextDirection.rtl : null,
        ),
      ),
    );
  }
}

/// Three dots that pulse while Hādi is answering. Holds still when the
/// device asks for less motion, and tells a screen reader that Hādi is
/// answering.
class HadiTypingIndicator extends StatefulWidget {
  const HadiTypingIndicator({super.key});

  @override
  State<HadiTypingIndicator> createState() => _HadiTypingIndicatorState();
}

class _HadiTypingIndicatorState extends State<HadiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _opacity(double t, int i) {
    final double phase = (t - i / 3) % 1.0;
    return 0.3 + 0.7 * (0.5 + 0.5 * math.sin(2 * math.pi * phase));
  }

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.of(context).disableAnimations;
    return Semantics(
      liveRegion: true,
      label: 'Hādi is answering',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  child: Opacity(
                    opacity: still ? 0.7 : _opacity(_c.value, i),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A heading that opens and closes the text under it. At least 48 dp tall,
/// and it grows with the text size.
class HadiDisclosure extends StatefulWidget {
  const HadiDisclosure({
    required this.title,
    required this.child,
    this.titleStyle,
    super.key,
  });

  final String title;
  final Widget child;
  final TextStyle? titleStyle;

  @override
  State<HadiDisclosure> createState() => _HadiDisclosureState();
}

class _HadiDisclosureState extends State<HadiDisclosure> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        widget.title,
                        style: widget.titleStyle ??
                            AppText.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldLight,
                            ),
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.sand.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(width: double.infinity, child: widget.child),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The note Hādi leaves under a live reply when it removed or could not
/// check something. Closed until the person opens it, so the reply reads
/// cleanly and nothing looks broken.
class HadiNotesPanel extends StatelessWidget {
  const HadiNotesPanel({required this.notes, super.key});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return HadiDisclosure(
      title: notes.length == 1
          ? 'Hādi checked this reply · 1 note'
          : 'Hādi checked this reply · ${notes.length} notes',
      titleStyle: AppText.caption.copyWith(
        color: AppColors.sand.withValues(alpha: 0.8),
        fontSize: 13,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final String n in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                n,
                style: AppText.caption.copyWith(
                  color: AppColors.sand.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/// A suggestion or action button for the chat. Unlike a Material chip it
/// never clips its label: a long label wraps onto more lines (at word
/// breaks), grows taller, and stays at least 48 dp high to tap.
class HadiActionButton extends StatelessWidget {
  const HadiActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconSize = 16,
    this.strong = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;

  /// True for the buttons that open a screen (gold), false for a suggested
  /// question.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final Color border =
        AppColors.gold.withValues(alpha: strong ? 0.4 : 0.3);
    return Semantics(
      button: true,
      child: Material(
        color: strong
            ? AppColors.gold.withValues(alpha: 0.08)
            : AppColors.gold.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: iconSize, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      softWrap: true,
                      style: strong
                          ? AppText.body.copyWith(
                              fontSize: 14,
                              color: AppColors.goldLight,
                            )
                          : AppText.bodyMuted.copyWith(
                              fontSize: 13,
                              color: AppColors.sand.withValues(alpha: 0.85),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
