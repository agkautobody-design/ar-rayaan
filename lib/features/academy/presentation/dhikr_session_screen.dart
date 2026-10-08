/// The Dhikr Session screen — the breathing-gold practice.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/sfx_provider.dart';
import '../domain/dhikr_session.dart';
import '../domain/sfx.dart';

class DhikrSessionScreen extends ConsumerStatefulWidget {
  const DhikrSessionScreen({super.key});

  @override
  ConsumerState<DhikrSessionScreen> createState() =>
      _DhikrSessionScreenState();
}

class _DhikrSessionScreenState
    extends ConsumerState<DhikrSessionScreen>
    with SingleTickerProviderStateMixin {
  DhikrSet _set = DhikrSet.classics.first;
  DhikrSessionState _state =
      DhikrSessionEngine.reset(DhikrSet.classics.first);
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await SfxPlayer.play(
        Sfx.tasbihTap, ref.read(soundSettingsProvider).tier);
    final DhikrSessionState next = DhikrSessionEngine.tap(_state);
    setState(() => _state = next);
    if (next.phase == DhikrPhase.milestonePause) {
      await SfxPlayer.play(
          Sfx.dhikrMilestone, ref.read(soundSettingsProvider).tier);
    }
    if (next.phase == DhikrPhase.complete) {
      await SfxPlayer.play(
          Sfx.dayComplete, ref.read(soundSettingsProvider).tier);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const ScreenHeader(title: 'The Dhikr Session'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final DhikrSet s in DhikrSet.classics)
                      ChoiceChip(
                        label: Text(s.meaning),
                        selected: _set.id == s.id,
                        onSelected: (_) => setState(() {
                          _set = s;
                          _state = DhikrSessionEngine.reset(s);
                        }),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              // The breathing gold — light that breathes with the session.
              AnimatedBuilder(
                animation: _breathe,
                builder: (context, _) {
                  final double glow = 0.35 + _breathe.value * 0.5;
                  return GestureDetector(
                    onTap: _state.phase == DhikrPhase.complete
                        ? null
                        : _tap,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            AppColors.gold.withValues(alpha: glow),
                            AppColors.gold.withValues(alpha: glow * 0.15),
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.gold.withValues(
                                alpha: glow * 0.5),
                            blurRadius: 60,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _state.phase == DhikrPhase.milestonePause
                                ? '…'
                                : '${_state.count}',
                            style: AppText.displayMedium.copyWith(
                              fontSize: 56,
                              color: const Color(0xFF0B1426),
                            ),
                          ),
                          Text(
                            '/ ${_set.target}',
                            style: AppText.caption
                                .copyWith(color: const Color(0xFF0B1426)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GlassCard(
                  strong: true,
                  child: Column(
                    children: <Widget>[
                      // Meaning first — always above the Arabic.
                      Text(_set.meaning,
                          style: AppText.titleMedium
                              .copyWith(color: AppColors.gold),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(_set.arabic,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 30,
                            color: AppColors.sand,
                          )),
                      const SizedBox(height: 10),
                      if (_state.phase == DhikrPhase.complete) ...[
                        Text(
                          'Completed, alhamdulillah. Sit in the silence a moment.',
                          style: AppText.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                      ] else if (_state.phase ==
                          DhikrPhase.milestonePause) ...[
                        Text(
                          'A third of the way. Breathe — then continue.',
                          style: AppText.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          'Tap the light with each remembrance.',
                          style: AppText.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _state.progress,
                          minHeight: 4,
                          backgroundColor:
                              AppColors.gold.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
