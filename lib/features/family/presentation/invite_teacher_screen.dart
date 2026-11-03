import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../application/family_providers.dart';

class InviteTeacherScreen extends ConsumerStatefulWidget {
  const InviteTeacherScreen({super.key});

  @override
  ConsumerState<InviteTeacherScreen> createState() => _InviteTeacherScreenState();
}

class _InviteTeacherScreenState extends ConsumerState<InviteTeacherScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    await ref.read(familyControllerProvider.notifier).inviteTeacher(email);
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Invite a Teacher', style: AppText.displayMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invite a live teacher to review your child\'s work, provide feedback, '
              'and communicate directly with you about their progress.',
              style: AppText.body,
            ),
            const SizedBox(height: 32),
            if (!_sent) ...[
              TextField(
                controller: _name,
                style: AppText.body.copyWith(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Teacher Name (optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _email,
                style: AppText.body.copyWith(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Teacher Email',
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
                    const Text(
                      'Teacher invited!\nThey will receive an email and can '
                      'access your children\'s progress once they accept.',
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
