import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../legal/legal_routes.dart';
import '../application/auth_providers.dart';
import '../application/auth_repository.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

/// Create-account screen — name, email, password.
/// On success, routes to the email-verification screen.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

final TextStyle _legalStyle = AppText.caption.copyWith(
  fontSize: 12,
  color: Colors.white.withValues(alpha: 0.4),
);

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: _legalStyle.copyWith(
          color: AppColors.goldLight,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = await ref
        .read(authControllerProvider.notifier)
        .signUp(_name.text, _email.text, _password.text);
    if (user != null && mounted) context.go(AppRoutes.verify);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;
    final error = state.hasError
        ? (state.error! as AuthException).message
        : null;

    return AuthScaffold(
      title: 'Create Account',
      subtitle: 'Begin your journey with Ar-Rayaan',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                controller: _name,
                label: 'Full name',
                icon: Icons.person_outline,
                validator: AuthValidators.name,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: AuthValidators.email,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _password,
                label: 'Password',
                icon: Icons.lock_outline,
                obscure: _obscure,
                validator: AuthValidators.password,
                suffix: IconButton(tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.sand.withValues(alpha: 0.7),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Password must be at least 6 characters.',
          style: AppText.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        if (error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.destructive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.destructive.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              error,
              style: AppText.caption.copyWith(color: const Color(0xFFF3A9A9)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        GoldButton(
          key: const Key('signup-submit'),
          label: loading ? 'Creating…' : 'Create Account',
          onPressed: loading ? null : _submit,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Already have an account?', style: AppText.caption),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Sign in',
                style: AppText.caption.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'By creating an account you agree to our',
                style: _legalStyle,
              ),
              _LegalLink(
                key: const Key('signup-terms'),
                label: 'Terms of Service',
                onTap: () => context.push(LegalRoutes.terms),
              ),
              Text('and', style: _legalStyle),
              _LegalLink(
                key: const Key('signup-privacy'),
                label: 'Privacy Policy',
                onTap: () => context.push(LegalRoutes.privacy),
              ),
              Text('.', style: _legalStyle),
            ],
          ),
        ),
      ],
    );
  }
}
