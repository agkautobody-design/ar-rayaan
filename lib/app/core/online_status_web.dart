import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool? platformReportsOnline() {
  try {
    return web.window.navigator.onLine;
  } catch (_) {
    return null;
  }
}

StreamController<bool>? _shared;

/// The browser's online / offline events, as a stream of "is online". One
/// pair of listeners serves every caller (a screen that listens and goes
/// away only cancels its own subscription).
Stream<bool> platformOnlineChanges() {
  final StreamController<bool> existing = _shared ??= _start();
  return existing.stream;
}

StreamController<bool> _start() {
  final StreamController<bool> c = StreamController<bool>.broadcast();
  try {
    web.window.addEventListener(
      'online',
      ((web.Event _) => c.add(true)).toJS,
    );
    web.window.addEventListener(
      'offline',
      ((web.Event _) => c.add(false)).toJS,
    );
  } catch (_) {
    // No window: the stream just never fires.
  }
  return c;
}
