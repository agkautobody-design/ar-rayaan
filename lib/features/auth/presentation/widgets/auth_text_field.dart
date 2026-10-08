import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// Gold-glass text field used across auth screens.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    super.key,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: AppText.body,
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.bodyMuted,
        prefixIcon: Icon(
          icon,
          size: 18,
          color: AppColors.gold.withValues(alpha: 0.7),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.night.withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.55)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        errorStyle: const TextStyle(color: AppColors.destructive, fontSize: 11),
      ),
    );
  }
}

/// Email/password validators shared by the auth forms.
abstract final class AuthValidators {
  static String? email(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final String v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  static String? name(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Name is required';
    return null;
  }
}
