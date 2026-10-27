import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'online_status.dart';

/// For a provider that answers with a fallback when a download fails
/// (an empty map, the built-in copy). Riverpod keeps that answer for good, so
/// after reconnecting the screen kept showing the fallback until the page was
/// reloaded. Call this on the failure path: when the browser reports it is
/// back online the provider is rebuilt and fetches again.
void refreshWhenBackOnline(Ref ref) {
  StreamSubscription<bool>? sub;
  try {
    sub = deviceOnlineChanges().listen((bool online) {
      if (online) ref.invalidateSelf();
    });
  } catch (_) {
    // No connection events here (phone apps): nothing to wait for.
  }
  ref.onDispose(() {
    unawaited(sub?.cancel());
  });
}
