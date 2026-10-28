import 'dart:async' show unawaited;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
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
import '../application/tracking_providers.dart';
import '../domain/encouragement.dart';
import '../domain/tracking_math.dart';
import 'gentle_nudge.dart';
import 'tracking_card.dart' show totalSentence;
import '../../../app/theme/widgets/focus_ring.dart';

/// My log: plain totals (this week, this month, all time), the last day
/// something was logged, and a calendar of the days the person logged. Kept
/// on this device only. Nothing resets, nothing is compared, and a day with
/// nothing on it is just empty space.
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  TrackingTrack _track = TrackingTrack.all;
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
    final bool needsSwitch = _track.needsSwitch || _track == TrackingTrack.all;
    final bool showOffInvite = !on && _track.needsSwitch;
    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const ScreenHeader(title: 'My log', close: true),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: <Widget>[
                      Text(
                        'Your own totals and a calendar of what you logged. '
                        'It only adds up, nothing starts over, and a day with '
                        'nothing on it is simply empty. Kept on this device '
                        'only.',
                        key: const Key('log-intro'),
                        style: AppText.bodyMuted.copyWith(
                          fontSize: elder ? 18 : 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TrackPicker(
                        selected: _track,
                        minTap: minTap,
                        onPick: (TrackingTrack t) =>
                            setState(() => _track = t),
                      ),
                      const SizedBox(height: 12),
                      if (showOffInvite)
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'The private log is off.',
                                style: AppText.titleMedium.copyWith(
                                  fontSize: elder ? 24 : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Turn it on to keep totals and a calendar of '
                                'the days you read, remember Allah and learn. '
                                'Your prayer and fasting logs are always '
                                'here.',
                                style: AppText.body.copyWith(
                                  fontSize: elder ? 18 : 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: BoxConstraints(minHeight: minTap),
                                child: FilledButton(
                                  key: const Key('log-screen-turn-on'),
                                  onPressed: () => unawaited(
                                    ref
                                        .read(
                                          returnLoopEnabledProvider.notifier,
                                        )
                                        .set(true),
                                  ),
                                  child: const Text('Turn on'),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...<Widget>[
                        _Summary(
                          view: ref.watch(trackingViewProvider(_track)),
                          note: needsSwitch && !on
                              ? 'Turn on the private log to add Qur’an, '
                                    'dhikr and lessons here.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _MonthCard(
                          view: ref.watch(trackingViewProvider(_track)),
                          month: _month,
                          canGoNext: !_atCurrentMonth,
                          onPrev: () => _shift(-1),
                          onNext: () => _shift(1),
                        ),
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
                            title: 'Keep a private log',
                            subtitle:
                                'Switching off erases the days it saved for '
                                'Qur’an, dhikr and lessons. Your prayer and '
                                'fasting logs are yours and stay as they '
                                'are.',
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

  final TrackingTrack selected;
  final double minTap;
  final ValueChanged<TrackingTrack> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final TrackingTrack t in TrackingTrack.values)
          Semantics(
            button: true,
            selected: t == selected,
            label: t.label,
            excludeSemantics: true,
            onTap: () => onPick(t),
            child: FocusRing(borderRadius: 24, child: InkWell(
              key: Key('log-track-${t.name}'),
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
            )),
          ),
      ],
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.view, this.note});

  final TrackingView view;
  final String? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool elder = ref.watch(elderModeProvider);
    final Encouragement e = ref.watch(encouragementProvider);
    final TrackingTrack t = view.track;
    final int week = view.total(LogPeriod.week);
    final DateTime? last = view.lastLogged;
    final TextStyle small = AppText.bodyMuted.copyWith(
      fontSize: elder ? 18 : 14,
      height: 1.5,
    );
    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            e.text ?? totalSentence(t, LogPeriod.week, week),
            key: const Key('log-headline'),
            style: AppText.titleMedium.copyWith(fontSize: elder ? 26 : null),
          ),
          if (e.text != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              totalSentence(t, LogPeriod.week, week),
              key: const Key('log-week-sentence'),
              style: small,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _Total(
                label: 'This week',
                value: view.total(LogPeriod.week),
                tileKey: const Key('log-total-week'),
                elder: elder,
              ),
              _Total(
                label: 'This month',
                value: view.total(LogPeriod.month),
                tileKey: const Key('log-total-month'),
                elder: elder,
              ),
              _Total(
                label: 'All time',
                value: view.total(LogPeriod.allTime),
                tileKey: const Key('log-total-all'),
                elder: elder,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t == TrackingTrack.prayers
                ? 'Prayers you marked as prayed, on time or late.'
                : 'Days with something logged.',
            style: small.copyWith(fontSize: elder ? 16 : 12),
          ),
          const SizedBox(height: 8),
          Text(
            last == null
                ? 'Nothing logged here yet.'
                : 'Last logged: ${DateFormat('d MMMM yyyy').format(last)}.',
            key: const Key('log-last'),
            style: small,
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(note!, key: const Key('log-switch-note'), style: small),
          ],
          if (e.nudge != null) GentleNudge(text: e.nudge!),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    required this.tileKey,
    required this.elder,
  });

  final String label;
  final int value;
  final Key tileKey;
  final bool elder;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        key: tileKey,
        children: <Widget>[
          Text(
            '$value',
            style: AppText.titleMedium.copyWith(
              fontSize: elder ? 28 : 24,
              color: AppColors.gold,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppText.bodyMuted.copyWith(fontSize: elder ? 16 : 12),
            ),
          ),
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

  final TrackingView view;
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
    final int loggedThisMonth = view.daysInMonth(month);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                key: const Key('log-prev-month'),
                tooltip: 'Previous month',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.chevron_left, color: AppColors.gold),
                onPressed: onPrev,
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  key: const Key('log-month'),
                  textAlign: TextAlign.center,
                  style: AppText.titleMedium.copyWith(
                    fontSize: elder ? 24 : 18,
                  ),
                ),
              ),
              IconButton(
                key: const Key('log-next-month'),
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
                      day:
                          (r * 7 + c - lead + 1) >= 1 &&
                              (r * 7 + c - lead + 1) <= count
                          ? DateTime(
                              month.year,
                              month.month,
                              r * 7 + c - lead + 1,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            loggedThisMonth == 0
                ? 'Nothing logged in this month. That is fine.'
                : '$loggedThisMonth ${loggedThisMonth == 1 ? 'day' : 'days'} '
                      'logged in this month.',
            key: const Key('log-month-count'),
            style: AppText.bodyMuted.copyWith(fontSize: elder ? 16 : 14),
          ),
        ],
      ),
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

  final TrackingView view;
  final DateTime? day;
  final double height;
  final bool elder;

  @override
  Widget build(BuildContext context) {
    final DateTime? d = day;
    if (d == null) return SizedBox(height: height);
    final bool logged = view.isLogged(d);
    final bool today =
        TrackingMath.stamp(d) == TrackingMath.stamp(view.today);
    final bool future = d.isAfter(view.today);
    final double dot = height - 8;
    return Semantics(
      label:
          '${DateFormat('d MMMM').format(d)}${today ? ', today' : ''}'
          '${logged ? ', logged' : ''}',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Center(
          child: Container(
            key: Key('log-day-${TrackingMath.stamp(d)}'),
            width: dot,
            height: dot,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: logged ? AppColors.gold : Colors.transparent,
              border: today && !logged
                  ? Border.all(
                      color: AppColors.sand.withValues(alpha: 0.8),
                      width: 1,
                    )
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${d.day}',
                style: TextStyle(
                  fontSize: elder ? 18 : 14,
                  fontWeight: logged ? FontWeight.w700 : FontWeight.w400,
                  color: logged
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
