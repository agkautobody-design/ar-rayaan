import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

/// Gives a dialog or bottom sheet a spoken name and the dialog role.
///
/// Flutter names a modal route "Dialog" (or nothing) unless something inside
/// it says otherwise, so a screen reader announced "Dialog" for the city
/// picker, the lesson-complete card and the Ask Wasia box. Wrap the sheet's
/// content in this and the route is announced by [label] when it opens, and
/// it is exposed to the browser as a dialog (role="dialog"), so a screen
/// reader says "dialog" together with the title.
class NamedRoute extends StatelessWidget {
  const NamedRoute({required this.label, required this.child, super.key});

  /// What a screen reader says when the sheet opens: its title.
  final String label;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      role: SemanticsRole.dialog,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: label,
      child: child,
    );
  }
}
