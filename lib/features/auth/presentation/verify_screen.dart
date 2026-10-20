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
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  bool _sending = false;
  String? _status;
  bool _statusIsError = false;

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _status = null;
    });
    final String? problem =
        await ref.read(authControllerProvider.notifier).resendVerification();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _statusIsError = problem != null;
      _status = problem ?? 'Sent again. Check your inbox and spam folder.';
    });
  }

  @override
  Widget build(BuildContext context) {
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
          key: const Key('verify-resend'),
          onPressed: _sending ? null : _resend,
          child: Text(
            _sending ? 'Sending\u2026' : 'Resend verification email',
            style: AppText.caption.copyWith(color: AppColors.goldLight),
          ),
        ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _status!,
              key: const Key('verify-status'),
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                color: _statusIsError
                    ? const Color(0xFFF3A9A9)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }
}
