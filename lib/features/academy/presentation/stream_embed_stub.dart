import 'package:flutter/widgets.dart';

/// No embedded player outside the web build.
bool get streamEmbedSupported => false;

Widget buildStreamEmbed({
  required Uri src,
  required String title,
  required double height,
}) =>
    const SizedBox.shrink();
