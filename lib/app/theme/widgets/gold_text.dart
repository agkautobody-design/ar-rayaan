import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Text rendered with the locked champagne-gold gradient.
class GoldText extends StatelessWidget {
  const GoldText(this.text, {required this.style, super.key, this.textAlign});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) =>
          AppColors.goldTextGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
