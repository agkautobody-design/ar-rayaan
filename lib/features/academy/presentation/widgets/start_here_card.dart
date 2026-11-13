/// "Where are you?" and "Start here": the learner says where they are (or
/// does not, and keeps going), and sees three places to begin, never a long
/// list. No test, no score. Changeable at any time.
library;

import 'package:flutter/material.dart' hide Text;
import '../../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/glass_card.dart';
import '../../application/academy_providers.dart';
import '../../domain/learner_path.dart';
import 'path_placement_dialog.dart' show showPathPlacement;
import 'path_ux_widgets.dart' show showPlacementQuiz;

class StartHereCard extends ConsumerWidget {
  const StartHereCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LearnerLevel? level = ref.watch(learnerLevelProvider);
    final List<PathStop> stops =
        level == null ? const <PathStop>[] : startHere(level);
    return GlassCard(
      key: const Key('start-here-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(level == null ? 'WHERE ARE YOU?' : 'START HERE',
              style: AppText.eyebrow.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            level == null
                ? 'Tell Wasia where you are and she will show you three good '
                    'places to begin. You can change this any time.'
                : level.blurb,
            style: AppText.bodyMuted.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              for (final LearnerLevel l in LearnerLevel.values)
                ChoiceChip(
                  key: Key('level-${l.prefValue}'),
                  label: Text(l.label),
                  selected: level == l,
                  onSelected: (_) =>
                      ref.read(learnerLevelProvider.notifier).set(l),
                ),
            ],
          ),
          // Someone who knows some Arabic need not start at the first letter:
          // a two-minute check suggests where to begin. Optional, never marked.
          if (level == LearnerLevel.basics || level == LearnerLevel.deeper)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('start-letters-check'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => showPlacementQuiz(context),
                icon: const Icon(Icons.checklist,
                    size: 16, color: AppColors.goldLight),
                label: Text('Not sure about the letters? Two-minute check',
                    style: AppText.body
                        .copyWith(fontSize: 13, color: AppColors.goldLight)),
              ),
            ),
          if (level == LearnerLevel.basics || level == LearnerLevel.deeper)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('start-path-check'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => showPathPlacement(context),
                icon: const Icon(Icons.route_outlined,
                    size: 16, color: AppColors.goldLight),
                label: Text('Where should I start in The Path? Eight questions',
                    style: AppText.body
                        .copyWith(fontSize: 13, color: AppColors.goldLight)),
              ),
            ),
          for (final PathStop p in stops)
            ListTile(
              key: Key('start-stop-${p.route}'),
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 8,
              title: Text(p.title, style: AppText.body),
              subtitle:
                  Text(p.why, style: AppText.bodyMuted.copyWith(fontSize: 12)),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.gold),
              onTap: () => context.go(p.route),
            ),
        ],
      ),
    );
  }
}
