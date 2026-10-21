import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Locked glass card style (Design System panel):
/// Blur 24px · Border 1px gold (subtle glow) · Radius 20px ·
/// Shadow soft & elegant · Background blur + transparency.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.strong = false,
    this.onTap,
    this.borderRadius = 20,
    this.blur = true,
    this.semanticsLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Strong variant: navy fill + wider gold glow (e.g. "Today for You").
  final bool strong;
  final VoidCallback? onTap;
  final double borderRadius;

  /// Background blur. Each blurred card costs a compositing layer, so long
  /// lists (stories index, ayah rows) should pass `blur: false` and keep the
  /// translucent fill + border, which looks the same on this dark background.
  final bool blur;

  /// What a screen reader says for a tappable card. When null the card reads
  /// out the text inside it; give a label when that text alone would be
  /// unclear (an icon-only card, or a row that needs its state spoken).
  final String? semanticsLabel;

  /// A tappable card is never shorter than this, so it is easy to hit.
  static const double minTapHeight = 48;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    final Widget inner = Material(
      color: Colors.transparent,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    final Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: strong
              ? AppColors.gold.withValues(alpha: 0.35)
              : AppColors.gold.withValues(alpha: 0.25),
        ),
        color: strong
            ? AppColors.navy.withValues(alpha: 0.8)
            : AppColors.glassFill,
        boxShadow: strong
            ? const [
                BoxShadow(color: Color(0x1FD4AF37), blurRadius: 24),
                BoxShadow(
                  color: Color(0x8C000000),
                  blurRadius: 50,
                  offset: Offset(0, 14),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x73000000),
                  blurRadius: 40,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: blur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: inner,
              )
            : inner,
      ),
    );

    if (onTap == null) return card;

    final Widget tappable = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minTapHeight),
          child: card,
        ),
      ),
    );
    final String? label = semanticsLabel;
    if (label == null) return Semantics(button: true, child: tappable);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: tappable,
    );
  }
}
