import 'package:flutter/foundation.dart' show ValueNotifier;

/// Raised by the quick-exit button and by the safe word. The privacy shield
/// (presentation layer) answers it: it clears the conversations and leaves for
/// Home with no way Back. Kept free of any other import so controllers can
/// raise it.
final ValueNotifier<int> kQuickExitSignal = ValueNotifier<int>(0);

void requestQuickExit() => kQuickExitSignal.value++;

/// The screens a quick exit leaves. A browser keeps its own history, so the
/// Back button would otherwise return to one of them. After a quick exit,
/// until the person next touches or types in the app, an address under one of
/// these goes to Home instead (see [quickExitRedirect]).
const List<String> kQuickExitQuietPrefixes = <String>[
  '/hadi',
  '/support',
  '/sakina',
  '/kids/safety',
];

DateTime? _quickExitAt;

/// How long the guard holds if the person does nothing at all.
const Duration kQuickExitGuardFor = Duration(minutes: 20);

/// Called when a quick exit has just happened.
void armQuickExitGuard([DateTime? now]) {
  _quickExitAt = now ?? DateTime.now();
}

/// Called on the person's next deliberate touch or key press.
void releaseQuickExitGuard([DateTime? now]) {
  final DateTime? at = _quickExitAt;
  if (at == null) return;
  // The press that raised the exit also ends with a key or pointer event;
  // that one must not release the guard.
  final DateTime t = now ?? DateTime.now();
  if (t.difference(at) < const Duration(milliseconds: 400)) return;
  _quickExitAt = null;
}

bool get quickExitGuardActive {
  final DateTime? at = _quickExitAt;
  if (at == null) return false;
  if (DateTime.now().difference(at) > kQuickExitGuardFor) {
    _quickExitAt = null;
    return false;
  }
  return true;
}

/// Router redirect: Home when the address is a screen that was just left by a
/// quick exit and nothing has been touched since (so it came from the
/// browser's Back button or a stale history entry).
String? quickExitRedirect(String path, String home) {
  if (!quickExitGuardActive) return null;
  for (final String p in kQuickExitQuietPrefixes) {
    if (path == p || path.startsWith('$p/')) return home;
  }
  return null;
}
