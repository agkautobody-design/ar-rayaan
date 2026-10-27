import 'dart:async';

import 'online_status_stub.dart'
    if (dart.library.js_interop) 'online_status_web.dart';

/// Reads the connection flag. Replaced in tests.
bool? Function() deviceOnlineProbe = platformReportsOnline;

/// Whether the device reports a network connection. Browser only: the
/// browser's own flag, which can say "online" on a dead connection but is
/// reliable when it says "offline". Null when unknown (the phone apps, where
/// nothing needs a download).
bool? get deviceReportsOnline => deviceOnlineProbe();

/// The browser's online / offline events. Replaced in tests.
Stream<bool> Function() deviceOnlineChanges = platformOnlineChanges;
