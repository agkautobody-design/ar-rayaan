/// Madinah page renderer — fixed 15-line layout, tap-ayah, playback
/// highlight. The LINE-LOCKED promise lives here: a page renders as
/// exactly its 15 lines, never reflowed; resize the window and the
/// lines scale, they never re-wrap (visual memorizers' recall contract).
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/mushaf_layout.dart';

/// Renders one [MushafPage]. The mushaf page is intentionally
/// parchment-light (authentic Madinah reading surface, and the tajweed
/// color spec is authored for light pages) — it sits inside the app's
/// dark scenic frame as "main content", matching the healing/hadith
/// screen rhythm.
class MushafPageView extends StatelessWidget {
  const MushafPageView({
    super.key,
    required this.page,
    this.onAyahTapped,
    this.highlight,
    this.tajweedColorFor,
    this.baseFontSize = 22,
  });

  final MushafPage page;

  /// Called with the ayah whose segment was tapped (playback range set).
  final void Function(int surah, int ayah)? onAyahTapped;

  /// Currently-playing ayah — its segments get a soft gold tint.
  final AyahLocation? highlight;

  /// Tajweed color layer (per-segment). Null = plain text for now;
  /// the tajweed pack wires in here without touching this widget.
  final Color? Function(LayoutSegment segment)? tajweedColorFor;

  final double baseFontSize;

  static const Color parchment = Color(0xFFFDF6E3);
  static const Color ink = Color(0xFF1A2B1A);
  static const Color activeTint = Color(0x33D4AF37);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72, // Madinah page proportion (portrait)
      child: Container(
        decoration: BoxDecoration(
          color: parchment,
          border: Border.all(color: AppColors.gold, width: 1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x66000000), blurRadius: 18),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < page.lines.length; i++)
              Expanded(
                child: _LineView(
                  line: page.lines[i],
                  lineIndex: i,
                  fontSize: baseFontSize,
                  highlight: highlight != null &&
                          highlight!.page == page.pageNumber
                      ? highlight!.lineIndex
                      : null,
                  tajweedColorFor: tajweedColorFor,
                  onAyahTapped: onAyahTapped,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LineView extends StatelessWidget {
  const _LineView({
    required this.line,
    required this.lineIndex,
    required this.fontSize,
    required this.highlight,
    required this.tajweedColorFor,
    required this.onAyahTapped,
  });

  final MushafLine line;
  final int lineIndex;
  final double fontSize;
  final int? highlight;
  final Color? Function(LayoutSegment segment)? tajweedColorFor;
  final void Function(int surah, int ayah)? onAyahTapped;

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = highlight == lineIndex;

    final List<Widget> spans = <Widget>[
      for (final LayoutSegment s in line.segments)
        GestureDetector(
          onTap: (s.surah != null && s.ayah != null && onAyahTapped != null)
              ? () => onAyahTapped!(s.surah!, s.ayah!)
              : null,
          child: Text.rich(
            TextSpan(
              text: s.text,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: fontSize,
                height: 1.35,
                color: s.marker
                    ? AppColors.gold
                    : (tajweedColorFor?.call(s) ?? MushafPageView.ink),
                backgroundColor:
                    isHighlighted && !s.marker ? MushafPageView.activeTint : null,
              ),
            ),
          ),
        ),
    ];

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: isHighlighted
          ? BoxDecoration(
              color: MushafPageView.activeTint.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: spans,
        ),
      ),
    );
  }
}
