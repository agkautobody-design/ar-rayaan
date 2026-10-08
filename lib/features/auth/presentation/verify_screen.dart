import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_scaffold.dart';

/// Email-verification screen shown right after sign-up.
class VerifyScreen extends ConsumerWidget {
  const VerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return AuthScaffold(
      title: 'Verify Your Email',
      subtitle: user?.email != null
          ? 'We sent a verification link to\n${user!.email}'
          : 'We sent a verification link to your email',
      children: [
        const SizedBox(height: 8),
        Icon(
          Icons.verified_outlined,
          size: 56,
          color: AppColors.gold.withValues(alpha: 0.9),
        ),
        const SizedBox(height: 24),
        Text(
          'Tap the link in the email to verify your account. '
          'You can continue exploring while verification is pending.',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        GoldButton(
          key: const Key('verify-continue'),
          label: 'Continue to Ar-Rayaan',
          onPressed: () => context.go(AppRoutes.home),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // TODO(O-4): resend verification email via Firebase.
          },
          child: Text(
            'Resend verification email',
            style: AppText.caption.copyWith(color: AppColors.goldLight),
          ),
        ),
      ],
    );
  }
}
