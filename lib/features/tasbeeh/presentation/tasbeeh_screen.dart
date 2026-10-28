import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/switch_row.dart';
import '../../habits/application/return_loop.dart';
import '../../tracking/application/tracking_providers.dart';
import '../application/tasbeeh_providers.dart';
import '../domain/tasbeeh_counter.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// A plain counter. The whole lower half of the screen is one big tap area.
/// On Android it can also count with the volume buttons while the screen is
/// off; elsewhere it can only keep the screen awake (a phone with its screen
/// off cannot receive taps, and iOS and web pages cannot read the buttons).
class TasbeehScreen extends ConsumerStatefulWidget {
  const TasbeehScreen({super.key});

  @override
  ConsumerState<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends ConsumerState<TasbeehScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _label;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(
      text: ref.read(tasbeehControllerProvider).counter.label,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _label.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(tasbeehControllerProvider.notifier).syncFromNative());
    }
  }

  void _onTap() {
    final bool reached = ref.read(tasbeehControllerProvider.notifier).tap();
    unawaited(_haptic(strong: reached));
    unawaited(noteTracking(ref, TrackingAct.dhikr));
  }

  /// A light tick on every tap, a heavier one when a round is complete.
  Future<void> _haptic({required bool strong}) async {
    try {
      if (strong) {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {
      // No haptics on this device or browser.
    }
  }

  Future<void> _confirmReset() async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        semanticLabel: 'Reset the counter?',
        title: const Text('Reset the counter?'),
        content: const Text(
          'The count and the rounds go back to zero. Your target stays.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      ref.read(tasbeehControllerProvider.notifier).reset();
    }
  }

  Future<void> _customTarget() async {
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext c) => _CustomTargetDialog(
        initial: ref.read(tasbeehControllerProvider).counter.target,
      ),
    );
    if (value != null && mounted) {
      ref.read(tasbeehControllerProvider.notifier).setTarget(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TasbeehViewState view = ref.watch(tasbeehControllerProvider);
    final TasbeehController ctl = ref.read(tasbeehControllerProvider.notifier);
    final bool android = ref.watch(volumeCounterChannelProvider).isSupported;
    final TasbeehState s = view.counter;
    final bool custom = !kTasbeehPresets.contains(s.target);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const ScreenHeader(title: 'Tasbeeh counter'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _label,
                      maxLength: kTasbeehMaxLabel,
                      textInputAction: TextInputAction.done,
                      style: AppText.body,
                      decoration: const InputDecoration(
                        labelText: 'Label (optional)',
                        counterText: '',
                      ),
                      onChanged: ctl.setLabel,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rounds completed: ${s.rounds}  ·  Total: ${s.total}',
                      style: AppText.body,
                    ),
                    const SizedBox(height: 12),
                    Text('TARGET', style: AppText.eyebrow),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final int p in kTasbeehPresets)
                          ChoiceChip(
                            label: Text('$p'),
                            selected: s.target == p,
                            onSelected: (_) => ctl.setTarget(p),
                          ),
                        ChoiceChip(
                          label: Text(custom ? 'Custom (${s.target})' : 'Custom'),
                          selected: custom,
                          onSelected: (_) => unawaited(_customTarget()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        TextButton.icon(
                          onPressed: s.total == 0 ? null : ctl.undo,
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Undo one'),
                        ),
                        TextButton.icon(
                          onPressed: s.total == 0
                              ? null
                              : () => unawaited(_confirmReset()),
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      blur: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: <Widget>[
                          if (android) ...<Widget>[
                            SwitchRow(
                              icon: Icons.volume_up_outlined,
                              title:
                                  'Count with volume buttons (works with screen off)',
                              subtitle:
                                  'Volume up adds one and volume down takes one away, '
                                  'even with the screen off; a small notification '
                                  'stays on while this is on.',
                              value: view.volumeMode,
                              onChanged: (bool v) =>
                                  unawaited(ctl.setVolumeMode(on: v)),
                            ),
                            Text(
                              'While this is on, the volume buttons count instead '
                              'of changing the volume. Some phone makers limit '
                              'this, so test it once with the screen off.',
                              style: AppText.bodyMuted.copyWith(fontSize: 12),
                            ),
                            Divider(
                              height: 20,
                              color: AppColors.gold.withValues(alpha: 0.1),
                            ),
                          ] else ...<Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Text(
                                'Screen off counting works on Android. '
                                'Here we can keep your screen awake instead',
                                style: AppText.bodyMuted.copyWith(fontSize: 13),
                              ),
                            ),
                            Divider(
                              height: 20,
                              color: AppColors.gold.withValues(alpha: 0.1),
                            ),
                          ],
                          SwitchRow(
                            icon: Icons.light_mode_outlined,
                            title: 'Keep screen on while counting',
                            subtitle: 'Stops the screen from turning off '
                                'while this page is open.',
                            value: view.keepAwake,
                            onChanged: (bool v) =>
                                unawaited(ctl.setKeepAwake(on: v)),
                          ),
                        ],
                      ),
                    ),
                    if (view.notice != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        view.notice!,
                        style: AppText.body.copyWith(
                          color: AppColors.destructive,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(child: _TapPad(state: s, onTap: _onTap)),
          ],
        ),
      ),
    );
  }
}

/// The lower half: one huge tap target showing the count.
class _TapPad extends StatelessWidget {
  const _TapPad({required this.state, required this.onTap});

  final TasbeehState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Semantics(
        button: true,
        label:
            'Tap to count. ${state.count} of ${state.target}, '
            '${state.rounds} rounds completed',
        excludeSemantics: true,
        child: Material(
          color: AppColors.gold.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: FocusRing(borderRadius: 12, child: InkWell(
            key: const ValueKey<String>('tasbeeh-tap-pad'),
            onTap: onTap,
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${state.count}',
                          key: const ValueKey<String>('tasbeeh-count'),
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 120,
                            height: 1.1,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                    Text('of ${state.target}', style: AppText.titleMedium),
                    const SizedBox(height: 8),
                    Text('Tap anywhere here to add one', style: AppText.bodyMuted),
                  ],
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}

class _CustomTargetDialog extends StatefulWidget {
  const _CustomTargetDialog({required this.initial});

  final int initial;

  @override
  State<_CustomTargetDialog> createState() => _CustomTargetDialogState();
}

class _CustomTargetDialogState extends State<_CustomTargetDialog> {
  late final TextEditingController _c = TextEditingController(
    text: kTasbeehPresets.contains(widget.initial) ? '' : '${widget.initial}',
  );
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final int? v = TasbeehLogic.parseTarget(_c.text);
    if (v == null) {
      setState(() {
        _error = 'Enter a whole number from 1 to $kTasbeehMaxTarget.';
      });
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      semanticLabel: 'Custom target',
      title: const Text('Custom target'),
      content: TextField(
        controller: _c,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          labelText: 'Number to count up to',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Set')),
      ],
    );
  }
}
