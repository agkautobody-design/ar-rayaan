import 'package:flutter/foundation.dart' show ValueNotifier;

/// Raised by the quick-exit button and by the safe word. The privacy shield
/// (presentation layer) answers it: it clears the conversations and leaves for
/// Home with no way Back. Kept free of any other import so controllers can
/// raise it.
final ValueNotifier<int> kQuickExitSignal = ValueNotifier<int>(0);

void requestQuickExit() => kQuickExitSignal.value++;
