import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_text.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

/// Screen 9 · Community — "Together in faith, stronger as one."
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static const List<(IconData, String, String)> _items = [
    (Icons.calendar_month_outlined, 'Events', 'Join upcoming events'),
    (Icons.people_outline, 'Groups', 'Connect with others'),
    (Icons.volunteer_activism_outlined, 'Volunteer', 'Make a difference'),
    (Icons.campaign_outlined, 'Announcements', 'Stay updated'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ScenicBackground.community(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const ScreenHeader(title: 'Community'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      // Tagline sits directly on the lantern scenery (locked board).
                      SizedBox(
                        height: 170,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Together in faith, ',
                                    style: AppText.titleMedium.copyWith(
                                      fontSize: 19,
                                    ),
                                  ),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: GoldText(
                                      'stronger as one.',
                                      style: AppText.titleMedium.copyWith(
                                        fontSize: 19,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final (icon, label, sub) in _items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            onTap: () {},
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                IconTile(icon: icon),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: AppText.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        sub,
                                        style: AppText.bodyMuted.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.gold.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'GUIDE. NEVER JUDGE.',
                        style: AppText.eyebrow.copyWith(
                          color: AppColors.gold.withValues(alpha: 0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
