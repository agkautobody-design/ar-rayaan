import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/support/domain/quick_exit_signal.dart';
import '../router.dart';

/// Escape goes Back on any screen that was opened on top of another.
///
/// A keyboard-only reader could not leave a long surah: Back sits first in
/// the focus order, but every ayah adds three more buttons, so Tab or
/// Shift+Tab never got there. This listener sits above the whole app. A key
/// that a control, a text field or a dialog already handled never reaches it,
/// and it steps aside while a dialog or sheet is open (their own Escape
/// closes them) and while the person is typing.
class KeyboardBackScope extends StatelessWidget {
  const KeyboardBackScope({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        // A deliberate key press ends the guard a quick exit sets.
        if (event is KeyDownEvent) releaseQuickExitGuard();
        return handleEscapeBack(router, event)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Paths where Escape must do nothing: the tabs, the entry point and the
/// first-run and sign-in flows (they have no "behind" to return to).
bool _escapeStaysPut(String path) =>
    path == AppRoutes.splash ||
    path == AppRoutes.onboarding ||
    path.startsWith('/auth/') ||
    kShellTabPaths.contains(path);

/// True when Escape took the person Back (and so is used up).
bool handleEscapeBack(GoRouter router, KeyEvent event) {
  if (event is! KeyDownEvent) return false;
  if (event.logicalKey != LogicalKeyboardKey.escape) return false;
  final HardwareKeyboard kb = HardwareKeyboard.instance;
  if (kb.isControlPressed || kb.isAltPressed || kb.isMetaPressed) return false;

  try {
    // A dialog, sheet or menu is on top: Escape closes it, wherever keyboard
    // focus happens to be (focus can still be on the page underneath, or in
    // a text box inside the sheet). A dialog that cannot be dismissed by
    // tapping outside (a choice that must be made) is left alone.
    final NavigatorState? nav = router.routerDelegate.navigatorKey.currentState;
    if (nav != null) {
      Route<dynamic>? found;
      nav.popUntil((Route<dynamic> r) {
        found = r;
        return true;
      });
      final Route<dynamic>? top = found;
      if (top is PopupRoute<dynamic>) {
        if (!top.barrierDismissible) return false;
        unawaited(nav.maybePop());
        return true;
      }
    }

    // Typing: leave the field with Tab; Escape must not throw a draft away.
    final BuildContext? focusContext =
        FocusManager.instance.primaryFocus?.context;
    if (focusContext != null &&
        (focusContext.widget is EditableText ||
            focusContext.findAncestorWidgetOfExactType<EditableText>() !=
                null)) {
      return false;
    }

    if (router.canPop()) {
      router.pop();
      return true;
    }
    final String path = router.routerDelegate.currentConfiguration.uri.path;
    if (_escapeStaysPut(path)) return false;
    router.go(parentRouteOf(path));
    return true;
  } catch (_) {
    return false;
  }
}
