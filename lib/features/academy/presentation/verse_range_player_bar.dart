/// Verse-range player bar — the Recitation School's playback controls.
///
/// Thumb-zone glass bar (Simplicity Charter): play/pause, the selected
/// range, and one expandable row of bounded controls. Every value feeds
/// the TESTED [RecitationPlanEngine] — this widget holds no sequencing
/// logic of its own.
///
/// Wakelock lives HERE (UI layer), listening to the player state — the
/// legal Riverpod pattern the production provider cannot use.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../quran/presentation/reciter_picker.dart';
import '../application/recitation_player_provider.dart';
import '../domain/recitation_audio.dart';

class VerseRangePlayerBar extends ConsumerStatefulWidget {
  const VerseRangePlayerBar({
    super.key,
    required this.surah,
    required this.ayahCount,
    this.initialStartAyah = 1,
    int? initialEndAyah,
  }) : initialEndAyah = initialEndAyah ?? ayahCount;

  /// Surah whose ayat this bar ranges over (reader passes its current surah).
  final int surah;
  final int ayahCount;

  /// Selection set by the reader's two-tap ayah pick.
  final int initialStartAyah;
  final int initialEndAyah;

  @override
  ConsumerState<VerseRangePlayerBar> createState() =>
      _VerseRangePlayerBarState();
}

