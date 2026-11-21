import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../application/user_knows_provider.dart';
import '../data/user_knows.dart';

/// Every line Hadi has noticed about this person, one delete button each, a
/// delete-all, and nothing else: no score, no mood, no hidden field.
class WhatHadiNoticedScreen extends ConsumerStatefulWidget {
  const WhatHadiNoticedScreen({super.key});

  @override
  ConsumerState<WhatHadiNoticedScreen> createState() => _State();
}

class _State extends ConsumerState<WhatHadiNoticedScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the screen picks up what another device of the same account
    // has learned (does nothing when signed out).
    Future<void>.microtask(() => ref.read(userKnowsProvider.notifier).syncNow());
  }

  @override
  Widget build(BuildContext context) {
    final UserKnows k = ref.watch(userKnowsProvider);
    final UserKnowsNotifier n = ref.read(userKnowsProvider.notifier);
    final List<MapEntry<String, KnownTopic>> topics = k.topics.entries.toList()
      ..sort((MapEntry<String, KnownTopic> a, MapEntry<String, KnownTopic> b) =>
          b.value.count.compareTo(a.value.count));
    final List<String> covered = (k.covered.entries.toList()
          ..sort((MapEntry<String, KnownTopic> a, MapEntry<String, KnownTopic> b) =>
              b.value.last.compareTo(a.value.last)))
        .map((MapEntry<String, KnownTopic> e) => e.key)
        .take(12)
        .toList();
    return Scaffold(
      body: Stack(children: <Widget>[
        const ScenicBackground.pattern(),
        SafeArea(
          child: Column(children: <Widget>[
            const ScreenHeader(title: 'What Hadi has noticed', showSettings: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: <Widget>[
                  Text(
                    'Hadi builds this over time from the questions you ask, so he '
                    'gets to know you and his answers fit you. It is only '
                    'subjects, the answers he has already given you and a few '
                    'things you said about yourself, never your questions, '
                    'health, safety or hard times. It is kept on this device, and in '
                    'your own account if you sign in. When Hadi asks the live '
                    'AI service about something outside his library, these '
                    'subject names (never your own words) go with the question '
                    'so the answer fits you. Switch noticing off and nothing '
                    'is used or sent.',
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  if (k.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Text('Hadi has noticed nothing yet.',
                          key: const Key('noticed-empty'),
                          style: AppText.body.copyWith(fontSize: 14)),
                    ),
                  for (final String r in k.roles)
                    _row(
                      UserKnowsRules.roleLabels[r]!,
                      'Delete this one',
                      () => n.forgetRole(r),
                    ),
                  for (final MapEntry<String, KnownTopic> e in topics)
                    _row(
                      'You often ask about: ${UserKnowsRules.labels[e.key]}',
                      'Delete this one',
                      () => n.forgetTopic(e.key),
                    ),
                  for (final String id in covered)
                    _row(
                      'We have been through: ${id.replaceAll('-', ' ')}',
                      'Delete this one',
                      () => n.forgetCovered(id),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('noticed-delete-all'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: k.isEmpty ? null : () => n.forgetAll(),
                    child: const Text('Delete everything'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anything you have not come back to for a year is forgotten by '
                    'itself.',
                    style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _row(String text, String tip, VoidCallback onDelete) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: <Widget>[
          const Icon(Icons.favorite_border, size: 16, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 14))),
          IconButton(
            tooltip: tip,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
        ]),
      );
}
