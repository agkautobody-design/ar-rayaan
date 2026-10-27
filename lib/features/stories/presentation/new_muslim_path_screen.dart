import '../../../app/core/scholar_review.dart';
import '../domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/router.dart';
import '../data/stories_repository.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// The New Muslim 30-Day Path — the same thirty lessons that live in the
/// Stories library, walked here as a guided road: one gentle step a day,
/// progress remembered on this device, and a door back to the library
/// at any moment. Navigation is free — a revert's life is not linear —
/// the order is a suggestion, not a lock.
class NewMuslimPathScreen extends ConsumerStatefulWidget {
  const NewMuslimPathScreen({super.key});

  static const String donePrefix = 'ar.nm.done.';

  @override
  ConsumerState<NewMuslimPathScreen> createState() => _PathState();
}

class _PathState extends ConsumerState<NewMuslimPathScreen> {
  Set<String> _walked = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final Set<String> walked = <String>{};
    for (final String k in p.getKeys()) {
      if (k.startsWith(NewMuslimPathScreen.donePrefix) &&
          p.getBool(k) == true) {
        walked.add(k.substring(NewMuslimPathScreen.donePrefix.length));
      }
    }
    if (mounted) setState(() => _walked = walked);
  }

  Future<void> _mark(String id, bool value) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setBool('${NewMuslimPathScreen.donePrefix}$id', value);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: stories.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Text('The path could not load.', style: AppText.bodyMuted),
        ),
        data: (all) {
          final repo = ref.read(storiesRepositoryProvider);
          final List<Story> days = repo.byCollection(all, 'newmuslim')
            ..sort((a, b) => a.id.compareTo(b.id));
          if (days.isEmpty) {
            return Center(
              child: Text('The path is not on this device yet.',
                  style: AppText.bodyMuted),
            );
          }
          int doneCount = 0;
          Story? next;
          for (final Story d in days) {
            if (_walked.contains(d.id)) {
              doneCount++;
            } else if (next == null) {
              next = d;
            }
          }
          final bool complete = doneCount == days.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'The New Muslim Path', close: true),
              const ScholarReviewNote(
                reviewKey: 'new-muslim',
                padding: const EdgeInsets.only(bottom: 8),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text('THIRTY GENTLE DAYS · ONE STEP AT A TIME',
                    style: AppText.eyebrow),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 14),
                child: Text(
                  'Each day is one door. Walk them in order or follow your '
                  'need — the road is a suggestion, not a lock. Your steps '
                  'are remembered on this device only.',
                  style: AppText.bodyMuted,
                ),
              ),
              GlassCard(
                key: const Key('nm-academy-path'),
                blur: false,
                onTap: () => context.push('/academy/course/the-path'),
                semanticsLabel: 'Also in the Academy: The Path, the same '
                    'ground lesson by lesson, with questions and saved '
                    'progress',
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined,
                        size: 22, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ALSO IN THE ACADEMY', style: AppText.eyebrow),
                          const SizedBox(height: 2),
                          Text(
                            'The Path: lesson by lesson, with questions',
                            style: AppText.body.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.gold),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (complete)
                GlassCard(
                  strong: true,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thirty doors, all walked.',
                          style: AppText.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Mā shā’ Allāh. You began with a sentence and ended '
                        'with a way of life. Keep Hādi beside you for what '
                        'comes next, and let a local masjid know you — '
                        'community is the next door.',
                        style: AppText.bodyMuted.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      FocusableTap(
                        onTap: () => context.go(AppRoutes.hadi),
                        child: Text('Open Ask Hādi →',
                            style: AppText.bodyMuted.copyWith(
                                color: AppColors.gold)),
                      ),
                    ],
                  ),
                )
              else if (next != null)
                GlassCard(
                  strong: true,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continue your road', style: AppText.eyebrow),
                      const SizedBox(height: 6),
                      Text(next.title, style: AppText.titleMedium),
                      const SizedBox(height: 4),
                      Text(next.subtitle, style: AppText.bodyMuted),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text('$doneCount / ${days.length} walked',
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 12)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _mark(next!.id, true);
                              context.open(AppRoutes.storyReader,
                                  extra: next);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.night,
                            ),
                            child: const Text('Walk today’s step'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              for (final Story d in days)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onLongPress: () => _mark(d.id, !_walked.contains(d.id)),
                    child: GlassCard(
                      blur: false,
                    onTap: () {
                      _mark(d.id, true);
                      context.open(AppRoutes.storyReader, extra: d);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _walked.contains(d.id)
                                  ? AppColors.gold
                                  : AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: _walked.contains(d.id)
                                ? const Icon(Icons.check,
                                    size: 16, color: AppColors.gold)
                                : Text(
                                    d.id.split('-').last,
                                    style: AppText.bodyMuted.copyWith(
                                        fontSize: 12),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5)),
                              const SizedBox(height: 2),
                              Text(d.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.bodyMuted.copyWith(
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 4),
                child: Text(
                  'Long-press a day to un-walk it. The full library is '
                  'always open under Stories → The New Muslim Path.',
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
