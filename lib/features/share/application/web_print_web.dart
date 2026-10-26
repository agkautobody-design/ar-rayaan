import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

bool get webPrintSupported => true;

/// Opens [html] in a new tab and starts the browser's print dialog there, so
/// the page prints on real paper-sized pages (the Flutter canvas itself would
/// print only what is on screen). Returns false when the browser blocked the
/// new tab. Must be called straight from a tap.
bool printHtmlDocument(String html) {
  try {
    final JSObject win = web.window as JSObject;
    final JSAny? opened =
        win.callMethod('open'.toJS, ''.toJS, '_blank'.toJS);
    if (opened == null) return false;
    final JSObject popup = opened as JSObject;
    final JSObject doc = popup['document']! as JSObject;
    doc.callMethod('open'.toJS);
    doc.callMethod('write'.toJS, html.toJS);
    doc.callMethod('close'.toJS);
    popup.callMethod('focus'.toJS);
    popup.callMethod('print'.toJS);
    return true;
  } catch (_) {
    return false;
  }
}
