/// Path UX widgets: the weekly rhythm strip and the placement quiz.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/core/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/glass_card.dart';
import '../../application/academy_providers.dart';
import '../../domain/path_ux.dart';

const List<String> _kWeekdayInitials = <String>[
  'M', 'T', 'W', 'T', 'F', 'S', 'S',
];

/// Seven dots for the last seven days and one gentle line. No streak.
class WeeklyRhythmCard extends ConsumerWidget {
  const WeeklyRhythmCard({super.key, this.now});

  /// Injected for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read when lessons are finished; the log itself is plain prefs.
    try {
      ref.watch(academyProgressProvider);
    } catch (_) {}
    Set<String> days = <String>{};
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      days = ActivityLog.decode(prefs.getString(ActivityLog.prefKey));
    } catch (_) {}
    final DateTime today = now ?? DateTime.now();
    final WeeklyRhythm r = WeeklyRhythm.of(days, today);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('THIS WEEK', style: AppText.eyebrow),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (int i = 0; i < r.days.length; i++)
                Column(
                  children: <Widget>[
                    Container(
                      key: ValueKey<String>('rhythm-${r.days[i]}'),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r.active[i]
                            ? AppColors.gold
                            : AppColors.gold.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _kWeekdayInitials[
                          DateTime.parse(r.days[i]).weekday - 1],
                      style: AppText.caption,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.message, style: AppText.bodyMuted),
        ],
      ),
    );
  }
}

/// A card that opens the placement quiz.
class PlacementQuizCard extends StatelessWidget {
  const PlacementQuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => showPlacementQuiz(context),
      child: Row(
        children: <Widget>[
          const Icon(Icons.flag_outlined, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Not sure where to start?', style: AppText.body),
                const SizedBox(height: 2),
                Text(
                  'A two-minute check suggests a lesson. You can always start '
                  'from the beginning.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gold),
        ],
      ),
    );
  }
}

Future<void> showPlacementQuiz(BuildContext context) => showDialog<void>(
      context: context,
      builder: (BuildContext c) => const PlacementQuizDialog(),
    );

class PlacementQuizDialog extends StatefulWidget {
  const PlacementQuizDialog({super.key});

  @override
  State<PlacementQuizDialog> createState() => _PlacementQuizDialogState();
}

class _PlacementQuizDialogState extends State<PlacementQuizDialog> {
  final List<bool> _correct = <bool>[];

  bool get _done => _correct.length >= PlacementQuiz.questions.length;

  @override
  Widget build(BuildContext context) {
    if (_done) {
      final String? start = PlacementQuiz.recommend(_correct);
      return AlertDialog(
        title: const Text('Where to begin'),
        content: Text(
          start == null
              ? 'You answered everything. You are ready for the Word Decks.'
              : 'A good place to start is ${_label(start)}. You can still '
                  'open any lesson.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (start != null)
            TextButton(
              key: const ValueKey<String>('placement-go'),
              onPressed: () {
                final GoRouter router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.go('/academy/letters/lesson/$start');
              },
              child: const Text('Start there'),
            ),
        ],
      );
    }
    final int i = _correct.length;
    final PlacementQuestion q = PlacementQuiz.questions[i];
    return AlertDialog(
      title: Text('Question ${i + 1} of ${PlacementQuiz.questions.length}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(q.prompt),
          const SizedBox(height: 12),
          for (int k = 0; k < q.options.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: ValueKey<String>('placement-opt-$k'),
                  onPressed: () => setState(() => _correct.add(k == q.answer)),
                  child: Text(q.options[k],
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _label(String lessonId) {
    final int n = int.tryParse(lessonId.split('-').last) ?? 1;
    return n == 1 ? 'lesson 1, the first letters' : 'lesson $n';
  }
}
