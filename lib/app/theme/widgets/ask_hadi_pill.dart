import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter/material.dart' hide Text;
import 'tr_text.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../core/kids_mode.dart';
import '../../router.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import 'focus_safe_semantics.dart';

/// One tap to Hādi from a full-screen page.
///
/// The pill lives INSIDE the page it belongs to (see `_fade` in the router),
/// not above the whole app. That is what keeps it correct:
/// * it is underneath dialogs and bottom sheets, never on top of them;
/// * it is not drawn for the bottom-navigation tabs (the Hādi tab is right
///   there) or on the Hādi screen, so it can never be confused with a route
///   prefix such as `/hadith`;
/// * it hides while the keyboard is open;
/// * it slides out of the way while the person scrolls down and returns when
///   they scroll up or reach the top, so it does not sit over the text being
///   read;
/// * only the pill itself is tappable and exposed to screen readers (the
///   host adds no full-size hit area or semantics node);
/// * it never covers anything: the page is laid out ABOVE a thin strip
///   ([bandHeight]) that belongs to the pill, so the last row of a list, a
///   time, a bell or a link is never under it (it used to sit over the
///   Maghrib time and the Isha bell);
/// * at large text it shrinks to a round icon so it stays out of the way.
class AskHadiPillHost extends StatefulWidget {
  const AskHadiPillHost({required this.child, this.enabled, super.key});

  final Widget child;

  /// Overrides whether the pill is drawn. Default: release builds only
  /// (debug builds keep the screen free for developer tools).
  final bool? enabled;

  /// Lets tests draw the pill in the whole app, where it is off in debug.
  @visibleForTesting
  static bool? forceEnabled;

  /// The strip at the bottom of a page that is kept free for the pill.
  static const double bandHeight = 60;

  @override
  State<AskHadiPillHost> createState() => _AskHadiPillHostState();
}

class _AskHadiPillHostState extends State<AskHadiPillHost> {
  bool _hidden = false;

  void _setHidden(bool hide) {
    if (_hidden == hide || !mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // A scroll notification during layout: change state after the frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hidden = hide);
      });
      return;
    }
    setState(() => _hidden = hide);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification) {
      final double d = n.scrollDelta ?? 0;
      if (d > 2) {
        _setHidden(true);
      } else if (d < -2) {
        _setHidden(false);
      }
    }
    if (n.metrics.pixels <= n.metrics.minScrollExtent + 1) {
      _setHidden(false); // back at the top
    }
    return false; // never consume: other listeners still see it
  }

  @override
  Widget build(BuildContext context) {
    final bool on = widget.enabled ?? AskHadiPillHost.forceEnabled ?? !kDebugMode;
    if (!on) return widget.child;
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double band = keyboardOpen
        ? 0
        : AskHadiPillHost.bandHeight + safe.bottom;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: band),
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: !keyboardOpen,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.child,
            ),
          ),
        ),
        if (!keyboardOpen)
          Positioned.fill(
            // Not drawn while a child is in Kids Corner: Hadi is an AI
            // assistant for grown-ups (see kKidsMode).
            child: ValueListenableBuilder<bool>(
              valueListenable: kKidsMode,
              builder: (BuildContext c, bool kids, Widget? _) => kids
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: 12 + safe.right,
                          bottom: 8 + safe.bottom,
                        ),
                        child: ExcludeSemantics(
                          excluding: _hidden,
                          child: IgnorePointer(
                            ignoring: _hidden,
                            child: AnimatedOpacity(
                              opacity: _hidden ? 0 : 1,
                              duration: const Duration(milliseconds: 160),
                              child: const AskHadiPill(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

/// The pill itself. Sized by its content: nothing in it expands.
class AskHadiPill extends StatelessWidget {
  const AskHadiPill({super.key});

  static const String label = 'Ask Hādi';

  @override
  Widget build(BuildContext context) {
    void open() => context.go(AppRoutes.hadi);
    // At large text the words would make the pill tall and wide: a round
    // 48dp icon instead (the label stays for screen readers).
    final bool compact = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
    return FocusSafeSemantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: open,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF20A0F18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
          ],
        ),
        // MaterialType.transparency shrink-wraps its child; a default
        // Material would grow to fill the page.
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: open,
            borderRadius: BorderRadius.circular(24),
            child: compact
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 22,
                      color: AppColors.goldLight,
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.goldLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: AppText.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
