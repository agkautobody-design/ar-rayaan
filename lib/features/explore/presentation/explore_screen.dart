import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/modules/module_status.dart';
import '../../../app/router.dart';
import '../../menu/presentation/menu_screen.dart'
    show MenuEntry, visibleMenuEntries;
import '../../academy/application/academy_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/switch_row.dart' show kTightRowWidth;

/// Screen 5 · Explore Ar-Rayaan — the full menu panel.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  static const List<(String, List<MenuEntry>)> _sections = [
    (
      'Faith & Worship',
      [
        // The things a first-time visitor looks for come first.
        (Icons.touch_app_outlined, 'Tasbeeh counter', AppRoutes.tasbeeh),
        (Icons.nights_stay_outlined, 'Prayer Times', AppRoutes.prayerTimes),
        (Icons.explore_outlined, 'Qibla \u00b7 which way to pray', AppRoutes.qibla),
        (
          Icons.self_improvement_outlined,
          'How to Pray \u00b7 step by step',
          '${AppRoutes.hudaGuide}?id=huda-prayer',
        ),
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
        (
          Icons.calendar_month_outlined,
          'Islamic Calendar \u00b7 Hijri date & Ramadan',
          AppRoutes.calendar,
        ),
        (Icons.spa_outlined, 'The 99 Names of Allah', AppRoutes.names99),
        (Icons.calculate_outlined, 'Zakat Calculator', AppRoutes.zakat),
        (Icons.school_outlined, 'The Academy', AppRoutes.academyGate),
        (Icons.nightlight_round, 'Ramadan Mode \u00b7 the season, complete', '/ramadan'),
        (Icons.translate_outlined, 'Language & Voice \u00b7 your tongue, your choice', '/settings/language'),
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
        // Same targets as the Menu (verified: Family Life school opens with
        // the Marriage unit; the Family Wing is the parents' space).
        (Icons.handshake_outlined, 'Marriage', '/academy/family-life'),
        (Icons.child_care_outlined, 'Parenting', '/academy/family'),
        (Icons.home_outlined, 'Family Life', '/academy/family-life'),
        (Icons.people_outline, 'Community', AppRoutes.community),
        (Icons.favorite_outline, 'Elder Care', '/elder-care'),
      ],
    ),
    (
      'Tools & Resources',
      [
        (Icons.local_library_outlined, 'Library', AppRoutes.stories),
        (Icons.bookmark_outline, 'Notes & Bookmarks', AppRoutes.notes),
        (Icons.download_outlined, 'Downloads', AppRoutes.downloads),
        (Icons.search, 'Search', AppRoutes.search),
        // The app is dark-only today; a light theme is not built.
        (Icons.light_mode_outlined, 'Light Theme', null),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kill switch: ar.flag.academy=false removes every Academy entry point.
    final bool showAcademy = ref.watch(academyFlagProvider).valueOrNull ?? true;
    // The Courtyard is an open forum with no moderation yet. The module
    // registry says 'gated', so the entry point stays hidden until it is live.
    final bool showMajlis =
        ref.watch(moduleRegistryProvider).valueOrNull?.isLive('majlis') ?? false;
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
                          for (final (int i, MenuEntry e) in visibleMenuEntries(
                            items,
                            showAcademy: showAcademy,
                          ).where((MenuEntry e) => showMajlis || e.$3 != AppRoutes.majlis).toList().indexed) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: AppColors.gold.withValues(alpha: 0.1),
                                indent: 64,
                              ),
                            _Row(
                              icon: e.$1,
                              label: e.$2,
                              comingSoon: e.$3 == null,
                              onTap: e.$3 == null
                                  ? null
                                  : () => context.open(e.$3!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GlassCard(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints box) {
                        // Side by side only when each half has room for a
                        // whole word; large text or a narrow phone stacks.
                        final bool stack =
                            box.maxWidth < 380 ||
                            MediaQuery.textScalerOf(context).scale(14) > 17;
                        final Widget settingsRow = _Row(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () => context.push(AppRoutes.settings),
                        );
                        final Widget helpRow = const _Row(
                          icon: Icons.help_outline,
                          label: 'Help & Support',
                          comingSoon: true,
                        );
                        if (stack) {
                          return Column(
                            children: [
                              settingsRow,
                              Divider(
                                height: 1,
                                color: AppColors.gold.withValues(alpha: 0.1),
                              ),
                              helpRow,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: settingsRow),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.gold.withValues(alpha: 0.1),
                            ),
                            Expanded(child: helpRow),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    strong: true,
                    onTap: () => context.open(AppRoutes.journey),
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
    this.comingSoon = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Not built yet: dimmed, "Coming soon", no chevron, announced as disabled.
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final String? caption = comingSoon ? 'Coming soon' : subtitle;
    return Semantics(
      button: true,
      enabled: !comingSoon,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: comingSoon ? 0.7 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  final bool tight = box.maxWidth < kTightRowWidth;
                  return Row(
                children: [
                  if (!tight)
                  ExcludeSemantics(child: IconTile(icon: icon, size: 32)),
                  if (!tight) const SizedBox(width: 12),
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
                        if (caption != null)
                          Text(caption, style: AppText.bodyMuted),
                      ],
                    ),
                  ),
                  if (!comingSoon && !tight)
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.gold.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
