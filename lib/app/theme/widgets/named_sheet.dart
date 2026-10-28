import 'package:flutter/material.dart';

import 'named_route.dart';

/// A bottom sheet whose spoken name is [label].
///
/// Flutter's own bottom sheet always announces itself as "Dialog" on the web
/// and cannot be renamed from inside. This opens the same kind of sheet
/// (bottom-aligned, dismissed by tapping outside or Back) as a dialog route,
/// which can carry a real name.
Future<T?> showNamedSheet<T>({
  required BuildContext context,
  required String label,
  required WidgetBuilder builder,
  Color? backgroundColor,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext ctx, Animation<double> a, Animation<double> b) {
      final double maxH = MediaQuery.sizeOf(ctx).height * 0.9;
      return NamedRoute(
        label: label,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH, maxWidth: 640),
              child: Material(
                color: backgroundColor ?? Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                clipBehavior: Clip.antiAlias,
                child: builder(ctx),
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
