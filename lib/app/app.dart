import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/env_config.dart';
import 'core/sound/sound_services.dart';
import 'l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class ArRayaanApp extends StatelessWidget {
  const ArRayaanApp({required this.env, super.key});

  final EnvConfig env;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ar-Rayaan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: buildRouter(),
      // First tap anywhere unlocks web audio; the soundscape setting is
      // mirrored into the ambient service.
      builder: (context, child) => Consumer(
        builder: (context, ref, _) {
          ref.listen(soundSettingsProvider, (_, next) {
            ref.read(ambientServiceProvider).setEnabled(next.ambient);
          });
          return Listener(
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
                constraints: const BoxConstraints(maxWidth: 460),
                child: ClipRect(
                  child: Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      const Positioned(
                        right: 12,
                        bottom: 12,
                        child: _AskHadiPill(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
        Locale('es'),
        Locale('ur'),
        Locale('pa'),
      ],
    );
  }
}

/// One tap to Hādi from anywhere in the app. Hides itself while you are
/// already talking to him.
class _AskHadiPill extends StatelessWidget {
  const _AskHadiPill();

  @override
  Widget build(BuildContext context) {
    final GoRouterDelegate delegate = GoRouter.of(context).routerDelegate;
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go(AppRoutes.hadi),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
