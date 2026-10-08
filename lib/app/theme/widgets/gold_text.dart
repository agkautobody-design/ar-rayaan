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
    // Solid gold instead of ShaderMask: ShaderMask is unreliable on Flutter
    // web and left text invisible on several screens.
    return Text(
      text,
      style: style.copyWith(color: AppColors.goldLight),
      textAlign: textAlign,
    );
  }
}
