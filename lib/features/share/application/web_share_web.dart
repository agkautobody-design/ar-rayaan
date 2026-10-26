import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// True when the browser offers the Web Share API (phones, Safari, Edge).
bool get webShareSupported {
  try {
    return (web.window.navigator as JSObject).has('share');
  } catch (_) {
    return false;
  }
}

/// Opens the browser's share sheet. Must be called straight from a tap.
/// Returns false when it could not be shown, so the caller copies instead.
/// A person closing the sheet is not a failure.
Future<bool> webShare(String text, {String? title}) async {
  try {
    final JSObject data = JSObject();
    data['text'] = text.toJS;
    if (title != null) data['title'] = title.toJS;
    final JSAny? result = (web.window.navigator as JSObject).callMethod(
      'share'.toJS,
      data,
    );
    if (result == null) return false;
    await (result as JSPromise<JSAny?>).toDart;
    return true;
  } catch (e) {
    return e.toString().contains('AbortError');
  }
}
