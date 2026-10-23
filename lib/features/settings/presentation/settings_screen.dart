import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/i18n/app_locale.dart';
import '../../../app/core/sound/sound_services.dart';
import '../../../app/core/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/switch_row.dart';
import '../../legal/legal_routes.dart';

/// Settings — begins with the Sound toggle promised on the locked splash
/// artwork ("Sound can be turned off in settings").
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SoundSettings settings = ref.watch(soundSettingsProvider);
    final L10n l10n = ref.watch(l10nProvider);

    return Scaffold(
      body: Stack(
        children: [
          const ScenicBackground.pattern(),
          SafeArea(
            child: Column(
              children: [
                ScreenHeader(title: l10n.ui('ui.settings'), showSettings: false),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(l10n.ui('ui.language').toUpperCase(), style: AppText.eyebrow),
                      ),
                      GlassCard(
                        onTap: () => context.push('/settings/language'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.translate_outlined,
                              size: 18,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('settings.language') == 'Language'
                                        ? 'Language & Voice'
                                        : '${l10n.t('settings.language')} · '
                                            'Language & Voice',
                                    style: AppText.body.copyWith(fontSize: 14),
                                  ),
                                  Text(
                                    'Pick English, Arabic, Bangla or Urdu. '
                                    'Menus and home titles change; lessons, '
                                    'stories and answers stay English.',
                                    style: AppText.bodyMuted,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.gold.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(l10n.ui('ui.about').toUpperCase(), style: AppText.eyebrow),
                      ),
                      GlassCard(
                        onTap: () => context.push(AppRoutes.sources),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 18,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.ui('ui.sources'),
                                    style: AppText.body.copyWith(fontSize: 14),
                                  ),
                                  Text(
                                    'How this app works and what it cannot do, '
                                    'plus every source we use',
                                    style: AppText.bodyMuted.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.gold.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('WHAT IS FREE', style: AppText.eyebrow),
                      ),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          'Everything in this app is free today, including '
                          'Hādi, and nothing asks for a card. A paid plan for '
                          'extra live answers is planned but not open yet. '
                          'Connecting your own AI account is optional and '
                          'advanced: it is under the ⋮ menu on the Hādi '
                          'screen.',
                          style: AppText.bodyMuted.copyWith(
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('SOUND', style: AppText.eyebrow),
                      ),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: SwitchRow(
                          icon: Icons.graphic_eq,
                          title: 'Ambient Sound',
                          subtitle: 'Gentle soundscape on arrival and NOOR',
                          value: settings.ambient,
                          onChanged: (bool v) {
                            ref
                                .read(soundSettingsProvider.notifier)
                                .setAmbient(v);
                            ref.read(ambientServiceProvider).setEnabled(v);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Adhan, Qur’an recitation, and read-aloud always play '
                        'when you tap them — this switch is only for the '
                        'background soundscape.',
                        style: AppText.bodyMuted.copyWith(
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('HĀDI', style: AppText.eyebrow),
                      ),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: StatefulBuilder(
                          builder: (context, setTile) {
                            // Preferences may be unavailable (tests, a failed
                            // storage init): show the switch off, not a crash.
                            SharedPreferences? prefs;
                            try {
                              prefs = ref.watch(sharedPreferencesProvider);
                            } catch (_) {
                              prefs = null;
                            }
                            final bool memoryOn =
                                prefs?.getBool('ar.hadi.memory') == true;
                            return SwitchRow(
                              icon: Icons.face_outlined,
                              title: 'Hādi remembers you',
                              subtitle: 'Share your name so Hādi can greet you '
                                  'personally. Stored on this device only.',
                              value: memoryOn,
                              onChanged: prefs == null
                                  ? null
                                  : (bool v) async {
                                      await prefs!.setBool('ar.hadi.memory', v);
                                      setTile(() {});
                                    },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hādi also remembers your last conversation on this '
                        'device, so you can pick up where you left off. Clear '
                        'it any time from the Hādi screen.',
                        style: AppText.bodyMuted.copyWith(
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        button: true,
                        label: 'Replay the introduction',
                        excludeSemantics: true,
                        child: GestureDetector(
                        onTap: () => context.go('${AppRoutes.onboarding}?replay=1'),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, top: 15, bottom: 15),
                          child: Text('Replay the introduction →',
                              style: AppText.bodyMuted.copyWith(
                                  color: AppColors.gold, fontSize: 13)),
                        ),
                      ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text('LEGAL & ACCOUNT', style: AppText.eyebrow),
                      ),
                      Semantics(
                        button: true,
                        label: 'Open the Terms of Service',
                        child: GestureDetector(
                          onTap: () => context.push(LegalRoutes.terms),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, top: 15, bottom: 15),
                            child: Text('Terms of Service (a draft, not yet checked by a lawyer) →',
                                style: AppText.bodyMuted.copyWith(
                                    color: AppColors.gold, fontSize: 13)),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Open the Privacy Policy',
                        child: GestureDetector(
                          onTap: () => context.push(LegalRoutes.privacy),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, top: 15, bottom: 15),
                            child: Text('Privacy Policy →',
                                style: AppText.bodyMuted.copyWith(
                                    color: AppColors.gold, fontSize: 13)),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Delete my account and data',
                        child: GestureDetector(
                          onTap: () => context.push(LegalRoutes.deleteAccount),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, top: 15, bottom: 15),
                            child: Text('Delete my account →',
                                style: AppText.bodyMuted.copyWith(
                                    color: AppColors.gold, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
