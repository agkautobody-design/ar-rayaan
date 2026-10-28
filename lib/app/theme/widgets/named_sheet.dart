import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'named_route.dart';

/// A bottom sheet whose spoken name is [label].
///
/// Flutter's own bottom sheet always announces itself as "Dialog" on the web
/// and cannot be renamed from inside. This opens the same kind of sheet
/// (bottom-aligned, full width up to 640, dismissed by tapping outside, by
/// Back, or by Escape) as a dialog route, which can carry a real name and the
/// dialog role. It is a drop-in for `showModalBottomSheet`: the sheet content
/// is sized and padded by its own builder exactly as before.
///
/// [avoidKeyboard] lifts the sheet above the on-screen keyboard; leave it off
/// for a builder that already pads itself by the keyboard height.
/// [isScrollControlled] is accepted so call sites read the same; the sheet
/// can always grow to 90% of the screen.
Future<T?> showNamedSheet<T>({
  required BuildContext context,
  required String label,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = true,
  bool showDragHandle = false,
  bool useSafeArea = false,
  bool avoidKeyboard = false,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext ctx, Animation<double> a, Animation<double> b) {
      final Size screen = MediaQuery.sizeOf(ctx);
      final double maxH = screen.height * 0.9;
      final double width = math.min(screen.width, 640.0);
      final ThemeData theme = Theme.of(ctx);
      final Color fill = backgroundColor ??
          theme.bottomSheetTheme.backgroundColor ??
          theme.colorScheme.surface;
      Widget content = builder(ctx);
      if (showDragHandle) {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(child: content),
          ],
        );
      }
      if (useSafeArea) content = SafeArea(bottom: false, child: content);
      return NamedRoute(
        label: label,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: avoidKeyboard ? MediaQuery.viewInsetsOf(ctx).bottom : 0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: width,
                maxWidth: width,
                maxHeight: maxH,
              ),
              child: Material(
                color: fill,
                shape: shape ??
                    const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                clipBehavior: Clip.antiAlias,
                child: content,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (BuildContext ctx, Animation<double> a,
        Animation<double> b, Widget child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
        child: FadeTransition(opacity: a, child: child),
      );
    },
  );
}
