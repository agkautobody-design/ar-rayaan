import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

/// Password-reset screen — enter email, receive reset link.
class ResetScreen extends ConsumerStatefulWidget {
  const ResetScreen({super.key});

  @override
  ConsumerState<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends ConsumerState<ResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_email.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;

    if (_sent) {
      return AuthScaffold(
        title: 'Check Your Inbox',
        subtitle: 'We sent a reset link to\n${_email.text.trim()}',
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.mark_email_read_outlined,
            size: 56,
            color: AppColors.gold.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 24),
          Text(
            'Follow the link in the email to set a new password. '
            'The link expires in 1 hour.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          GoldButton(
            key: const Key('reset-back-login'),
            label: 'Back to Sign In',
            onPressed: () => context.go(AppRoutes.login),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: loading ? null : _submit,
            child: Text(
              'Resend email',
              style: AppText.caption.copyWith(color: AppColors.goldLight),
            ),
          ),
        ],
      );
    }

    return AuthScaffold(
      title: 'Reset Password',
      subtitle: 'Enter your email and we\'ll send you a reset link',
      children: [
        Form(
          key: _formKey,
          child: AuthTextField(
            controller: _email,
            label: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: AuthValidators.email,
          ),
        ),
        const SizedBox(height: 24),
        GoldButton(
          key: const Key('reset-submit'),
          label: loading ? 'Sending…' : 'Send Reset Link',
          onPressed: loading ? null : _submit,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: Text(
            'Back to Sign In',
            style: AppText.caption.copyWith(color: AppColors.goldLight),
          ),
        ),
      ],
    );
  }
}
