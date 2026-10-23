import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../app_colors.dart';
import '../app_typography.dart';

/// Shared screen header: round back (or close) button · Playfair title ·
/// round settings button — per the locked screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    super.key,
    this.close = false,
    this.showSettings = true,
  });

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
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppText.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (showSettings)
            _RoundButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onTap: () => context.push(AppRoutes.settings),
            )
          else
            const SizedBox(width: _RoundButton.hitSize),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  /// 44 logical px touch target around the 36 px visual circle.
  static const double hitSize = 44;

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
    );
  }
}
