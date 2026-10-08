import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_text.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../habits/presentation/habits_card.dart';
import '../application/journey_providers.dart';

/// Screen 8 · My Journey — progress ring + My Path.
///
/// Locked layout preserved; the ring is now REAL progress (adhkar today,
/// Qur'an reading started, reflections saved) — pending Founder approval.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  static const List<(IconData, String, String?)> _path = [
    (Icons.auto_stories_outlined, 'My Reflections', AppRoutes.noor),
    (Icons.track_changes, 'Goals', null),
    (Icons.edit_note, 'Gratitude Journal', null),
    (Icons.bookmark_outline, 'Bookmarks', null),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<JourneyStats> stats = ref.watch(journeyStatsProvider);
    final JourneyStats? s = stats.valueOrNull;
    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: 'My Journey'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Journey Progress',
                                style: AppText.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You are growing beautifully.',
                                style: AppText.bodyMuted.copyWith(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              if (s != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'ADHKAR ${s.adhkarDone}/${s.adhkarTotal} · QUR’AN ${s.readingStarted ? 'STARTED' : '—'} · REFLECTIONS ${s.reflections}',
                                  style: AppText.eyebrow.copyWith(
                                    fontSize: 9,
                                    color: AppColors.sand.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _ProgressRing(value: s?.progress ?? 0),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 24, bottom: 8),
                    child: Text('MY PATH', style: AppText.eyebrow),
                  ),
                  GlassCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < _path.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: AppColors.gold.withValues(alpha: 0.1),
                              indent: 64,
                            ),
                          Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: _path[i].$3 == null
                                  ? null
                                  : () => context.go(_path[i].$3!),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    IconTile(icon: _path[i].$1),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _path[i].$2,
                                        style: AppText.body.copyWith(
                                          color: AppColors.sand.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: AppColors.gold.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const HabitsCard(),
                  const SizedBox(height: 32),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'وَقُل رَّبِّ زِدْنِي عِلْمًا',
                      style: AppText.arabicLarge.copyWith(
                        fontSize: 24,
                        color: AppColors.gold.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOut,
        builder: (context, v, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: v,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
              Center(
                child: GoldText(
                  '${(v * 100).round()}%',
                  style: AppText.titleMedium.copyWith(fontSize: 20),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
