import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../academy/application/academy_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';

/// Screen 5 · Explore Ar-Rayaan — the full menu panel.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  static const List<(String, List<(IconData, String, String?)>)> _sections = [
    (
      'Faith & Worship',
      [
        (Icons.menu_book_outlined, 'Qur’an', AppRoutes.quran),
        (Icons.article_outlined, 'Hadith', AppRoutes.hadith),
        (Icons.auto_stories_outlined, 'Stories', AppRoutes.stories),
        (Icons.account_tree_outlined, 'The Messengers\u2019 Tree', AppRoutes.familyTree),
        (Icons.menu_book_outlined, 'Huda \u2014 Worship Guides', AppRoutes.huda),
        (Icons.sports_esports_outlined, 'Games', AppRoutes.games),
        (Icons.favorite_border, 'For Your Heart', AppRoutes.feelings),
        (Icons.forum_outlined, 'Majlis \u2014 The Courtyard', AppRoutes.majlis),
        (Icons.savings_outlined, 'Tayyib Finance \u00b7 zakat & halal investing', '/finance'),
        (Icons.mosque_outlined, 'Masajid \u00b7 mosques near you', '/masajid'),
        (Icons.ios_share_outlined, 'Verse Cards \u00b7 share the light', '/share'),
        (Icons.wb_sunny_outlined, 'Dhikr & Du’a', AppRoutes.adhkar),
        (Icons.nights_stay_outlined, 'Prayer Times', AppRoutes.prayerTimes),
        (Icons.calendar_month_outlined, 'Islamic Calendar', AppRoutes.calendar),
        (Icons.explore_outlined, 'Qibla Finder', AppRoutes.qibla),
        (Icons.calculate_outlined, 'Zakat Calculator', AppRoutes.zakat),
        (Icons.school_outlined, 'The Academy', AppRoutes.academyGate),
      ],
    ),
    (
      'Healing & Guidance',
      [
        (
          Icons.spa_outlined,
          'Sakina · Healing for the Heart',
          AppRoutes.sakina,
        ),
      ],
    ),
    (
      'Family & Community',
      [
        (Icons.handshake_outlined, 'Marriage', null),
        (Icons.child_care_outlined, 'Parenting', null),
        (Icons.home_outlined, 'Family Life', null),
        (Icons.people_outline, 'Community', AppRoutes.community),
        (Icons.favorite_outline, 'Elder Care', null),
      ],
    ),
    (
      'Tools & Resources',
      [
        (Icons.local_library_outlined, 'Library', null),
        (Icons.bookmark_outline, 'Notes & Bookmarks', null),
        (Icons.download_outlined, 'Downloads', null),
        (Icons.search, 'Saved Searches', null),
        (Icons.dark_mode_outlined, 'Night Mode', null),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kill switch: ar.flag.academy=false removes every Academy entry point.
    final bool showAcademy = ref.watch(academyFlagProvider).valueOrNull ?? true;
    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: '', close: true),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text('EXPLORE AR-RAYAAN', style: AppText.eyebrow),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  for (final (title, items) in _sections) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        top: 16,
                        bottom: 8,
                      ),
                      child: Text(title.toUpperCase(), style: AppText.eyebrow),
                    ),
                    GlassCard(
                      child: Column(
                        children: [
                          for (int i = 0; i < items.length; i++) ...[
                            if (showAcademy || items[i].$3 != AppRoutes.academyGate)
                            if (i > 0 && (showAcademy || items[i].$3 != AppRoutes.academyGate))
                              Divider(
                                height: 1,
                                color: AppColors.gold.withValues(alpha: 0.1),
                                indent: 64,
                              ),
                            _Row(
                              icon: items[i].$1,
                              label: items[i].$2,
                              onTap: items[i].$3 == null
                                  ? null
                                  : () => context.go(items[i].$3!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Row(
                      children: [
                        const Expanded(
                          child: _Row(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.gold.withValues(alpha: 0.1),
                        ),
                        const Expanded(
                          child: _Row(
                            icon: Icons.help_outline,
                            label: 'Help & Support',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    strong: true,
                    onTap: () => context.go(AppRoutes.journey),
                    child: const _Row(
                      icon: Icons.auto_awesome,
                      label: 'My Profile',
                      subtitle: 'Your Journey, Your Progress',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconTile(icon: icon, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.body.copyWith(
                        color: AppColors.sand.withValues(alpha: 0.9),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppText.bodyMuted.copyWith(fontSize: 10),
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
    );
  }
}
