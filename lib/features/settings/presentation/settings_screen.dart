import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      body: Stack(
        children: [
          const ScenicBackground.pattern(),
          SafeArea(
            child: Column(
              children: [
                const ScreenHeader(title: 'Settings', showSettings: false),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
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
                        onTap: () => context.go(AppRoutes.onboarding),
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
                            child: Text('Terms of Service →',
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
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('LANGUAGE', style: AppText.eyebrow),
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
                                    'Language & Voice',
                                    style: AppText.body.copyWith(fontSize: 14),
                                  ),
                                  Text(
                                    'Pick a language. Only these settings '
                                    'labels are translated so far; the rest of '
                                    'the app is English.',
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
                        child: Text('ABOUT', style: AppText.eyebrow),
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
                                    'Our Sources',
                                    style: AppText.body.copyWith(fontSize: 14),
                                  ),
                                  Text(
                                    'Qur’an, the Authentic Six, and guidance — fully transparent',
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
