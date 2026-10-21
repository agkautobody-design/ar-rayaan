import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/glass_card.dart';
import '../../application/family_service.dart';
import 'parent_gate.dart';

/// Who is learning? Shown on every Letters screen once a parent has added a
/// child. Lessons and exams are saved to the ACTIVE child, so on a shared
/// device a sibling's work used to land on whoever was switched to last, with
/// nothing on screen saying who that was.
///
/// Nothing shows when no child has been added. Changing the child (or
/// choosing "nobody") sits behind the parent check.
class ActiveChildBanner extends ConsumerWidget {
  const ActiveChildBanner({super.key});

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    if (!await requireParent(context, ref)) return;
    if (!context.mounted) return;
    final List<Map<String, dynamic>> kids = ref.read(childrenProvider).valueOrNull ??
        const <Map<String, dynamic>>[];
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0A0F18),
      builder: (BuildContext ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: <Widget>[
            Text('Who is learning?', style: AppText.titleMedium),
            const SizedBox(height: 8),
            for (final Map<String, dynamic> c in kids)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.child_care_outlined,
                    color: AppColors.goldLight),
                title: Text(c['name'] as String, style: AppText.body),
                onTap: () => Navigator.pop(ctx, c['id'] as String),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_off_outlined,
                  color: AppColors.goldLight),
              title: Text('Nobody — do not save to a child',
                  style: AppText.body),
              onTap: () => Navigator.pop(ctx, ''),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final FamilyService fam = ref.read(familyServiceProvider);
    if (picked.isEmpty) {
      await fam.clearActiveChild();
    } else {
      await fam.setActiveChild(picked);
    }
    ref.invalidate(activeChildProvider);
    ref.read(learnerConfirmedProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Map<String, dynamic>> kids =
        ref.watch(childrenProvider).valueOrNull ??
            const <Map<String, dynamic>>[];
    if (kids.isEmpty) return const SizedBox.shrink();
    final Map<String, dynamic>? active =
        ref.watch(activeChildProvider).valueOrNull;
    final bool confirmed = ref.watch(learnerConfirmedProvider);
    final bool ask = kids.length > 1 && !confirmed;
    final String line = active == null
        ? 'No child is chosen, so progress is not being saved to a child.'
        : ask
            ? 'Who is learning? Saving to ${active['name']}.'
            : 'Learning as ${active['name']}.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: <Widget>[
            const Icon(Icons.child_care_outlined,
                size: 18, color: AppColors.goldLight),
            const SizedBox(width: 10),
            Expanded(
              child: Text(line,
                  key: const Key('active-child-line'),
                  style: AppText.bodyMuted.copyWith(fontSize: 13)),
            ),
            if (ask && active != null)
              TextButton(
                onPressed: () =>
                    ref.read(learnerConfirmedProvider.notifier).state = true,
                child: const Text('Yes',
                    style: TextStyle(color: AppColors.goldLight)),
              ),
            TextButton(
              key: const Key('active-child-change'),
              onPressed: () => _change(context, ref),
              child: Text(active == null ? 'Choose' : 'Change',
                  style: const TextStyle(color: AppColors.goldLight)),
            ),
          ],
        ),
      ),
    );
  }
}
