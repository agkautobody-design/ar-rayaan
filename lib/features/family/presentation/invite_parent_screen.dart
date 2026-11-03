import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../application/family_providers.dart';

class InviteParentScreen extends ConsumerStatefulWidget {
  const InviteParentScreen({super.key});

  @override
  ConsumerState<InviteParentScreen> createState() => _InviteParentScreenState();
}

class _InviteParentScreenState extends ConsumerState<InviteParentScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    await ref.read(familyControllerProvider.notifier).inviteParent(email);
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const TrText('Invite Co-Parent', style: AppText.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TrText(
              'Invite your spouse or co-parent to share access to your children\'s '
              'learning progress, academy updates, and teacher communications.',
              style: AppText.body,
            ),
            const SizedBox(height: 32),
            if (!_sent) ...[
              TextField(
                controller: _email,
                style: AppText.body.copyWith(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Co-Parent Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
                ),
              ),
              const SizedBox(height: 32),
              GoldButton(
                onPressed: _sendInvite,
                label: 'Send Invite',
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 64, color: AppColors.gold),
                    const SizedBox(height: 16),
                    const TrText(
                      'Invitation sent!\nYour co-parent will receive an email '
                      'and can join your family once they sign up.',
                      style: AppText.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GoldButton(
                      onPressed: () => context.pop(),
                      label: 'Done',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
