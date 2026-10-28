import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Quick exit on the web: the entry the person is standing on (a support
/// screen, a conversation) is overwritten with Home, so the browser's Back
/// button does not return to it.
///
/// Two things are replaced, not one. The address is set to Home. And the
/// entry's saved router state is cleared: the router keeps the screen it was
/// showing inside the browser's history entry, and on Back it restored that
/// screen from the saved state even when the address said Home (so Back
/// "returned to Sakina" although the address had been overwritten). The
/// entry keeps only the counter the Flutter engine needs to follow history.
///
/// Limits, stated honestly in Settings and on the Help pages: the browser
/// gives a page no way to delete the entries from earlier visits, so the
/// screens visited BEFORE the quiet one stay in the history (Back from Home
/// can still reach the page the person came from, such as the Menu), and the
/// address bar of a tab left open still shows what it showed. Closing the
/// tab or window is the only complete exit.
void replaceHistoryEntryWithHome() {
  try {
    final JSObject history = web.window.history as JSObject;
    final web.Location loc = web.window.location;
    final String url = '${loc.pathname}${loc.search}#/home';
    final JSAny? old = history['state'];
    JSAny? clean;
    try {
      if (old != null && old.isA<JSObject>()) {
        final JSAny? count = (old as JSObject)['serialCount'];
        if (count != null) {
          final JSObject fresh = JSObject();
          fresh['serialCount'] = count;
          fresh['state'] = null;
          clean = fresh;
        }
      }
    } catch (_) {
      clean = null;
    }
    history.callMethod(
      'replaceState'.toJS,
      clean,
      ''.toJS,
      url.toJS,
    );
  } catch (_) {}
}
