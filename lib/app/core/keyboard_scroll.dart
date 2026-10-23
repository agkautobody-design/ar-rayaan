import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Makes Space, Page Up, Page Down, Home and End scroll the screen you are
/// on, even when keyboard focus is not inside the list.
///
/// Flutter scrolls with these keys only when the focused control sits inside
/// the scrolling list. On a screen whose focus is on a header button, or on
/// nothing, they did nothing, so reading a long surah by keyboard meant
/// pressing Tab dozens of times. This listener sits above the whole app. A
/// key that a control or a list already handled never reaches it.
class KeyboardScrollScope extends StatelessWidget {
  const KeyboardScrollScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: (FocusNode node, KeyEvent event) => handleKeyboardScroll(event)
          ? KeyEventResult.handled
          : KeyEventResult.ignored,
      child: child,
    );
  }
}

/// True when the key scrolled the screen (and so is used up).
bool handleKeyboardScroll(KeyEvent event) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
  final HardwareKeyboard kb = HardwareKeyboard.instance;
  if (kb.isControlPressed || kb.isAltPressed || kb.isMetaPressed) return false;

  final LogicalKeyboardKey key = event.logicalKey;
  final bool isSpace = key == LogicalKeyboardKey.space;
  if (!isSpace &&
      key != LogicalKeyboardKey.pageDown &&
      key != LogicalKeyboardKey.pageUp &&
      key != LogicalKeyboardKey.home &&
      key != LogicalKeyboardKey.end) {
    return false;
  }

  final FocusNode? focus = FocusManager.instance.primaryFocus;
  final BuildContext? focusContext = focus?.context;
  if (focus == null || focusContext == null) return false;
  // Typing: Space, Home and End belong to the text field.
  if (focusContext.widget is EditableText ||
      focusContext.findAncestorWidgetOfExactType<EditableText>() != null) {
    return false;
  }
  // Space on a focused control activates it; only a screen with nothing
  // focused (or only its own scope focused) scrolls on Space.
  if (isSpace && focus is! FocusScopeNode) return false;
  // Focus already inside a list: Flutter's own handling scrolls that list.
  if (Scrollable.maybeOf(focusContext) != null) return false;

  final BuildContext? scope = focus.nearestScope?.context;
  if (scope == null) return false;
  final ScrollPosition? position = _mainPosition(scope);
  if (position == null) return false;

  final double page = position.viewportDimension * 0.875;
  double target;
  if (key == LogicalKeyboardKey.home) {
    target = position.minScrollExtent;
  } else if (key == LogicalKeyboardKey.end) {
    target = position.maxScrollExtent;
  } else if (key == LogicalKeyboardKey.pageUp || (isSpace && kb.isShiftPressed)) {
    target = position.pixels - page;
  } else {
    target = position.pixels + page;
  }
  target = target
      .clamp(position.minScrollExtent, position.maxScrollExtent)
      .toDouble();
  if (target == position.pixels) return true;
  unawaited(
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    ),
  );
  return true;
}

/// The screen's main vertical list: the tallest one that has room to scroll,
/// skipping pages hidden behind the visible one.
ScrollPosition? _mainPosition(BuildContext scope) {
  ScrollPosition? best;
  double bestSize = 0;
  void visit(Element element) {
    final Widget widget = element.widget;
    if (widget is Offstage && widget.offstage) return;
    if (element is StatefulElement && element.state is ScrollableState) {
      try {
        final ScrollPosition p = (element.state as ScrollableState).position;
        if (p.axis == Axis.vertical &&
            p.hasContentDimensions &&
            p.maxScrollExtent > p.minScrollExtent &&
            p.viewportDimension > bestSize) {
          best = p;
          bestSize = p.viewportDimension;
        }
      } catch (_) {
        // A list that is not attached yet.
      }
    }
    element.visitChildren(visit);
  }

  scope.visitChildElements(visit);
  return best;
}
