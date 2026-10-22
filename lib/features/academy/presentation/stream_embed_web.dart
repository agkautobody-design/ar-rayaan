import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The browser can show the embedded player.
bool get streamEmbedSupported => true;

final Map<String, String> _viewTypes = <String, String>{};

/// An iframe for [src]. Only called with addresses built by [StreamLink].
Widget buildStreamEmbed({
  required Uri src,
  required String title,
  required double height,
}) {
  final String url = src.toString();
  final String viewType = _viewTypes.putIfAbsent(url, () {
    final String type = 'ar-stream-embed-${_viewTypes.length}';
    ui_web.platformViewRegistry.registerViewFactory(type, (int viewId) {
      final web.HTMLIFrameElement frame =
          web.document.createElement('iframe') as web.HTMLIFrameElement;
      frame.src = url;
      frame.title = title;
      frame.allow =
          'autoplay; encrypted-media; fullscreen; picture-in-picture';
      frame.allowFullscreen = true;
      frame.referrerPolicy = 'strict-origin-when-cross-origin';
      frame.style.setProperty('border', '0');
      frame.style.setProperty('width', '100%');
      frame.style.setProperty('height', '100%');
      return frame;
    });
    return type;
  });
  return SizedBox(
    height: height,
    child: HtmlElementView(key: ValueKey<String>(viewType), viewType: viewType),
  );
}
