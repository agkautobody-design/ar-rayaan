import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../application/auth_providers.dart';
import '../application/auth_repository.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

/// Sign-in screen — email + password with Google / Apple options.
///
/// This screen (and the rest of the auth flow) is pending Founder approval;
/// it follows the locked visual system: night background, gold accents,
/// glass container, Playfair Display headings, Inter body.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
    if (user != null && mounted) context.go(AppRoutes.home);
  }

  Future<void> _social(Future<AuthUser?> Function() signIn) async {
    final user = await signIn();
    if (user != null && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;
    final error = state.hasError
        ? (state.error! as AuthException).message
        : null;

    return AuthScaffold(
      title: 'Welcome Back',
      subtitle: 'Sign in to continue your journey',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
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
                suffix: IconButton(
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go(AppRoutes.reset),
            child: Text(
              'Forgot password?',
              style: AppText.caption.copyWith(color: AppColors.goldLight),
            ),
          ),
        ),
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
          key: const Key('login-submit'),
          label: loading ? 'Signing in…' : 'Sign In',
          onPressed: loading ? null : _submit,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: AppText.caption),
            ),
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                key: const Key('login-google'),
                label: 'Google',
                icon: Icons.g_mobiledata,
                onPressed: loading
                    ? null
                    : () => _social(
                        () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                key: const Key('login-apple'),
                label: 'Apple',
                icon: Icons.apple,
                onPressed: loading
                    ? null
                    : () => _social(
                        () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithApple(),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('New to Ar-Rayaan?', style: AppText.caption),
            TextButton(
              onPressed: () => context.go(AppRoutes.signup),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Create account',
                style: AppText.caption.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(AppRoutes.home),
          child: Text(
            'Continue as guest',
            style: AppText.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              decoration: TextDecoration.underline,
              decorationColor: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.sand, size: 22),
      label: Text(label, style: AppText.label.copyWith(color: AppColors.sand)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}
