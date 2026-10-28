import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Quick exit on the web: the entry the person is standing on (a support
/// screen, a conversation) is overwritten with Home, so the browser's Back
/// button does not return to it. The browser gives a page no way to delete
/// the entries from earlier visits; those stay, and the Help pages say so.
void replaceHistoryEntryWithHome() {
  try {
    final JSObject history = web.window.history as JSObject;
    final web.Location loc = web.window.location;
    final String url = '${loc.pathname}${loc.search}#/home';
    final JSAny? state = history['state'];
    history.callMethod('replaceState'.toJS, state, ''.toJS, url.toJS);
  } catch (_) {}
}
