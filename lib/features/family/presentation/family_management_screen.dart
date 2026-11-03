import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
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
        title: const Text('Family', style: AppText.displayMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: familyAsync.when(
        data: (family) => _Body(family: family),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: AppText.body.copyWith(color: Colors.red)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChildDialog(context, ref),
        backgroundColor: AppColors.gold,
        icon: const Icon(Icons.person_add, color: Colors.black),
        label: const Text('Add Child', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.night,
        title: const Text('Add a Child', style: AppText.titleMedium),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
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

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.night,
        title: const Text('Child Account Created', style: AppText.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${child.name}', style: AppText.body),
            const SizedBox(height: 8),
            Text('Email: ${child.email}', style: AppText.body),
            const SizedBox(height: 16),
            const Text(
              'Send these credentials to your child via text message. '
              'They can log in on their own device.',
              style: AppText.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
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
    return Column(
      children: [
        // Invite buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.person_add_alt_1,
                  label: 'Invite Co-Parent',
                  onTap: () => context.push('/family/invite-parent'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.school,
                  label: 'Invite Teacher',
                  onTap: () => context.push('/family/invite-teacher'),
                ),
              ),
            ],
          ),
        ),
        // Children list or empty state
        Expanded(
          child: children.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        const Text(
                          'No children added yet.\nTap "Add Child" to create an account '
                          'for your child and monitor their learning.',
                          style: AppText.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: children.length,
                  itemBuilder: (ctx, i) => _ChildCard(child: children[i]),
                ),
        ),
      ],
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
        title: Text(child.name, style: AppText.label.copyWith(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (child.grade != null && child.grade!.isNotEmpty)
              Text(child.grade!, style: AppText.caption.copyWith(color: Colors.white70)),
            Text(child.email, style: AppText.caption.copyWith(color: Colors.white54)),
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
                  title: const Text('Remove Child?', style: AppText.titleMedium),
                  content: Text(
                    'This will remove ${child.name} from your family list. '
                    'Their account will remain active.',
                    style: AppText.body,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Remove', style: TextStyle(color: Colors.red)),
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
            const PopupMenuItem(value: 'monitor', child: Text('View Progress')),
            const PopupMenuItem(value: 'wasia', child: Text('Speak to Wasia')),
            const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}


class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 28),
            const SizedBox(height: 8),
            Text(label, style: AppText.caption.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
