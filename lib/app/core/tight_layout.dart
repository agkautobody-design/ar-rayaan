import 'package:flutter/widgets.dart';

/// True when the screen has little room: a very narrow window (a browser
/// zoomed to 200% is about 195 dp wide; a small phone at 320 is not), a very short one, or text scaled to
/// about 1.4x or more. Screens use it to fold decoration away so the content
/// people came for (a chat, the verses, the prayer times) gets the space.
bool isTightLayout(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  final double scale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return size.width < 260 || size.height < 520 || scale > 1.4;
}
