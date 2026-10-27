import 'package:flutter/foundation.dart';

/// True while a child is using Kids Corner (and the lessons and stories it
/// opened). While it is on, no screen offers the Settings gear (account
/// deletion, Elder Mode, Hadi memory) or the "Ask Hadi" AI pill; leaving Kids
/// Corner needs the parent check, which turns it off.
///
/// A plain notifier rather than a provider so widgets that live outside a
/// ProviderScope (the header, the pill) can listen to it. It is held in
/// memory only, so a reload always starts with it off.
final ValueNotifier<bool> kKidsMode = ValueNotifier<bool>(false);
