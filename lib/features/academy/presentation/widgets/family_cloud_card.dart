import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/glass_card.dart';
import '../../../../app/theme/widgets/tr_text.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/family_service.dart';
import '../../domain/learner_path.dart';

final AutoDisposeFutureProvider<bool> cloudConsentProvider =
    FutureProvider.autoDispose<bool>(
        (Ref ref) => ref.watch(familyServiceProvider).cloudConsented());

final AutoDisposeFutureProvider<List<Map<String, dynamic>>>
    cloudChildrenProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (Ref ref) async {
      final FamilyService fam = ref.watch(familyServiceProvider);
      await fam.syncNow(); // this device's latest first; no-op unless sync is on
      return fam.cloudChildren();
    });

final AutoDisposeFutureProvider<Map<String, String>> cloudLabelsProvider =
    FutureProvider.autoDispose<Map<String, String>>(
        (Ref ref) => ref.watch(familyServiceProvider).cloudLabels());

/// "Track my child from my own phone": sign in, switch sync on, then read each
/// child's level and progress from any device signed in to the same account.
class FamilyCloudCard extends ConsumerWidget {
  const FamilyCloudCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final bool signedIn = user != null && user.email.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        key: const Key('family-cloud-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('TRACK FROM YOUR OWN PHONE', style: AppText.eyebrow),
            const SizedBox(height: 6),
            if (!signedIn) ...<Widget>[
              Text(
                'Sign in with your own account on this device and on yours. '
                'Then you can see each child’s level, lessons, exam scores '
                'and where they read to in the Qur’an, from your phone.',
                style: AppText.body.copyWith(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('family-cloud-signin'),
                onPressed: () => context.push(AppRoutes.login),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Sign in'),
              ),
            ] else
              _SignedInBody(email: user.email),
          ],
        ),
      ),
    );
  }
}

class _SignedInBody extends ConsumerWidget {
  const _SignedInBody({required this.email});
  final String email;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final FamilyService fam = ref.read(familyServiceProvider);
    if (on) {
      final bool? yes = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text('Send progress to your account?', style: AppText.titleMedium),
          content: Text(
            'What is sent: for each child, a random id, lessons finished, exam '
            'scores, a level, the last time they studied, and the surah and '
            'ayah they last read.\n\n'
            'What is never sent: the child’s name, age band, answers, '
            'photos, voice or anything they typed.\n\n'
            'It is kept on your account only. Turn this off any time and the '
            'copy is deleted.',
            style: AppText.body.copyWith(fontSize: 13, height: 1.5),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not now')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes, send it')),
          ],
        ),
      );
      if (yes != true) return;
      await fam.turnCloudSyncOn();
    } else {
      await fam.turnCloudSyncOff();
    }
    ref.invalidate(cloudConsentProvider);
    ref.invalidate(cloudChildrenProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool on = ref.watch(cloudConsentProvider).valueOrNull ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Signed in as $email',
            style: AppText.bodyMuted.copyWith(fontSize: 12)),
        SwitchListTile(
          key: const Key('family-cloud-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text('Send my children’s progress to my account',
              style: AppText.body.copyWith(fontSize: 13)),
          subtitle: Text(
              on
                  ? 'On. Switch this on from the device your child uses.'
                  : 'Off. Nothing leaves this device.',
              style: AppText.bodyMuted.copyWith(fontSize: 12)),
          value: on,
          onChanged: (bool v) => _toggle(context, ref, v),
        ),
        if (on) const _CloudChildren(),
      ],
    );
  }
}

String _ago(String? iso) {
  if (iso == null) return 'no study yet';
  final DateTime? t = DateTime.tryParse(iso);
  if (t == null) return 'no study yet';
  final int d = DateTime.now().difference(t).inDays;
  if (d <= 0) return 'today';
  if (d == 1) return 'yesterday';
  return '$d days ago';
}

class _CloudChildren extends ConsumerWidget {
  const _CloudChildren();

  Future<void> _rename(
      BuildContext context, WidgetRef ref, String id, String current) async {
    final TextEditingController c = TextEditingController(text: current);
    final String? v = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Label for this child', style: AppText.titleMedium),
        content: TextField(
          controller: c,
          maxLength: 30,
          decoration: const InputDecoration(
              helperText: 'Kept on this phone only. Never sent anywhere.'),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (v == null) return;
    await ref.read(familyServiceProvider).setCloudLabel(id, v);
    ref.invalidate(cloudLabelsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(cloudChildrenProvider);
    final Map<String, String> labels =
        ref.watch(cloudLabelsProvider).valueOrNull ?? <String, String>{};
    final Map<String, String> localNames = <String, String>{
      for (final Map<String, dynamic> c
          in ref.watch(childrenProvider).valueOrNull ??
              const <Map<String, dynamic>>[])
        '${c['id']}': '${c['name']}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: <Widget>[
          Expanded(
              child: Text('Children on your account',
                  style: AppText.body
                      .copyWith(fontSize: 13, fontWeight: FontWeight.w600))),
          TextButton(
            key: const Key('family-cloud-refresh'),
            onPressed: () async {
              await ref.read(familyServiceProvider).syncNow();
              ref.invalidate(cloudChildrenProvider);
            },
            child: const Text('Refresh',
                style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
          ),
        ]),
        list.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(minHeight: 2)),
          error: (Object e, StackTrace _) => Text(
              'Could not load. Check your connection and tap Refresh.',
              style: AppText.bodyMuted.copyWith(fontSize: 12)),
          data: (List<Map<String, dynamic>> kids) {
            if (kids.isEmpty) {
              return Text(
                  'Nothing here yet. On your child’s device, sign in to this '
                  'account, add the child and switch this on. It appears here '
                  'within a minute.',
                  style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5));
            }
            return Column(children: <Widget>[
              for (int i = 0; i < kids.length; i++)
                _row(context, ref, kids[i], i, labels, localNames),
            ]);
          },
        ),
      ],
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, Map<String, dynamic> k,
      int i, Map<String, String> labels, Map<String, String> localNames) {
    final String id = '${k['id']}';
    final String label = labels[id] ?? localNames[id] ?? 'Child ${i + 1}';
    final int lessons = (k['lessonsDone'] as num? ?? 0).toInt();
    final int total = (k['lettersTotal'] as num? ?? 40).toInt();
    final int exams = (k['examsTaken'] as num? ?? 0).toInt();
    final int best = (k['bestPct'] as num? ?? 0).toInt();
    final int mastered = (k['masteredCount'] as num? ?? 0).toInt();
    final Object? q = k['quran'];
    String quran = 'Qur’an: no reading recorded yet';
    if (q is Map) {
      quran = 'Qur’an: last read surah ${q['surah']}, ayah ${q['ayah']}';
    }
    return Container(
      key: Key('cloud-child-$id'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(
                child: Text(label,
                    style: AppText.titleMedium.copyWith(fontSize: 15))),
            IconButton(
              tooltip: 'Label this child',
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.goldLight),
              onPressed: () => _rename(context, ref, id, labels[id] ?? ''),
            ),
          ]),
          Text(
              'Level: ${childLevelName(lettersDone: lessons, lettersTotal: total, exams: exams)}',
              style: AppText.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(
              '$lessons / $total letter lessons · $mastered mastered · '
              '$exams exam(s)${exams > 0 ? ' · best $best%' : ''}',
              style: AppText.bodyMuted.copyWith(fontSize: 12)),
          Text(quran, style: AppText.bodyMuted.copyWith(fontSize: 12)),
          Text('Last studied: ${_ago(k['lastActiveAt'] as String?)}',
              style: AppText.bodyMuted.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
