import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';
import 'focus_ring.dart';

/// Below this row width the decorative icons and chevrons of a list row are
/// dropped so the words keep the room (a very narrow window, a zoomed browser
/// or the largest text size must not break a label into one letter per line).
const double kTightRowWidth = 230;

/// A labelled on/off row: icon, title, subtitle, switch. Unlike
/// [SwitchListTile] its text column is a plain [Expanded], so it keeps whole
/// words at any width, and the icon steps aside when the row is very narrow.
/// The whole row is one tap target (48dp tall at least).
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;

  /// Null disables the row.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool>? change = onChanged;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final bool tight = box.maxWidth < kTightRowWidth;
        return MergeSemantics(
          child: FocusRing(
            child: InkWell(
            onTap: change == null ? null : () => change(!value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    if (!tight) ...<Widget>[
                      Icon(icon, size: 18, color: AppColors.gold),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: AppText.body.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppText.bodyMuted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      value: value,
                      activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
                      thumbColor: const WidgetStatePropertyAll<Color>(
                        AppColors.gold,
                      ),
                      onChanged: change,
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }
}
