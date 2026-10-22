import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';

/// App-wide error handling.
///
/// Three nets, so that no failure ends as a bare grey rectangle:
/// * `FlutterError.onError` - errors thrown while building, laying out or
///   painting (the details still go to the console).
/// * `PlatformDispatcher.onError` and the `runZonedGuarded` zone in main() -
///   uncaught asynchronous errors, which are recorded and handled instead of
///   escaping to the console as "uncaught".
/// * `ErrorWidget.builder` - a widget that fails to build is replaced by
///   [AppErrorFallback]: a calm full-screen message with Home and Back when
///   the failed widget is a whole screen, a small inline note when it is
///   only a part of one.
///
/// No error is ever sent anywhere. The last few are kept in memory
/// ([recent]) for the Doctor and for tests.
abstract final class AppErrorHandling {
  /// The latest errors, newest last (at most [maxRecent]).
  static final List<String> recent = <String>[];
  static const int maxRecent = 20;

  /// Records an error (type and message only, never user data).
  static void record(Object error, StackTrace? stack, {String where = ''}) {
    final String line = where.isEmpty
        ? '${error.runtimeType}: $error'
        : '$where: ${error.runtimeType}: $error';
    recent.add(line.length > 300 ? line.substring(0, 300) : line);
    if (recent.length > maxRecent) recent.removeAt(0);
    debugPrint('Ar-Rayaan error ($where): $error');
  }

  /// Handler for `runZonedGuarded`.
  static void onZoneError(Object error, StackTrace stack) =>
      record(error, stack, where: 'zone');

  /// Handler for `PlatformDispatcher.onError`: true = handled.
  static bool onPlatformError(Object error, StackTrace stack) {
    record(error, stack, where: 'platform');
    return true;
  }

  /// Installs the three nets. Call once, after the binding is initialised.
  /// [replaceErrorWidget] is false in debug builds so developers keep the
  /// red error screen.
  static void install({bool? replaceErrorWidget}) {
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      record(details.exception, details.stack, where: 'flutter');
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    ui.PlatformDispatcher.instance.onError = onPlatformError;
    if (replaceErrorWidget ?? !kDebugMode) {
      ErrorWidget.builder = AppErrorFallback.builder;
    }
  }
}

/// What replaces a widget that threw while building.
class AppErrorFallback extends StatelessWidget {
  const AppErrorFallback({required this.details, super.key});

  final FlutterErrorDetails details;

  static Widget builder(FlutterErrorDetails details) =>
      AppErrorFallback(details: details);

  static const Color _night = Color(0xFF05090F);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _sand = Color(0xFFE8DCC0);

  void _home(BuildContext context) {
    try {
      GoRouter.of(context).go(AppRoutes.home);
    } catch (_) {
      // No router above this widget: nothing to navigate.
    }
  }

  void _back(BuildContext context) {
    try {
      final NavigatorState? nav = Navigator.maybeOf(context);
      if (nav != null && nav.canPop()) {
        nav.pop();
        return;
      }
    } catch (_) {
      // Fall through to Home.
    }
    _home(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final bool screenSized = c.hasBoundedWidth &&
              c.hasBoundedHeight &&
              c.maxWidth >= 240 &&
              c.maxHeight >= 240;
          if (!screenSized) return _inline();
          return _fullScreen(context);
        },
      ),
    );
  }

  /// A part of a screen failed: say so in place, small.
  Widget _inline() {
    return Container(
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
      color: const Color(0x1AD4AF37),
      child: const Text(
        'This part could not be shown.',
        style: TextStyle(
          color: _sand,
          fontSize: 13,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _fullScreen(BuildContext context) {
    return Material(
      color: _night,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 44, color: _gold),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _sand,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This screen could not be shown. Nothing you saved was '
                'lost. Go back, or return Home and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _sand,
                  fontSize: 15,
                  height: 1.5,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _FallbackButton(
                    label: 'Home',
                    icon: Icons.home_outlined,
                    filled: true,
                    onTap: () => _home(context),
                  ),
                  _FallbackButton(
                    label: 'Back',
                    icon: Icons.arrow_back,
                    filled: false,
                    onTap: () => _back(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackButton extends StatelessWidget {
  const _FallbackButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color gold = AppErrorFallbackColors.gold;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: filled ? gold : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(color: gold.withValues(alpha: 0.7)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    icon,
                    size: 18,
                    color: filled ? AppErrorFallbackColors.night : gold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: filled ? AppErrorFallbackColors.night : gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain constants: the fallback must not depend on the app theme, which may
/// be the very thing that failed.
abstract final class AppErrorFallbackColors {
  static const Color night = Color(0xFF05090F);
  static const Color gold = Color(0xFFD4AF37);
}
