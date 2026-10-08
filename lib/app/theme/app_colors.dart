import 'package:flutter/material.dart';

/// Locked design-system palette (Design System panel, "LOCKED" board).
abstract final class AppColors {
  // Core tokens
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C96A);
  static const Color goldDark = Color(0xFF9C7C1E);
  static const Color sand = Color(0xFFEAD6B4);
  static const Color deepBlue = Color(0xFF0B1B2A);
  static const Color navy = Color(0xFF101C2E);
  static const Color night = Color(0xFF05090F);

  // Glass token (panel: #FFFFFF1A)
  static const Color glassFill = Color(0x1AFFFFFF);

  // Semantic
  static const Color destructive = Color(0xFFC4524F);
  static const Color textPrimary = sand;
  static const Color textMuted = Color(0x99EAD6B4);
  static const Color textFaint = Color(0x66EAD6B4);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEED488), gold, Color(0xFFB08A24)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldTextGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3DD9A), gold, Color(0xFFA9821F)],
    stops: [0.0, 0.45, 1.0],
  );
}
