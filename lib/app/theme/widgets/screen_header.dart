import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/elder/application/elder_mode.dart';
import '../../router.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import 'focus_ring.dart';
import 'whole_word_text.dart';

/// Largest text scale the header title itself grows to.
const double kHeaderTitleMaxScale = 1.3;

/// Shared screen header: round back (or close) button · Playfair title ·
/// round settings button — per the locked screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    super.key,
    this.close = false,
    this.showSettings = true,
    this.actions = const <HeaderAction>[],
  });

  /// Extra round buttons on the right (for example the Qur'an reader's text
  /// size). They replace the Settings gear, so the title keeps its room.
  final List<HeaderAction> actions;

  final String title;

  /// Back / Close: pop when there is a screen underneath, otherwise go to the
  /// screen this one belongs to (a lesson's school, a story's library), and
  /// Home only for a screen that belongs nowhere.
  static void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    String target = AppRoutes.home;
    try {
      target = parentRouteOf(GoRouterState.of(context).uri.path);
    } catch (_) {
      // Not under a route (a bare test harness): Home.
    }
    // In Elder Mode "Home" is the Elder home, so Back never drops an elder
    // onto the busy normal Home.
    if (target == AppRoutes.home) {
      try {
        if (ProviderScope.containerOf(context).read(elderModeProvider)) {
          target = ElderMode.homeRoute;
        }
      } catch (_) {
        // No provider scope (a bare test harness): normal Home.
      }
    }
    context.go(target);
  }

  /// Shows an ✕ instead of ← (Explore / Menu panels).
  final bool close;

  /// The gear opens Settings. Screens that ARE settings pass false: the gear
  /// is then replaced by an empty slot so the title stays centred.
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _RoundButton(
            icon: close ? Icons.close : Icons.arrow_back,
            tooltip: close ? 'Close' : 'Back',
            onTap: () => _leave(context),
          ),
          Expanded(
            // The title sits between two fixed 44 px buttons, so at very
            // large text a single word is wider than its slot and would be
            // cut mid-word ("Settin / gs"). Its own scale stops at 1.3x
            // (the page below still scales fully), which keeps whole words.
            child: Semantics(
              header: true,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: kHeaderTitleMaxScale,
                // A word wider than the slot shrinks to fit instead of
                // breaking inside ("Praye / r Ti...").
                child: WholeWordText(
                  title,
                  style: AppText.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ),
          ),
          if (actions.isNotEmpty)
            for (final HeaderAction a in actions)
              _RoundButton(
                icon: a.icon,
                tooltip: a.tooltip,
                onTap: a.onTap,
                hitSize: 48,
              )
          else if (showSettings)
            _RoundButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onTap: () => context.open(AppRoutes.settings),
            )
          else
            const SizedBox(width: _RoundButton.defaultHitSize),
        ],
      ),
    );
  }
}

/// One extra round button of a [ScreenHeader].
class HeaderAction {
  const HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.hitSize = defaultHitSize,
  });

  /// 44 logical px touch target around the 36 px visual circle.
  static const double defaultHitSize = 44;

  /// The touch target actually used (48 for the extra header actions).
  final double hitSize;

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Material(
          type: MaterialType.transparency,
          // Same bright ring as every other control (the plain wash was
          // nearly invisible over the patterned background).
          child: FocusRing(
            borderRadius: hitSize / 2,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: hitSize,
                height: hitSize,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.glassFill,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: AppColors.sand.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
