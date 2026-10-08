import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              color: const Color(0xFF04070C),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ClipRect(child: child ?? const SizedBox.shrink()),
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
