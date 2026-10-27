import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../academy/application/wasia_controller.dart';
import '../../hadi/application/hadi_controller.dart';
import '../application/support_settings.dart';
import '../domain/quick_exit_signal.dart';

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
    try {
      ref.read(hadiControllerProvider.notifier).clearThread();
      ref.read(wasiaControllerProvider.notifier).clear();
    } catch (_) {}
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
class QuickExitButton extends ConsumerWidget {
  const QuickExitButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SupportSettings s = ref.watch(supportSettingsProvider);
    if (!s.quickExit) return const SizedBox.shrink();
    return Align(
      alignment: s.quickExitLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Semantics(
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
    );
  }
}
