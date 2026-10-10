import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../auth/application/auth_providers.dart';
import '../../academy/application/academy_providers.dart';

/// Screen 11 · Menu (Full List) — built to the locked §6.11 spec:
/// three grouped lists (FAITH & WORSHIP · FAMILY & COMMUNITY ·
/// TOOLS & RESOURCES), Settings · Help & Support row, My Profile card.
/// Shipped module rows are wired; Marriage stays destination-less
/// (NOOR Connect deferred, §10); other rows inert until phased.
/// Log Out kept (auth flow necessity) below the locked content.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  static const List<(String, List<(IconData, String, String?)>)> _sections = [
    (
      'Faith & Worship',
      [
        (Icons.menu_book_outlined, 'Qur’an', AppRoutes.quran),
        (Icons.article_outlined, 'Hadith', AppRoutes.hadith),
        (Icons.wb_sunny_outlined, 'Dhikr & Du’a', AppRoutes.adhkar),
        (Icons.nights_stay_outlined, 'Prayer Times', AppRoutes.prayerTimes),
        (Icons.calendar_month_outlined, 'Islamic Calendar', AppRoutes.calendar),
        (Icons.explore_outlined, 'Qibla Finder', AppRoutes.qibla),
        (Icons.calculate_outlined, 'Zakat Calculator', AppRoutes.zakat),
        (Icons.school_outlined, 'Islamic Courses', AppRoutes.academy),
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
        (
          Icons.handshake_outlined,
          'Marriage',
          null,
        ), // NOOR Connect deferred (§10)
        (Icons.child_care_outlined, 'Parenting', '/academy/family'),
        (Icons.home_outlined, 'Family Life', AppRoutes.feelings),
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
        (Icons.search, 'Saved Searches', AppRoutes.quran),
        (Icons.dark_mode_outlined, 'Night Mode', AppRoutes.settings),
        (Icons.monitor_heart_outlined, 'Ar-Rayaan Doctor (founder)', '/founder'),
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
          children: [
            const ScreenHeader(title: 'Menu', close: true),
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
                            if (showAcademy || items[i].$3 != AppRoutes.academy)
                            if (i > 0 && (showAcademy || items[i].$3 != AppRoutes.academy))
                              Divider(
                                height: 1,
                                color: AppColors.gold.withValues(alpha: 0.1),
                                indent: 64,
                              ),
                            _MenuRow(
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
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.settings),
                            borderRadius: BorderRadius.circular(20),
                            child: const _MenuRow(
                              icon: Icons.settings_outlined,
                              label: 'Settings',
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.gold.withValues(alpha: 0.1),
                        ),
                        const Expanded(
                          child: _MenuRow(
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
                    child: const _MenuRow(
                      icon: Icons.auto_awesome,
                      label: 'My Profile',
                      subtitle: 'Your Journey, Your Progress',
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    strong: true,
                    onTap: () => context.go(AppRoutes.share),
                    child: const _MenuRow(
                      icon: Icons.qr_code_2,
                      label: 'Share Ar-Rayaan',
                      subtitle: 'Beta invite · QR code',
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: _MenuRow(
                      icon: Icons.logout,
                      label: 'Log Out',
                      destructive: true,
                      onTap: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();
                        if (context.mounted) context.go(AppRoutes.login);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'VERIFIED · AUTHENTIC · COMPASSIONATE',
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
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color color = destructive ? AppColors.destructive : AppColors.gold;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconTile(
                icon: icon,
                size: 32,
                color: destructive ? AppColors.destructive : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.body.copyWith(
                        color: destructive
                            ? AppColors.destructive
                            : AppColors.sand.withValues(alpha: 0.9),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppText.caption.copyWith(
                          color: AppColors.sand.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
              if (!destructive)
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: color.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
