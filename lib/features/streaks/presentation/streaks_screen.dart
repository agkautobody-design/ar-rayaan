import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/switch_row.dart';
import '../../elder/application/elder_mode.dart';
import '../../habits/application/return_loop.dart';
import '../../share/application/share_text.dart';
import '../../share/presentation/share_actions.dart';
import '../application/streaks_providers.dart';
import '../domain/streak_math.dart';
import 'streaks_card.dart' show streakPhrase;

/// What a shared "came back" line calls each streak. Prayers have none: a
/// prayer streak is never offered for sharing.
String? streakShareSubject(StreakTrack t) {
  switch (t) {
    case StreakTrack.quran:
      return 'the Qur’an';
    case StreakTrack.dhikr:
      return 'dhikr';
    case StreakTrack.returned:
      return 'my daily practice';
    case StreakTrack.prayers:
      return null;
  }
}

/// Streaks: Qur'an, dhikr, prayers logged and days returned. Gentle by
/// design: one grace day a week, no loss messages, kept on this device.
class StreaksScreen extends ConsumerStatefulWidget {
  const StreaksScreen({super.key});

  @override
  ConsumerState<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends ConsumerState<StreaksScreen> {
  StreakTrack _track = StreakTrack.returned;
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _atCurrentMonth {
    final DateTime n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  void _shift(int by) {
    final DateTime next = DateTime(_month.year, _month.month + by);
    final DateTime n = DateTime.now();
    if (next.isAfter(DateTime(n.year, n.month))) return;
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final bool on = kReturnLoopEnabled && ref.watch(returnLoopEnabledProvider);
    final bool elder = ref.watch(elderModeProvider);
    final double minTap = elder ? 64 : 48;
    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const ScreenHeader(title: 'Streaks', close: true),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: <Widget>[
                      Text(
                        'Gentle by design. One day off each week is forgiven, '
                        'a longer break simply starts a fresh run, and nothing '
                        'is ever said about it. Kept on this device only.',
                        key: const Key('streaks-intro'),
                        style: AppText.bodyMuted.copyWith(
                          fontSize: elder ? 18 : 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!on) ...<Widget>[
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Streaks are off.',
                                style: AppText.titleMedium.copyWith(
                                  fontSize: elder ? 24 : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Turn them on to keep a calendar of the days '
                                'you read, remember Allah, log your prayers '
                                'and come back.',
                                style: AppText.body.copyWith(
                                  fontSize: elder ? 18 : 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: BoxConstraints(minHeight: minTap),
                                child: FilledButton(
                                  key: const Key('streaks-screen-turn-on'),
                                  onPressed: () => unawaited(
                                    ref
                                        .read(returnLoopEnabledProvider.notifier)
                                        .set(true),
                                  ),
                                  child: const Text('Turn on'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...<Widget>[
                        _TrackPicker(
                          selected: _track,
                          minTap: minTap,
                          onPick: (StreakTrack t) => setState(() => _track = t),
                        ),
                        const SizedBox(height: 12),
                        _Summary(view: ref.watch(streakViewProvider(_track))),
                        const SizedBox(height: 12),
                        _MonthCard(
                          view: ref.watch(streakViewProvider(_track)),
                          month: _month,
                          canGoNext: !_atCurrentMonth,
                          onPrev: () => _shift(-1),
                          onNext: () => _shift(1),
                        ),
                        const SizedBox(height: 12),
                        _ShareBlock(view: ref.watch(streakViewProvider(_track))),
                      ],
                      const SizedBox(height: 16),
                      if (kReturnLoopEnabled)
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: SwitchRow(
                            icon: Icons.wb_twilight_outlined,
                            title: 'Keep my streaks',
                            subtitle:
                                'Switching off erases the saved days. Your '
                                'prayer log is yours and stays as it is.',
                            value: on,
                            onChanged: (bool v) => unawaited(
                              ref
                                  .read(returnLoopEnabledProvider.notifier)
                                  .set(v),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackPicker extends StatelessWidget {
  const _TrackPicker({
    required this.selected,
    required this.minTap,
    required this.onPick,
  });

  final StreakTrack selected;
  final double minTap;
  final ValueChanged<StreakTrack> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final StreakTrack t in StreakTrack.values)
          Semantics(
            button: true,
            selected: t == selected,
            label: t.label,
            excludeSemantics: true,
            onTap: () => onPick(t),
            child: InkWell(
              key: Key('streak-track-${t.name}'),
              borderRadius: BorderRadius.circular(24),
              onTap: () => onPick(t),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minTap),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: t == selected
                        ? AppColors.gold.withValues(alpha: 0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: AppColors.gold.withValues(
                        alpha: t == selected ? 0.9 : 0.35,
                      ),
                      width: t == selected ? 1.6 : 1,
                    ),
                  ),
                  child: Text(
                    t.label,
                    style: AppText.body.copyWith(
                      fontSize: 14,
                      fontWeight: t == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.view});

  final StreakView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool elder = ref.watch(elderModeProvider);
    final int n = view.days;
    final String headline = n >= StreakMath.minToShow
        ? streakPhrase(view.track, n)
        : n == 1
        ? 'One day so far. A good start.'
        : 'Begin whenever you are ready. Today is a good day.';
    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            headline,
            key: const Key('streak-headline'),
            style: AppText.titleMedium.copyWith(fontSize: elder ? 26 : null),
          ),
          const SizedBox(height: 8),
          Text(
            view.graceAvailable
                ? 'A grace day is ready this week. One day off will not end '
                      'your run.'
                : 'This week’s grace day is in use. A fresh one comes on '
                      'Monday.',
            key: const Key('streak-grace'),
            style: AppText.bodyMuted.copyWith(
              fontSize: elder ? 18 : 14,
              height: 1.5,
            ),
          ),
          if (view.track == StreakTrack.prayers) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'A day counts when you log at least one prayer. Days you mark '
              'as excused are skipped and never count against you.',
              key: const Key('streak-prayers-note'),
              style: AppText.bodyMuted.copyWith(
                fontSize: elder ? 18 : 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthCard extends ConsumerWidget {
  const _MonthCard({
    required this.view,
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  final StreakView view;
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool elder = ref.watch(elderModeProvider);
    final int lead = DateTime(month.year, month.month, 1).weekday - 1;
    final int count = DateTime(month.year, month.month + 1, 0).day;
    final int rows = ((lead + count) / 7).ceil();
    final double cell = elder ? 52 : 44;
    final int doneThisMonth = view.doneInMonth(month);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                key: const Key('streak-prev-month'),
                tooltip: 'Previous month',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.chevron_left, color: AppColors.gold),
                onPressed: onPrev,
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  key: const Key('streak-month'),
                  textAlign: TextAlign.center,
                  style: AppText.titleMedium.copyWith(
                    fontSize: elder ? 24 : 18,
                  ),
                ),
              ),
              IconButton(
                key: const Key('streak-next-month'),
                tooltip: 'Next month',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(
                  Icons.chevron_right,
                  color: canGoNext
                      ? AppColors.gold
                      : AppColors.gold.withValues(alpha: 0.3),
                ),
                onPressed: canGoNext ? onNext : null,
              ),
            ],
          ),
          Row(
            children: <Widget>[
              for (final String w in _weekdays)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      w,
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (int r = 0; r < rows; r++)
            Row(
              children: <Widget>[
                for (int c = 0; c < 7; c++)
                  Expanded(
                    child: _DayCell(
                      view: view,
                      height: cell,
                      elder: elder,
                      day: (r * 7 + c - lead + 1) >= 1 &&
                              (r * 7 + c - lead + 1) <= count
                          ? DateTime(month.year, month.month, r * 7 + c - lead + 1)
                          : null,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            doneThisMonth == 0
                ? 'Nothing marked this month yet.'
                : '$doneThisMonth ${doneThisMonth == 1 ? 'day' : 'days'} '
                      'this month.',
            key: const Key('streak-month-count'),
            style: AppText.bodyMuted.copyWith(fontSize: elder ? 16 : 14),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: <Widget>[
              _Legend(
                swatch: _swatch(filled: true),
                label: 'Done',
              ),
              _Legend(
                swatch: _swatch(filled: false),
                label: 'Grace day (forgiven)',
              ),
              if (view.track == StreakTrack.prayers)
                const _Legend(
                  swatch: Text('–', style: TextStyle(color: AppColors.sand)),
                  label: 'Excused (skipped)',
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _swatch({required bool filled}) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? AppColors.gold : Colors.transparent,
      border: Border.all(color: AppColors.gold, width: 1.6),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        swatch,
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: AppText.bodyMuted.copyWith(fontSize: 12)),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.view,
    required this.day,
    required this.height,
    required this.elder,
  });

  final StreakView view;
  final DateTime? day;
  final double height;
  final bool elder;

  @override
  Widget build(BuildContext context) {
    final DateTime? d = day;
    if (d == null) return SizedBox(height: height);
    final bool done = view.isDone(d);
    final bool grace = !done && view.isGrace(d);
    final bool neutral = !done && !grace && view.isNeutral(d);
    final bool today = StreakMath.stamp(d) == StreakMath.stamp(view.today);
    final bool future = d.isAfter(view.today);
    final String state = done
        ? 'done'
        : grace
        ? 'grace day, forgiven'
        : neutral
        ? 'excused, skipped'
        : '';
    final double dot = height - 8;
    return Semantics(
      label:
          '${DateFormat('d MMMM').format(d)}${today ? ', today' : ''}'
          '${state.isEmpty ? '' : ', $state'}',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Center(
          child: Container(
            key: Key('streak-day-${StreakMath.stamp(d)}'),
            width: dot,
            height: dot,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.gold : Colors.transparent,
              border: grace
                  ? Border.all(color: AppColors.gold, width: 1.6)
                  : today
                  ? Border.all(
                      color: AppColors.sand.withValues(alpha: 0.8),
                      width: 1,
                    )
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                neutral ? '–' : '${d.day}',
                style: TextStyle(
                  fontSize: elder ? 18 : 14,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                  color: done
                      ? AppColors.night
                      : future
                      ? AppColors.sand.withValues(alpha: 0.6)
                      : AppColors.sand,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareBlock extends ConsumerWidget {
  const _ShareBlock({required this.view});

  final StreakView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool elder = ref.watch(elderModeProvider);
    final String? subject = streakShareSubject(view.track);
    if (!view.track.shareable || subject == null) {
      return Text(
        'Prayer streaks stay private. They are never offered for sharing.',
        key: const Key('streak-prayers-private'),
        style: AppText.bodyMuted.copyWith(fontSize: elder ? 16 : 14),
      );
    }
    if (view.days < StreakMath.minToShow) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: elder ? 64 : 48),
        child: OutlinedButton.icon(
          key: const Key('streak-share'),
          onPressed: () => unawaited(
            showSharePreview(
              context,
              text: comeBackShareText(subject, view.days),
              subject: 'this milestone',
            ),
          ),
          icon: const Icon(Icons.ios_share, size: 18),
          label: const Text('Preview and share'),
        ),
      ),
    );
  }
}
