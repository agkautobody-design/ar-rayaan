import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/env_config.dart';
import '../features/elder/application/elder_mode.dart';
import 'core/i18n/app_locale.dart';
import 'core/providers.dart';
import 'core/sound/sound_services.dart';
import 'l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

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

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The language the person chose in Settings (never GPS). Drives Flutter's
    // own localizations (dialogs, date pickers, text direction), so picking
    // Arabic or Urdu flips the app to right-to-left. App text itself is only
    // translated where L10n/AppLocalizations have strings; see
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
          // Respect the system text size, but cap the extreme end so fixed
          // layouts stay usable (Android's largest setting is 2.0x).
          final MediaQueryData mq = MediaQuery.of(context);
          final TextScaler scaler = mq.textScaler.clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 2.0,
          );
          ref.listen(soundSettingsProvider, (_, next) {
            ref.read(ambientServiceProvider).setEnabled(next.ambient);
          });
          return MediaQuery(
            data: mq.copyWith(textScaler: scaler),
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
                    child: Stack(
                      children: [
                        child ?? const SizedBox.shrink(),
                        if (!kDebugMode)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: _AskHadiPill(router: _router),
                          ),
                      ],
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

/// One tap to Hādi from anywhere in the app. Hides itself while you are
/// already talking to him.
class _AskHadiPill extends StatelessWidget {
  const _AskHadiPill({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final GoRouterDelegate delegate = router.routerDelegate;
    return AnimatedBuilder(
      animation: delegate,
      builder: (context, _) {
        var path = '';
        try {
          path = delegate.currentConfiguration.uri.path;
        } catch (_) {
          path = '';
        }
        if (path.startsWith('/hadi')) return const SizedBox.shrink();
        return SafeArea(
          child: Semantics(
            button: true,
            label: 'Ask H\u0101di',
            excludeSemantics: true,
            onTap: () => router.go(AppRoutes.hadi),
            child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => router.go(AppRoutes.hadi),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF20A0F18),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.goldLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ask H\u0101di',
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }
}
