import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/glass_card.dart';
import '../../../sakina/domain/crisis_detector.dart';
import '../../../sakina/presentation/widgets/need_help_button.dart';
import '../../../support/domain/checkin_scheduler.dart';
import '../../application/family_service.dart';
import '../../application/wasia_checkin.dart';
import 'parent_gate.dart';

/// Wasia's gentle check-in. It sits at the top of the child-facing Wasia
/// screens (Kids Corner, the Academy, a lesson) and is never put on a parent
/// screen. It shows only when it is due, once per interval, and never as a
/// notification. Its answer is not stored and no parent can read it.
class WasiaCheckinCard extends ConsumerStatefulWidget {
  const WasiaCheckinCard({super.key, this.register});

  /// Who is looking: `'adult'` on the Academy home when a grown-up is using
  /// the Adult or Parent track, `'13-17'` on the Teen track, or null for the
  /// active child's own band (Kids Corner and lessons).
  final String? register;

  @override
  ConsumerState<WasiaCheckinCard> createState() => _WasiaCheckinCardState();
}

class _WasiaCheckinCardState extends ConsumerState<WasiaCheckinCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bool parentOpen = ref.read(parentGateProvider.notifier).isOpen();
      final WasiaCheckinNotifier n = ref.read(wasiaCheckinProvider.notifier);
      // A card written for a grown-up never stays up for a child, or the
      // other way round (the track was switched).
      final WasiaCheckinState cur = ref.read(wasiaCheckinProvider);
      if ((cur.line != null || cur.reply != null) &&
          cur.adult != (widget.register == 'adult')) {
        n.reset();
      }
      n.maybeShow(parentOpen: parentOpen, register: widget.register);
    });
  }

  @override
  Widget build(BuildContext context) {
    // A different child: the card from the last one goes away.
    ref.listen(activeChildProvider, (_, __) {
      ref.read(wasiaCheckinProvider.notifier).reset();
    });
    final WasiaCheckinState s = ref.watch(wasiaCheckinProvider);
    final WasiaCheckinNotifier n = ref.read(wasiaCheckinProvider.notifier);
    if (s.line == null && s.reply == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        key: const Key('wasia-checkin-card'),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          if (s.line != null) ...<Widget>[
            Text(s.line!, style: AppText.body.copyWith(fontSize: 14, height: 1.5)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
              for (final (String key, String label, CheckinAnswer a) in <(String, String, CheckinAnswer)>[
                ('wasia-checkin-okay', 'I’m okay', CheckinAnswer.okay),
                ('wasia-checkin-hard', 'It’s been hard', CheckinAnswer.hard),
                ('wasia-checkin-rather', 'I’d rather not say', CheckinAnswer.rather),
              ])
                OutlinedButton(
                  key: Key(key),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => n.answer(a),
                  child: Text(label),
                ),
              TextButton(
                key: const Key('wasia-checkin-stop'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: n.stop,
                child: Text('Don’t ask me again',
                    style: AppText.caption.copyWith(fontSize: 12, decoration: TextDecoration.underline)),
              ),
            ]),
          ] else ...<Widget>[
            Text(s.reply!, key: const Key('wasia-checkin-reply'), style: AppText.body.copyWith(fontSize: 14, height: 1.5)),
            if (s.hard) ...<Widget>[
              const SizedBox(height: 8),
              // An adult is shown the adult lines; a child the child lines.
              NeedHelpNowButton(
                key: const Key('wasia-checkin-help'),
                kind: s.adult ? CrisisKind.selfHarm : CrisisKind.childSafety,
                label: 'Show help lines',
                showSakinaLink: s.adult,
                forChild: !s.adult,
              ),
            ],
            const SizedBox(height: 6),
            TextButton(
              onPressed: n.reset,
              child: Text('Close', style: AppText.caption.copyWith(color: AppColors.goldLight)),
            ),
          ],
        ]),
      ),
    );
  }
}
