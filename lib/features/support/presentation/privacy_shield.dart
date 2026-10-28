import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/core/providers.dart';
import '../../academy/application/wasia_controller.dart';
import '../../hadi/application/hadi_controller.dart';
import '../../sakina/application/sakina_providers.dart';
import '../application/support_settings.dart';
import '../domain/quick_exit_signal.dart';
import 'history_replace.dart';

/// Wraps the whole app (see app.dart).
///
///  * Quick exit: clears Hadi's and Wasia's conversations (memory only) and
///    goes to Home with no way Back.
///  * Private mode: when the app is covered or goes to the background, the
///    screen is replaced by a plain neutral cover, and on return the
///    conversations are already gone. The notification text is not set by
///    this app at all in private mode (no content is ever put in one).
///
/// The launcher label of the app cannot be changed while it runs; that is a
/// platform limit and is said so in Settings.
class PrivacyShield extends ConsumerStatefulWidget {
  const PrivacyShield({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends ConsumerState<PrivacyShield> with WidgetsBindingObserver {
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    kQuickExitSignal.addListener(_exit);
    // Private mode: opening the app (or reloading the page) never lands
    // inside a conversation or a support screen from the last visit.
    WidgetsBinding.instance.addPostFrameCallback((_) => _coldOpen());
  }

  static const List<String> _quietPrefixes = kQuickExitQuietPrefixes;

  void _coldOpen() {
    if (!mounted || !_private) return;
    try {
      final String path =
          widget.router.routeInformationProvider.value.uri.path;
      for (final String p in _quietPrefixes) {
        if (path == p || path.startsWith('$p/')) {
          _exit();
          return;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    kQuickExitSignal.removeListener(_exit);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _private {
    try {
      return ref.read(supportSettingsProvider).privateMode;
    } catch (_) {
      return false;
    }
  }

  void _exit() {
    // Back (the browser's too) must not return to the screen just left.
    armQuickExitGuard();
    try {
      ref.read(hadiControllerProvider.notifier).clearThread();
      ref.read(wasiaControllerProvider.notifier).clear();
      ref.read(wasiaParentControllerProvider.notifier).clear();
      // The country picked for the help lines is part of what was said.
      ref.read(pickedHelpCountryProvider.notifier).state = null;
    } catch (_) {}
    // Web: overwrite the sensitive entry so Back does not return to it.
    replaceHistoryEntryWithHome();
    try {
      widget.router.go(AppRoutes.home);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_private) return;
    final bool away = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
    if (away && !_covered) {
      // The cover goes up before the system takes its app-switcher picture.
      setState(() => _covered = true);
      if (state == AppLifecycleState.paused) _exit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        if (_covered)
          Positioned.fill(
            child: Material(
              color: const Color(0xFF14181F),
              child: InkWell(
                key: const Key('privacy-cover'),
                onTap: () => setState(() => _covered = false),
                child: const Center(
                  child: Text(
                    'Tap to continue',
                    style: TextStyle(color: Color(0xFF8A93A3), fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A small, always-visible button to leave a support screen at once.
///
/// The first time it is shown it says, in one line, what it does and what it
/// cannot do (the browser keeps older history). After that the line is gone.
class QuickExitButton extends ConsumerStatefulWidget {
  const QuickExitButton({super.key});

  @override
  ConsumerState<QuickExitButton> createState() => _QuickExitButtonState();
}

const String kExitExplainedPref = 'ar.support.exit_explained';

class _QuickExitButtonState extends ConsumerState<QuickExitButton> {
  bool _explain = false;

  @override
  void initState() {
    super.initState();
    try {
      final SharedPreferences p = ref.read(sharedPreferencesProvider);
      if (p.getBool(kExitExplainedPref) != true) {
        _explain = true;
        // Said once: it is marked as seen as soon as it has been on screen.
        p.setBool(kExitExplainedPref, true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final SupportSettings s = ref.watch(supportSettingsProvider);
    if (!s.quickExit) return const SizedBox.shrink();
    return Align(
      alignment: s.quickExitLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment:
            s.quickExitLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            button: true,
            label: 'Quick exit. Clears this conversation and leaves now.',
            child: OutlinedButton.icon(
              key: const Key('quick-exit'),
              onPressed: requestQuickExit,
              icon: const Icon(Icons.exit_to_app, size: 20),
              label: const Text('Exit now'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ),
          if (_explain)
            const Padding(
              key: Key('quick-exit-explained'),
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Exit now clears this chat and takes you to Home at once. '
                'It is here on every support page.',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3)),
              ),
            ),
        ],
      ),
    );
  }
}
