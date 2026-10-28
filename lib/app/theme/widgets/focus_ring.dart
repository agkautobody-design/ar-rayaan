import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

/// The ring drawn around a control that has keyboard focus: 3px, bright gold,
/// impossible to miss on the dark background.
const double kFocusRingWidth = 3;

BoxDecoration focusRingDecoration(double radius) => BoxDecoration(
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppColors.goldLight, width: kFocusRingWidth),
);

/// Draws the focus ring around [child] while anything inside it has keyboard
/// focus. Wrap a material control that already takes focus (an InkWell, a
/// button). The ring is drawn over the child and takes no space.
class FocusRing extends StatefulWidget {
  const FocusRing({required this.child, this.borderRadius = 12, super.key});

  final Widget child;
  final double borderRadius;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _on = false;

  void _change(bool focused) {
    // Only for keyboard use; a mouse click must not leave a ring behind.
    final bool show =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (show != _on && mounted) setState(() => _on = show);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: _change,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: _on
            ? focusRingDecoration(widget.borderRadius)
            : BoxDecoration(borderRadius: BorderRadius.circular(widget.borderRadius)),
        child: widget.child,
      ),
    );
  }
}

/// A tappable region that the keyboard can reach: Tab focuses it, Enter or
/// Space activates it, and a gold ring shows where focus is. Use it where a
/// plain GestureDetector would be invisible to a keyboard.
class FocusableTap extends StatefulWidget {
  const FocusableTap({
    required this.onTap,
    required this.child,
    this.borderRadius = 14,
    this.behavior = HitTestBehavior.opaque,
    this.autofocus = false,
    super.key,
  });

  /// Takes keyboard focus when the screen opens, so Enter or Space works at
  /// once without a first Tab. Use only where this is the one thing to do.
  final bool autofocus;

  /// Null makes the region inert (nothing to activate, no hand cursor).
  final VoidCallback? onTap;
  final Widget child;
  final double borderRadius;
  final HitTestBehavior behavior;

  @override
  State<FocusableTap> createState() => _FocusableTapState();
}

class _FocusableTapState extends State<FocusableTap> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: widget.autofocus,
      enabled: widget.onTap != null,
      mouseCursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onShowFocusHighlight: (bool v) {
        if (v != _focused && mounted) setState(() => _focused = v);
      },
      // Enter as well as Space: on the web Flutter's defaults activate on
      // Space only, so a keyboard user's Enter did nothing.
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent _) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: _focused
              ? focusRingDecoration(widget.borderRadius)
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
          child: widget.child,
        ),
      ),
    );
  }
}
