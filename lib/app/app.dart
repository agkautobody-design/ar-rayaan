import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show ApplicationSwitcherDescription, SystemChrome;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/accessibility_scope.dart';
import 'core/env_config.dart';
import 'core/route_titles.dart';
import '../features/elder/application/elder_mode.dart';
import 'core/i18n/app_locale.dart';
import 'core/providers.dart';
import 'core/sound/sound_services.dart';
import 'l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class ArRayaanApp extends ConsumerStatefulWidget {
  const ArRayaanApp({required this.env, this.showOnboarding = false, super.key});

  final EnvConfig env;
  final bool showOnboarding;

  @override
  ConsumerState<ArRayaanApp> createState() => _ArRayaanAppState();
}

class _ArRayaanAppState extends ConsumerState<ArRayaanApp> {
  // The router lives in State so it is built once, not with every widget
  // rebuild (a locale change rebuilds MaterialApp but must keep navigation).
  late final GoRouter _router = buildRouter(initialLocation: _startRoute());

  /// Where a cold start lands: onboarding on first run; the Elder home when
  /// Elder Mode is on (the flag is written by the Elder tile and read here,
  /// so "the app opens here every time" is true); otherwise Home.
  String _startRoute() {
    if (widget.showOnboarding) return AppRoutes.onboarding;
    try {
      return ElderMode.launchLocation(
        ref.read(sharedPreferencesProvider),
        fallback: AppRoutes.splash,
      );
    } catch (_) {
      // Preferences unavailable (tests without a store): normal start.
    }
    return AppRoutes.splash;
  }

  String? _lastTitle;

  /// Keeps the browser tab title in step with the screen (web only).
  void _updateTitle() {
    if (!kIsWeb) return;
    String path;
    try {
      path = _router.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return;
    }
    final String title = RouteTitles.forPath(path);
    if (title == _lastTitle) return;
    _lastTitle = title;
    try {
      unawaited(
        SystemChrome.setApplicationSwitcherDescription(
          ApplicationSwitcherDescription(label: title),
        ),
      );
    } catch (_) {
      // The title is a nicety; never let it break navigation.
    }
  }

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_updateTitle);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTitle());
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_updateTitle);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The language the person chose in Settings (never GPS). Drives Flutter's
    // own localizations (dialogs, date pickers). The layout mirrors to
    // right-to-left only for a language whose whole interface is translated
    // (LocaleController.layoutDirection): today none, so Arabic and Urdu keep
    // the left-to-right layout instead of a mirrored English app. App text
    // itself is only translated where L10n/AppLocalizations have strings; see
    // LocaleController.translatedChrome.
    final Locale locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Ar-Rayaan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: locale,
      routerConfig: _router,
      // First tap anywhere unlocks web audio; the soundscape setting is
      // mirrored into the ambient service.
      builder: (context, child) => Consumer(
        builder: (context, ref, _) {
          ref.listen(soundSettingsProvider, (_, next) {
            ref.read(ambientServiceProvider).setEnabled(next.ambient);
          });
          return Directionality(
            textDirection: LocaleController.layoutDirection(locale),
            child: AccessibilityScope(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => ref.read(ambientServiceProvider).unlock(),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/bg_pattern.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0xD805090F),
                      BlendMode.darken,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: ConstrainedBox(
                  // Responsive shell: phones fill their screen; tablets and
                  // browsers use their real width instead of a phone column.
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width < 600
                        ? 460
                        : MediaQuery.of(context).size.width < 1100
                            ? 780
                            : 1120,
                  ),
                  child: ClipRect(
                    // The "Ask Hādi" pill is drawn by each page itself (see
                    // _fade in router.dart), so dialogs and sheets stay on
                    // top of it.
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          );
        },
      ),
      localizationsDelegates: const [
        _AppLocalizationsFallbackDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Exactly the languages the picker offers, so what Settings lets you
      // choose is what Flutter will actually apply.
      supportedLocales: LocaleController.supported.keys.toList(),
    );
  }
}

/// AppLocalizations only ships English and Arabic strings. For every other
/// picker language it falls back to English instead of leaving
/// `AppLocalizations.of(context)` empty.
class _AppLocalizationsFallbackDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsFallbackDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale)
          ? AppLocalizations.delegate.load(locale)
          : AppLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(_AppLocalizationsFallbackDelegate old) => false;
}
