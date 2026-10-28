import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/i18n/app_locale.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/switch_row.dart' show kTightRowWidth;
import '../../../app/theme/widgets/whole_word_text.dart';
import '../../auth/application/auth_providers.dart';
import '../../academy/application/academy_providers.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// One menu row: icon, label, route. A null route means "not built yet": the
/// row is shown dimmed with a "Coming soon" caption instead of a dead tap.
typedef MenuEntry = (IconData, String, String?);

/// True when [route] belongs to the Academy (the `ar.flag.academy` switch).
bool isAcademyRoute(String? route) =>
    route != null && route.startsWith('/academy');

/// The rows of a section that stay visible. With the Academy kill switch off
/// every Academy entry point disappears - the row AND its divider, because the
/// divider is drawn per visible row, never per source row.
List<MenuEntry> visibleMenuEntries(
  List<MenuEntry> items, {
  required bool showAcademy,
}) =>
    <MenuEntry>[
      for (final MenuEntry e in items)
        if (showAcademy || !isAcademyRoute(e.$3)) e,
    ];

/// Screen 11 · Menu (Full List) — built to the locked §6.11 spec:
/// three grouped lists (FAITH & WORSHIP · FAMILY & COMMUNITY ·
/// TOOLS & RESOURCES), Settings · Help & Support row, My Profile card.
/// Shipped module rows are wired. Anything not built yet (Help & Support)
/// says "Coming soon" instead of looking tappable.
/// Log Out kept (auth flow necessity) below the locked content.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  static const List<(String, List<MenuEntry>)> _sections = [
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
        // One row: Marriage is the first unit of the Family Life school
        // (verified in family_school_screen.dart), so both words open it.
        // NOOR Connect matchmaking stays deferred.
        (Icons.handshake_outlined, 'Marriage & Family Life', '/academy/family-life'),
        // The Family Wing: add children, follow their lessons, ask Wasia.
        // It is the parents' space (behind the parent check), not parenting
        // advice, and the label says so.
        (Icons.child_care_outlined, 'Family Wing \u00b7 for parents', '/academy/family'),
        (Icons.people_outline, 'Community', AppRoutes.community),
        (Icons.favorite_outline, 'Elder Care', '/elder-care'),
      ],
    ),
    (
      'Tools & Resources',
      [
        (Icons.local_library_outlined, 'Library', AppRoutes.stories),
        (Icons.bookmark_outline, 'Notes & Bookmarks', AppRoutes.notes),
        (Icons.event_available_outlined, 'My log', AppRoutes.tracking),
        (Icons.download_outlined, 'Downloads', AppRoutes.downloads),
        (Icons.text_fields, 'Text size \u00b7 bigger words', AppRoutes.settings),
        (Icons.translate_outlined, 'Language & Voice \u00b7 your tongue, your choice', '/settings/language'),
        if (kFounderTools)
          (Icons.monitor_heart_outlined, 'Ar-Rayaan Doctor (founder)', '/founder'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kill switch: ar.flag.academy=false removes every Academy entry point.
    final bool showAcademy = ref.watch(academyFlagProvider).valueOrNull ?? true;
    final L10n l10n = ref.watch(l10nProvider);
    final bool signedIn = ref.watch(authStateProvider).valueOrNull != null;
    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(title: l10n.english('Menu'), close: true),
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
                      child: Text(l10n.english(title).toUpperCase(),
                          style: AppText.eyebrow),
                    ),
                    GlassCard(
                      child: Column(
                        children: [
                          for (final (int i, MenuEntry e) in visibleMenuEntries(
                            items,
                            showAcademy: showAcademy,
                          ).indexed) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: AppColors.gold.withValues(alpha: 0.1),
                                indent: 64,
                              ),
                            _MenuRow(
                              icon: e.$1,
                              label: l10n.english(e.$2),
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
                  // Help & Support is not built yet, so it is not listed: a
                  // row that goes nowhere is worse than no row.
                  GlassCard(
                    child: _MenuRow(
                      icon: Icons.settings_outlined,
                      label: l10n.ui('ui.settings'),
                      onTap: () => context.open(AppRoutes.settings),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Opens the Journey screen, so it says Journey (it used to say
                  // "My Profile", which is the You tab).
                  GlassCard(
                    strong: true,
                    onTap: () => context.open(AppRoutes.journey),
                    child: _MenuRow(
                      icon: Icons.auto_awesome,
                      label: l10n.ui('tile.journey'),
                      subtitle: 'Your Journey, Your Progress',
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    strong: true,
                    onTap: () => context.open(AppRoutes.share),
                    child: const _MenuRow(
                      icon: Icons.qr_code_2,
                      label: 'Share Ar-Rayaan',
                      subtitle: 'Invite a friend · verse cards · QR code',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // A guest has nothing to log out of: the row offers sign-in
                  // instead. Logging out asks first.
                  GlassCard(
                    child: signedIn
                        ? _MenuRow(
                            icon: Icons.logout,
                            label: l10n.ui('menu.logout'),
                            destructive: true,
                            onTap: () async {
                              final bool ok = await _confirmLogOut(context);
                              if (!ok || !context.mounted) return;
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signOut();
                              if (context.mounted) context.go(AppRoutes.login);
                            },
                          )
                        : _MenuRow(
                            icon: Icons.login,
                            label: l10n.ui('menu.signin'),
                            onTap: () => context.go(AppRoutes.login),
                          ),
                  ),
                  const SizedBox(height: 20),
                  // Says only what is true today: sources are shown, and no
                  // named scholar has reviewed the app yet.
                  Text(
                    'SOURCES SHOWN \u00b7 SCHOLAR REVIEW NEEDED',
                    style: AppText.eyebrow,
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

/// "Log out of this device?" - true to go ahead.
Future<bool> _confirmLogOut(BuildContext context) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      semanticLabel: 'Log out?',
      backgroundColor: const Color(0xFF0A0F18),
      title: Text('Log out?', style: AppText.titleMedium),
      content: Text(
        'You will be signed out on this device. Your progress, bookmarks '
        'and settings stay on it.',
        style: AppText.bodyMuted,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Stay signed in'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.destructive = false,
    this.comingSoon = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  /// Not built yet: the row reads "Coming soon", is dimmed, has no chevron and
  /// is announced as disabled, instead of looking tappable and doing nothing.
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final Color color = destructive ? AppColors.destructive : AppColors.gold;
    final bool soon = comingSoon;
    final String? caption = soon ? 'Coming soon' : subtitle;
    return Semantics(
      button: true,
      enabled: !soon,
      child: Material(
        type: MaterialType.transparency,
        child: FocusRing(borderRadius: 12, child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: soon ? 0.7 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  final bool tight = box.maxWidth < kTightRowWidth;
                  return Row(
                children: [
                  if (!tight)
                  ExcludeSemantics(
                    child: IconTile(
                      icon: icon,
                      size: 32,
                      color: destructive ? AppColors.destructive : null,
                    ),
                  ),
                  if (!tight) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WholeWordText(
                          label,
                          style: AppText.body.copyWith(
                            color: destructive
                                ? AppColors.destructive
                                : AppColors.sand.withValues(alpha: 0.9),
                          ),
                        ),
                        if (caption != null)
                          WholeWordText(
                            caption,
                            style: AppText.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!destructive && !soon && !tight)
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: color.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              );
                },
              ),
            ),
          ),
        )),
      ),
    );
  }
}
