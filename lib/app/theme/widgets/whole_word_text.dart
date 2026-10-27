import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';

/// A [Text] that never breaks a word in the middle.
///
/// A normal [Text] wraps at spaces, but when ONE word is wider than the box
/// (large text on a narrow phone: "Prayer", "Settings") Flutter cuts that
/// word wherever it runs out of room ("Praye / r"). This widget measures the
/// longest word first; if it does not fit, the font is made just small
/// enough for that word to fit on one line. Otherwise it is an ordinary
/// [Text]: it wraps at word boundaries and, with [maxLines], ends in an
/// ellipsis.
///
/// It needs a bounded width (a [Row] child must be wrapped in [Expanded] or
/// [Flexible], as for any wrapping text); with an unbounded width it is a
/// plain [Text].
class WholeWordText extends StatelessWidget {
  const WholeWordText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.minFactor = 0.4,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  /// The smallest share of the requested font size this will shrink to.
  final double minFactor;

  /// Splits where a line may break: spaces and dashes.
  static final RegExp _breaks = RegExp(r'[\s‐-―-]+');

  /// The factor (at most 1) by which [style] must shrink so that the longest
  /// word of [text] is no wider than [maxWidth]. 1 when it already fits.
  @visibleForTesting
  static double fitFactor({
    required String text,
    required TextStyle style,
    required TextScaler scaler,
    required TextDirection direction,
    required double maxWidth,
    double minFactor = 0.4,
  }) {
    if (!maxWidth.isFinite || maxWidth <= 0 || text.isEmpty) return 1;
    double widest = 0;
    for (final String word in text.split(_breaks)) {
      if (word.isEmpty) continue;
      final TextPainter p = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (p.width > widest) widest = p.width;
      p.dispose();
    }
    if (widest <= maxWidth || widest <= 0) return 1;
    // A hair of slack: the two measurements can differ by rounding.
    final double f = (maxWidth / widest) * 0.97;
    return f < minFactor ? minFactor : f;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle base = DefaultTextStyle.of(context).style.merge(style);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection dir = Directionality.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double f = fitFactor(
          text: data,
          style: base,
          scaler: scaler,
          direction: dir,
          maxWidth: box.maxWidth,
          minFactor: minFactor,
        );
        final TextStyle used = f >= 1
            ? base
            : base.copyWith(
                fontSize: (base.fontSize ?? 14) * f,
                letterSpacing:
                    base.letterSpacing == null ? null : base.letterSpacing! * f,
              );
        return Text(
          data,
          style: used,
          textAlign: textAlign,
          maxLines: maxLines,
          // No line limit means the whole text shows, wrapped. An ellipsis
          // here made the web (CanvasKit) renderer cut a wrapped subtitle to
          // its first line ("Private log for Qur'an reading, ..."), in
          // every switch row. The ellipsis only makes sense with a limit.
          overflow: maxLines == null ? TextOverflow.clip : overflow,
        );
      },
    );
  }
}
