import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../../../app/theme/widgets/whole_word_text.dart';
import '../application/adhkar_providers.dart';
import '../domain/adhkar_models.dart';

/// Dhikr & Du'a — Hisn al-Muslim sets with tap-to-count repetitions and
/// daily-resetting progress. Pending Founder approval.
class AdhkarScreen extends ConsumerStatefulWidget {
  const AdhkarScreen({super.key, this.initialSet});

  /// The set to open straight on (`morning`, `evening`, `after-prayer`), from
  /// `/adhkar?set=…`. Null (or an id that does not exist) opens the chooser.
  final String? initialSet;

  @override
  ConsumerState<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends ConsumerState<AdhkarScreen> {
  String? _selectedSet;

  @override
  void initState() {
    super.initState();
    _selectedSet = widget.initialSet;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AdhkarSet>> sets = ref.watch(adhkarSetsProvider);
    // Re-evaluates which dhikr is next (it gets the big counter) on every tap.
    ref.watch(adhkarProgressProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Dhikr & Du\'a'),
            Expanded(
              child: sets.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                // The single duas do not need the counters to load.
                error: (Object e, _) => const AdhkarChooser(
                  sets: <AdhkarSet>[],
                  onOpenSet: null,
                ),
                data: (List<AdhkarSet> data) {
                  AdhkarSet? found;
                  for (final AdhkarSet s in data) {
                    if (s.id == _selectedSet) found = s;
                  }
                  if (found == null) {
                    return AdhkarChooser(
                      sets: data,
                      onOpenSet: (String id) =>
                          setState(() => _selectedSet = id),
                    );
                  }
                  final AdhkarSet set = found;
                  // The first dhikr not yet finished is the one to do next: its
                  // counter is the big one-thumb tap area.
                  int nextOpen = -1;
                  for (int i = 0; i < set.items.length; i++) {
                    final Dhikr d = set.items[i];
                    if (ref
                            .read(adhkarProgressProvider.notifier)
                            .doneFor(set.id, d.number) <
                        d.count) {
                      nextOpen = i;
                      break;
                    }
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('adhkar-all-duas'),
                          onPressed: () =>
                              setState(() => _selectedSet = null),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('All duas'),
                        ),
                      ),
                      _SetPicker(
                        sets: data,
                        selected: set.id,
                        onSelect: (id) => setState(() => _selectedSet = id),
                      ),
                      const SizedBox(height: 16),
                      _ProgressCard(set: set),
                      const SizedBox(height: 16),
                      GlassCard(
                        blur: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < set.items.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 24,
                                  color: AppColors.gold.withValues(alpha: 0.1),
                                ),
                              _DhikrCard(
                                set: set,
                                dhikr: set.items[i],
                                big: i == nextOpen,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SOURCE: HISN AL-MUSLIM · PROGRESS RESETS DAILY',
                        style: AppText.eyebrow.copyWith(
                          fontSize: 12,
                          color: AppColors.gold.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetPicker extends StatelessWidget {
  const _SetPicker({
    required this.sets,
    required this.selected,
    required this.onSelect,
  });

  final List<AdhkarSet> sets;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < sets.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              selected: sets[i].id == selected,
              child: GestureDetector(
              onTap: () => onSelect(sets[i].id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: sets[i].id == selected
                      ? AppColors.gold.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: sets[i].id == selected
                        ? AppColors.gold.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: WholeWordText(
                  sets[i].titleEn,
                  style: AppText.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sets[i].id == selected
                        ? AppColors.goldLight
                        : AppColors.sand.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({required this.set});

  final AdhkarSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adhkarProgressProvider);
    final int done = ref
        .read(adhkarProgressProvider.notifier)
        .completedInSet(set);
    final int total = set.totalRepetitions;
    final double ratio = total == 0 ? 0 : done / total;
    final bool complete = done >= total && total > 0;

    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 3.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                ),
                if (complete)
                  const Icon(Icons.check, color: AppColors.gold, size: 18)
                else
                  Text(
                    '${(ratio * 100).round()}%',
                    style: AppText.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  set.titleEn,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  complete
                      ? 'Complete — may Allah accept it'
                      : '$done of $total repetitions · ${total - done} remaining',
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (done > 0 && !complete)
            TextButton(
              onPressed: () =>
                  ref.read(adhkarProgressProvider.notifier).resetSet(set.id),
              child: Text(
                'Reset',
                style: AppText.caption.copyWith(
                  color: AppColors.goldLight,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DhikrCard extends ConsumerWidget {
  const _DhikrCard({
    required this.set,
    required this.dhikr,
    this.big = false,
  });

  final AdhkarSet set;
  final Dhikr dhikr;

  /// The dhikr to do next: its counter is a large tap area (160 dp circle)
  /// under the text instead of the small circle beside it.
  final bool big;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adhkarProgressProvider);
    final int done = ref
        .read(adhkarProgressProvider.notifier)
        .doneFor(set.id, dhikr.number);
    final bool complete = done >= dhikr.count;
    final bool bigCounter = big && !complete;

    final Widget details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          dhikr.arabic,
          style: AppText.arabicLarge.copyWith(
            fontSize: 18,
            height: 2.0,
            color: complete
                ? AppColors.sand.withValues(alpha: 0.45)
                : AppColors.sand,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        if (dhikr.transliteration != null) ...[
          Text(
            dhikr.transliteration!,
            key: Key('dhikr-${set.id}-${dhikr.number}-tl'),
            style: AppText.bodyMuted.copyWith(
              fontSize: 13,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: AppColors.goldLight.withValues(alpha: complete ? 0.4 : 0.9),
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (dhikr.translation != null) ...[
          Text(
            dhikr.translation!,
            style: AppText.bodyMuted.copyWith(
              fontSize: 12,
              height: 1.55,
              color: complete
                  ? AppColors.sand.withValues(alpha: 0.35)
                  : AppColors.sand.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (dhikr.source != null) ...[
          Text(
            'Source: ${dhikr.source!}',
            key: Key('dhikr-${set.id}-${dhikr.number}-source'),
            style: AppText.bodyMuted.copyWith(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.gold.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (dhikr.translation != null)
              SpeakButton(text: dhikr.translation!, size: 24)
            else
              const SizedBox.shrink(),
            Text(
              complete
                  ? 'Completed'
                  : '${dhikr.count} ${dhikr.count == 1 ? 'repetition' : 'repetitions'}',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
          ],
        ),
      ],
    );

    // Tap-to-count button. The whole circle is the tap area.
    final double size = bigCounter ? 160 : 52;
    final Widget counter = Semantics(
      button: true,
      label: complete
          ? 'Dhikr ${dhikr.number} complete'
          : 'Count dhikr ${dhikr.number}, ${dhikr.count - done} left',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: complete
            ? null
            : () => ref
                  .read(adhkarProgressProvider.notifier)
                  .increment(set.id, dhikr.number, dhikr.count),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: complete
                ? AppColors.gold.withValues(alpha: 0.18)
                : AppColors.gold.withValues(alpha: bigCounter ? 0.14 : 0.08),
            border: Border.all(
              color: complete
                  ? AppColors.gold
                  : AppColors.gold.withValues(alpha: 0.35),
              width: complete ? 1.6 : 1,
            ),
          ),
          child: complete
              ? const Icon(Icons.check, color: AppColors.gold, size: 20)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${dhikr.count - done}',
                      key: Key('dhikr-${set.id}-${dhikr.number}-remaining'),
                      style: AppText.titleMedium.copyWith(
                        color: AppColors.goldLight,
                        fontSize: bigCounter ? 44 : 16,
                      ),
                    ),
                    if (bigCounter)
                      Text(
                        'tap to count',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      ),
                  ],
                ),
        ),
      ),
    );

    if (bigCounter) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [details, const SizedBox(height: 14), Center(child: counter)],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: details),
          const SizedBox(width: 12),
          counter,
        ],
      ),
    );
  }
}

/// One row of the chooser: a plain label and what it opens.
class AdhkarChoice {
  const AdhkarChoice({
    required this.label,
    required this.icon,
    this.setId,
    this.storyId,
  });

  final String label;
  final IconData icon;

  /// A counted Hisn al-Muslim set in `assets/adhkar/adhkar.json`.
  final String? setId;

  /// A single dua in `assets/stories/dailyduas.json`, opened in the reader.
  final String? storyId;
}

/// The counted sets (shown only if they exist in the data).
const List<AdhkarChoice> kAdhkarSetChoices = <AdhkarChoice>[
  AdhkarChoice(label: 'Morning', icon: Icons.wb_sunny_outlined, setId: 'morning'),
  AdhkarChoice(
      label: 'Evening', icon: Icons.nights_stay_outlined, setId: 'evening'),
  AdhkarChoice(
      label: 'After prayer', icon: Icons.mosque_outlined, setId: 'after-prayer'),
];

/// Single duas, by the moment you are in. Every `storyId` is a dua in
/// `assets/stories/dailyduas.json` (a test checks it).
const List<AdhkarChoice> kAdhkarDuaChoices = <AdhkarChoice>[
  AdhkarChoice(
      label: 'Before sleep', icon: Icons.bedtime_outlined, storyId: 'dua-sleep'),
  AdhkarChoice(
      label: 'Waking up', icon: Icons.alarm_outlined, storyId: 'dua-waking'),
  AdhkarChoice(
      label: 'Worry or anxiety',
      icon: Icons.favorite_border,
      storyId: 'dua-anxiety'),
  AdhkarChoice(
      label: 'Travel', icon: Icons.luggage_outlined, storyId: 'dua-travel'),
  AdhkarChoice(
      label: 'Before eating',
      icon: Icons.restaurant_outlined,
      storyId: 'dua-eat-before'),
  AdhkarChoice(
      label: 'Entering home', icon: Icons.home_outlined, storyId: 'dua-home-in'),
  AdhkarChoice(
      label: 'Forgiveness',
      icon: Icons.water_drop_outlined,
      storyId: 'dua-istikhlas'),
];

/// What Dhikr & Du'a opens on: pick the moment, not a 351-count set.
class AdhkarChooser extends StatelessWidget {
  const AdhkarChooser({required this.sets, required this.onOpenSet, super.key});

  final List<AdhkarSet> sets;

  /// Opens a counted set in place. Null while the sets could not load.
  final void Function(String id)? onOpenSet;

  @override
  Widget build(BuildContext context) {
    final void Function(String id)? open = onOpenSet;
    final Map<String, AdhkarSet> byId = <String, AdhkarSet>{
      for (final AdhkarSet s in sets) s.id: s,
    };
    Widget row(AdhkarChoice c, String sub, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            blur: false,
            onTap: onTap,
            child: Row(
              children: [
                Icon(c.icon, size: 20, color: AppColors.goldLight),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.label,
                        style: AppText.body.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(sub,
                          style: AppText.bodyMuted.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
              ],
            ),
          ),
        );

    return ListView(
      key: const Key('adhkar-chooser'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'What do you need right now?',
          style: AppText.bodyMuted.copyWith(height: 1.5),
        ),
        const SizedBox(height: 14),
        if (open != null) ...[
          Text('COUNT AS YOU GO', style: AppText.eyebrow),
          const SizedBox(height: 8),
          for (final AdhkarChoice c in kAdhkarSetChoices)
            if (byId[c.setId] != null)
              row(
                c,
                '${byId[c.setId]!.items.length} remembrances',
                () => open(c.setId!),
              ),
          const SizedBox(height: 10),
        ],
        Text('A SINGLE DUA', style: AppText.eyebrow),
        const SizedBox(height: 8),
        for (final AdhkarChoice c in kAdhkarDuaChoices)
          row(
            c,
            'Arabic, meaning and source',
            () => context.open('${AppRoutes.storyReader}?id=${c.storyId}'),
          ),
        const SizedBox(height: 10),
        Text('MORE', style: AppText.eyebrow),
        const SizedBox(height: 8),
        row(
          const AdhkarChoice(label: 'All duas by moment', icon: Icons.shield_outlined),
          'Hisn al-Muslim: every dua, grouped',
          () => context.open('/academy/hisn'),
        ),
        row(
          const AdhkarChoice(label: 'For Your Heart', icon: Icons.spa_outlined),
          'A guide for what you are feeling',
          () => context.open(AppRoutes.feelings),
        ),
      ],
    );
  }
}
