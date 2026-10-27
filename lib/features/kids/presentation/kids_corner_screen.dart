import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/child_mode.dart';
import '../../../app/core/kids_mode.dart';
import '../../../app/core/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../academy/application/academy_providers.dart';
import '../../academy/presentation/widgets/parent_gate.dart';
import '../../sakina/domain/crisis_detector.dart';
import '../../sakina/presentation/widgets/need_help_button.dart';

/// One door of the children's corner.
class KidsDoor {
  const KidsDoor({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    this.isAcademy = false,
    this.needsParent = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;

  /// Academy doors disappear with the Academy kill switch.
  final bool isAcademy;

  /// The door leads out of Kids Corner into the whole app (with its menus,
  /// Settings and Hadi), so a grown-up opens it: the parent check comes first.
  final bool needsParent;
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
    subtitle: 'Play and learn. A grown-up opens this door.',
    route: AppRoutes.games,
    icon: Icons.sports_esports_outlined,
    needsParent: true,
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
///
/// In child mode the doors that lead out of Kids Corner (Games) are left out:
/// a child on a handed-over device only has what is for children.
List<KidsDoor> kidsDoorsFor({
  required bool showAcademy,
  bool childMode = false,
}) =>
    <KidsDoor>[
      for (final KidsDoor d in kKidsDoors)
        if ((showAcademy || !d.isAcademy) && !(childMode && d.needsParent)) d,
    ];

/// A parent hands the device to a child: the PIN check (the first time it
/// asks the parent to choose a PIN), then child mode on, the parent gate shut,
/// and Kids Corner.
Future<void> startChildMode(BuildContext context, WidgetRef ref) async {
  if (!await requireParent(context, ref)) return;
  if (!context.mounted) return;
  final prefs = ref.read(sharedPreferencesProvider);
  ref.read(parentGateProvider.notifier).lock();
  await setChildMode(prefs, true);
  if (!context.mounted) return;
  context.go(AppRoutes.kids);
}

/// /kids — a small, calm page for children with three big buttons. A grown-up
/// can sit alongside; nothing here asks for a name or an account.
///
/// While it is open the app is in kids mode ([kKidsMode]): no Settings gear
/// and no Ask Hadi pill on this page or the lessons it opens. Leaving needs
/// the parent check, the same one as the Family Wing.
class KidsCornerScreen extends ConsumerStatefulWidget {
  const KidsCornerScreen({super.key});

  @override
  ConsumerState<KidsCornerScreen> createState() => _KidsCornerScreenState();
}

class _KidsCornerScreenState extends ConsumerState<KidsCornerScreen> {
  /// How many Kids Corner pages are on screen (normally one).
  static int _open = 0;

  @override
  void initState() {
    super.initState();
    _open++;
    // After the first frame: switching it on rebuilds listeners elsewhere.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      kKidsMode.value = true;
      // Arriving in Kids Corner closes the parent gate.
      ref.read(parentGateProvider.notifier).lock();
    });
  }

  @override
  void dispose() {
    _open--;
    // Not during the teardown of the tree: listeners would rebuild too early.
    // In child mode the kids look stays on for the whole app.
    scheduleMicrotask(() {
      if (_open <= 0 && !kChildMode.value) kKidsMode.value = false;
    });
    super.dispose();
  }

  /// Back / Close: only after the parent check.
  Future<void> _leave() async {
    if (!await requireParent(context, ref)) return;
    if (!mounted) return;
    // Leaving also ends child mode (the PIN was the way out).
    if (kChildMode.value) {
      await setChildMode(ref.read(sharedPreferencesProvider), false);
    }
    kKidsMode.value = false;
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _openDoor(KidsDoor d) async {
    if (d.needsParent) {
      if (!await requireParent(context, ref)) return;
      if (!mounted) return;
      kKidsMode.value = false;
    }
    if (!mounted) return;
    context.open(d.route);
  }

  @override
  Widget build(BuildContext context) {
    final bool showAcademy = ref.watch(academyFlagProvider).valueOrNull ?? true;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) unawaited(_leave());
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: kChildMode,
        builder: (BuildContext context, bool childMode, Widget? _) => _body(
          kidsDoorsFor(showAcademy: showAcademy, childMode: childMode),
          childMode,
        ),
      ),
    );
  }

  Widget _body(List<KidsDoor> doors, bool childMode) {
    return ScenicScaffold.pattern(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: <Widget>[
            ScreenHeader(
              title: 'For Children',
              showSettings: false,
              onBack: () => unawaited(_leave()),
            ),
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
                  onTap: () => unawaited(_openDoor(d)),
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
            // Always there: a child who is scared or hurt can find real help
            // lines here without Sakina, which child mode closes.
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: NeedHelpNowButton(
                  key: Key('kids-need-help'),
                  kind: CrisisKind.childSafety,
                  label: 'Need to talk to someone?',
                  showSakinaLink: false,
                ),
              ),
            ),
            if (!childMode) _childModeCard(),
          ],
        ),
      ),
    );
  }

  /// For a parent: turn the whole app into a children's app on this device.
  Widget _childModeCard() {
    return GlassCard(
      semanticsLabel: 'Child mode. For a parent. Hands this device to a child '
          'and hides the rest of the app until you enter your PIN.',
      onTap: () => unawaited(startChildMode(context, ref)),
      child: Row(
        children: <Widget>[
          const Icon(Icons.lock_outline, color: AppColors.goldLight),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'For a parent: child mode',
                  key: const Key('kids-child-mode'),
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hand over the device. Only Kids Corner stays: no menus, '
                  'Settings, Ask Hadi, marriage, finance or community. Your '
                  'PIN turns it off.',
                  style: AppText.bodyMuted.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
