import 'dart:js_interop';

@JS('Intl.DateTimeFormat')
extension type _DateTimeFormat._(JSObject _) implements JSObject {
  external factory _DateTimeFormat();
  external _ResolvedOptions resolvedOptions();
}

extension type _ResolvedOptions._(JSObject _) implements JSObject {
  external JSString? get timeZone;
}

/// The browser's IANA time zone, from Intl.DateTimeFormat.
String? platformTimeZone() {
  try {
    return _DateTimeFormat().resolvedOptions().timeZone?.toDart;
  } catch (_) {
    return null;
  }
}
