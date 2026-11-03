import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../application/family_providers.dart';
import '../domain/family_models.dart';

class FamilyManagementScreen extends ConsumerWidget {
  const FamilyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const TrText('Family', style: AppText.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: familyAsync.when(
        data: (family) => _Body(family: family),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
          child: TrText('Error: $e', style: AppText.body.copyWith(color: Colors.red)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChildDialog(context, ref),
        backgroundColor: AppColors.gold,
        icon: const Icon(Icons.person_add, color: Colors.black),
        label: const TrText('Add Child', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.night,
        title: const TrText('Add a Child', style: AppText.heading4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: AppText.body.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Child's Name",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gradeCtrl,
              style: AppText.body.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Grade / Level (optional)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TrText('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          GoldButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final child = await ref.read(familyControllerProvider.notifier)
                  .addChild(name, grade: gradeCtrl.text.trim());
              if (child != null && context.mounted) {
                _showCredentialsDialog(context, child);
              }
            },
            label: 'Create Account',
          ),
        ],
      ),
    );
  }

  void _showCredentialsDialog(BuildContext context, Child child) {
    final message = "Ar-Rayaan - Child Login\n\nName: ${child.name}\nEmail: ${child.email}\nPassword: (sent securely)\n\nDownload Ar-Rayaan and sign in with these credentials to start learning.\n\nParents can monitor progress and speak to Wasia anytime.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.night,
        title: const TrText('Child Account Created', style: AppText.heading4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrText('Name: ${child.name}', style: AppText.body),
            const SizedBox(height: 8),
            TrText('Email: ${child.email}', style: AppText.body),
            const SizedBox(height: 16),
            const TrText(
              'Send these credentials to your child via text message. '
              'They can log in on their own device.',
              style: AppText.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TrText('Close', style: TextStyle(color: Colors.white70)),
          ),
          GoldButton(
            onPressed: () {
              Share.share(message, subject: 'Ar-Rayaan Child Login');
              Navigator.pop(ctx);
            },
            label: 'Send via Text',
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({this.family});
  final Family? family;

  @override
  Widget build(BuildContext context) {
    final children = family?.children ?? [];
    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.family_restroom, size: 64, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const TrText(
                'No children added yet.\nTap "Add Child" to create an account '
                'for your child and monitor their learning.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: children.length,
      itemBuilder: (ctx, i) {
        final child = children[i];
        return _ChildCard(child: child);
      },
    );
  }
}

class _ChildCard extends ConsumerWidget {
  const _ChildCard({required this.child});
  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.gold.withValues(alpha: 0.2),
          child: Text(
            child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
            style: AppText.label.copyWith(color: AppColors.gold),
          ),
        ),
        title: TrText(child.name, style: AppText.label.copyWith(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (child.grade != null && child.grade!.isNotEmpty)
              TrText(child.grade!, style: AppText.caption.copyWith(color: Colors.white70)),
            TrText(child.email, style: AppText.caption.copyWith(color: Colors.white54)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onSelected: (value) async {
            if (value == 'monitor') {
              context.push('/family/child/${child.id}/progress');
            } else if (value == 'wasia') {
              context.push('/family/child/${child.id}/wasia');
            } else if (value == 'remove') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.night,
                  title: const TrText('Remove Child?', style: AppText.heading4),
                  content: TrText(
                    'This will remove ${child.name} from your family list. '
                    'Their account will remain active.',
                    style: AppText.body,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const TrText('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const TrText('Remove', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(familyControllerProvider.notifier).removeChild(child.id);
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'monitor', child: TrText('View Progress')),
            const PopupMenuItem(value: 'wasia', child: TrText('Speak to Wasia')),
            const PopupMenuItem(value: 'remove', child: TrText('Remove', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
