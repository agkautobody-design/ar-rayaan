import 'dart:async';

/// Not the browser: unknown.
bool? platformReportsOnline() => null;

/// Not the browser: no events.
Stream<bool> platformOnlineChanges() => const Stream<bool>.empty();
