import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';

/// Gold pill CTA (locked style): champagne gradient, soft gold shadow,
/// night-colored label, press scale feedback.
class GoldButton extends StatefulWidget {
  const GoldButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.trailing,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final bool expand;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;

    final Widget content = Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.goldGradient : null,
        color: enabled ? null : AppColors.textFaint,
        borderRadius: BorderRadius.circular(999),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x59D4AF37),
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.night,
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            IconTheme(
              data: const IconThemeData(color: AppColors.night, size: 18),
              child: widget.trailing!,
            ),
          ],
        ],
      ),
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 150),
        child: widget.expand
            ? content
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: content,
              ),
      ),
    );
  }
}
