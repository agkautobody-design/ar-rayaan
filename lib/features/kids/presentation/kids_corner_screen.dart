import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../academy/application/academy_providers.dart';

/// One door of the children's corner.
class KidsDoor {
  const KidsDoor({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    this.isAcademy = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;

  /// Academy doors disappear with the Academy kill switch.
  final bool isAcademy;
}

/// The three doors. Every one is a screen that already exists.
const List<KidsDoor> kKidsDoors = <KidsDoor>[
  KidsDoor(
    id: 'letters',
    title: 'Arabic letters',
    subtitle: 'Learn the letters, one at a time',
    route: '/academy/letters',
    icon: Icons.abc,
    isAcademy: true,
  ),
  KidsDoor(
    id: 'games',
    title: 'Games',
    subtitle: 'Play and learn',
    route: AppRoutes.games,
    icon: Icons.sports_esports_outlined,
  ),
  KidsDoor(
    id: 'stories',
    title: 'Stories school',
    subtitle: 'Stories with a lesson to talk about',
    route: '/academy/stories',
    icon: Icons.auto_stories_outlined,
    isAcademy: true,
  ),
];

/// The doors to show: all of them, or without the Academy ones when the
/// Academy is switched off.
List<KidsDoor> kidsDoorsFor({required bool showAcademy}) => <KidsDoor>[
      for (final KidsDoor d in kKidsDoors)
        if (showAcademy || !d.isAcademy) d,
    ];

/// /kids — a small, calm page for children with three big buttons. A grown-up
/// can sit alongside; nothing here asks for a name or an account.
class KidsCornerScreen extends ConsumerWidget {
  const KidsCornerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showAcademy = ref.watch(academyFlagProvider).valueOrNull ?? true;
    final List<KidsDoor> doors = kidsDoorsFor(showAcademy: showAcademy);
    return ScenicScaffold.pattern(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: <Widget>[
            const ScreenHeader(title: 'For Children'),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
              child: Text(
                'Pick one. A grown-up can sit with you.',
                style: AppText.body.copyWith(fontSize: 18, height: 1.4),
              ),
            ),
            for (final KidsDoor d in doors)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassCard(
                  strong: true,
                  semanticsLabel: '${d.title}. ${d.subtitle}',
                  onTap: () => context.open(d.route),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(d.icon, size: 44, color: AppColors.goldLight),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              d.title,
                              key: Key('kids-${d.id}'),
                              style: AppText.titleMedium.copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.subtitle,
                              style: AppText.bodyMuted.copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.gold.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
