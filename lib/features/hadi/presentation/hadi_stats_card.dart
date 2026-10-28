import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../application/hadi_stats.dart';

/// Founder-only view of how Hādi's replies were made on this device:
/// built-in library vs hosted AI. Counters only; no question text; nothing
/// leaves the device.
class HadiStatsCard extends ConsumerStatefulWidget {
  const HadiStatsCard({super.key});

  @override
  ConsumerState<HadiStatsCard> createState() => _HadiStatsCardState();
}

class _HadiStatsCardState extends ConsumerState<HadiStatsCard> {
  @override
  Widget build(BuildContext context) {
    final HadiStats stats = ref.watch(hadiStatsProvider);
    final double? share = stats.localShare;
    final String headline = share == null
        ? 'Hādi replies: none yet on this device'
        : 'Hādi answered ${(share * 100).round()}% without a hosted call '
            '(${stats.total} replies)';
    return GlassCard(
      key: const Key('hadi-stats-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(headline,
              style: AppText.body.copyWith(color: AppColors.gold)),
          const SizedBox(height: 6),
          for (final HadiAnswerKind k in HadiAnswerKind.values)
            Text('${k.name}: ${stats.count(k)}', style: AppText.caption),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () async {
              await stats.reset();
              if (mounted) setState(() {});
            },
            child: const Text('Reset counters'),
          ),
        ],
      ),
    );
  }
}