class _VerseRangePlayerBarState extends ConsumerState<VerseRangePlayerBar> {
  int _startAyah = 1;
  int _endAyah = 1;
  int _loopRange = 1;
  int _perAyahRepeat = 1;
  double _gapSeconds = 2.0;
  double _speed = 1.0;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _startAyah = widget.initialStartAyah.clamp(1, widget.ayahCount);
    _endAyah = widget.initialEndAyah.clamp(_startAyah, widget.ayahCount);
  }

  List<PlaybackEvent> _buildPlan() {
    final List<AyahRef> refs = AyahRange.withinSurah(
      surah: widget.surah,
      fromAyah: _startAyah,
      toAyah: _endAyah,
    ).refs;
    return RecitationPlanEngine.buildPlan(
      range: refs,
      perAyahRepeat: _perAyahRepeat,
      gapMs: (_gapSeconds * 1000).round(),
      loopRange: _loopRange,
    );
  }

  Future<void> _togglePlay() async {
    final notifier = ref.read(recitationPlayerProvider.notifier);
    final RecitationPlaybackState current = ref.read(recitationPlayerProvider);
    if (current.playing) {
      await notifier.pause();
      return;
    }
    // One engine serves the ayah buttons and this bar, so nothing else
    // can be playing: no cross-stop is needed (and one would reset a pause).
    await notifier.setSpeed(_speed);
    if (current.paused) {
      // Pause means pause: continue from the exact utterance.
      await notifier.resume();
    } else {
      await notifier.playPlan(_buildPlan());
    }
  }

  /// Apply a settings edit. If playback is paused the old plan no longer
  /// matches the controls, so it is dropped and the next press starts the
  /// new plan.
  void _edit(VoidCallback change) {
    setState(change);
    if (ref.read(recitationPlayerProvider).paused) {
      unawaited(ref.read(recitationPlayerProvider.notifier).stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screen stays awake while reciting (§4). Wrapped: platform channels
    // may be absent in tests/web-shims — wakelock is best-effort.
    ref.listen<RecitationPlaybackState>(recitationPlayerProvider, (_, next) {
      try {
        if (next.playing) {
          WakelockPlus.enable();
        } else {
          WakelockPlus.disable();
        }
      } catch (_) {}
    });

    final RecitationPlaybackState state =
        ref.watch(recitationPlayerProvider);
    final String reciter = ref.watch(selectedReciterProvider).displayName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassCard(
        strong: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Main row: play + range + expand -------------------------------
            Row(
              children: <Widget>[
                IconButton(
                  tooltip: state.playing ? 'Pause' : 'Play',
                  iconSize: 34,
                  color: AppColors.gold,
                  icon: Icon(
                    state.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  onPressed: _togglePlay,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$_startAyah – $_endAyah',
                        style: AppText.titleMedium
                            .copyWith(color: AppColors.gold),
                      ),
                      Text(
                        reciter,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Choose reciter',
                  icon: const Icon(Icons.record_voice_over_outlined,
                      color: AppColors.gold),
                  onPressed: () => showReciterPicker(context, ref),
                ),
                IconButton(
                  tooltip: _expanded ? 'Hide controls' : 'Show controls',
                  icon: Icon(
                    _expanded ? Icons.expand_more : Icons.tune,
                    color: AppColors.gold,
                  ),
                  onPressed: () =>
                      setState(() => _expanded = !_expanded),
                ),
              ],
            ),

            if (state.failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'This ayah\'s audio could not be loaded. Check your '
                  'connection and press play to try again.',
                  style: AppText.caption.copyWith(color: AppColors.gold),
                ),
              ),

            // Expanded controls ---------------------------------------------
            if (_expanded) ...<Widget>[
              const Divider(height: 1),
              const SizedBox(height: 8),
              _BoundedStepper(
                label: 'Range loop',
                value: _loopRange,
                min: 1,
                max: 10,
                onChanged: (v) => _edit(() => _loopRange = v),
              ),
              _BoundedStepper(
                label: 'Repeat each ayah',
                value: _perAyahRepeat,
                min: 1,
                max: 5,
                onChanged: (v) => _edit(() => _perAyahRepeat = v),
              ),
              _RangeRow(
                label: 'Pause between',
                value: '${_gapSeconds.toStringAsFixed(1)}s',
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.gold,
                    thumbColor: AppColors.gold,
                    inactiveTrackColor: AppColors.gold.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _gapSeconds,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    onChanged: (v) => _edit(() => _gapSeconds = v),
                  ),
                ),
              ),
              _RangeRow(
                label: 'Speed',
                value: '${_speed.toStringAsFixed(2)}×',
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.gold,
                    thumbColor: AppColors.gold,
                    inactiveTrackColor: AppColors.gold.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _speed,
                    min: 0.75,
                    max: 1.25,
                    divisions: 2,
                    onChanged: (v) {
                      setState(() => _speed = v);
                      unawaited(ref
                          .read(recitationPlayerProvider.notifier)
                          .setSpeed(v));
                    },
                  ),
                ),
              ),
              _RangeRow(
                label: 'From ayah',
                value: '$_startAyah',
                child: _ayahChips(
                  selected: _startAyah,
                  onSelect: (a) => _edit(() {
                    _startAyah = a.clamp(1, _endAyah);
                  }),
                ),
              ),
              _RangeRow(
                label: 'To ayah',
                value: '$_endAyah',
                child: _ayahChips(
                  selected: _endAyah,
                  onSelect: (a) => _edit(() {
                    _endAyah = a.clamp(_startAyah, widget.ayahCount);
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Compact ayah selector: stepper pair (Simplicity: ≤5 visible items).
  Widget _ayahChips({
    required int selected,
    required ValueChanged<int> onSelect,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: AppColors.gold, size: 20),
          onPressed: selected > 1 ? () => onSelect(selected - 1) : null,
        ),
        Text('$selected', style: AppText.body),
        IconButton(
          icon: const Icon(Icons.add_circle_outline,
              color: AppColors.gold, size: 20),
          onPressed:
              selected < widget.ayahCount ? () => onSelect(selected + 1) : null,
        ),
      ],
    );
  }
}

class _BoundedStepper extends StatelessWidget {
  const _BoundedStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: AppText.body)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.gold, size: 20),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text('$value', style: AppText.body.copyWith(color: AppColors.gold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.gold, size: 20),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({
    required this.label,
    required this.value,
    required this.child,
  });

  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label, style: AppText.body),
          ),
          Expanded(child: child),
          SizedBox(
            width: 52,
            child: Text(value,
                style: AppText.caption.copyWith(color: AppColors.gold),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
