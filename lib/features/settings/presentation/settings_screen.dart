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
                const ScreenHeader(title: 'Settings'),
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
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: settings.ambient,
                          activeTrackColor: AppColors.gold.withValues(
                            alpha: 0.5,
                          ),
                          thumbColor: const WidgetStatePropertyAll(
                            AppColors.gold,
                          ),
                          title: Text(
                            'Ambient Sound',
                            style: AppText.body.copyWith(fontSize: 14),
                          ),
                          subtitle: Text(
                            'Gentle soundscape on arrival and NOOR',
                            style: AppText.bodyMuted.copyWith(fontSize: 11),
                          ),
                          secondary: const Icon(
                            Icons.graphic_eq,
                            size: 18,
                            color: AppColors.gold,
                          ),
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
                          fontSize: 11,
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
                            final SharedPreferences prefs =
                                ref.watch(sharedPreferencesProvider);
                            final bool memoryOn =
                                prefs.getBool('ar.hadi.memory') == true;
                            return SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: memoryOn,
                              activeTrackColor: AppColors.gold.withValues(
                                alpha: 0.5,
                              ),
                              thumbColor: const WidgetStatePropertyAll(
                                AppColors.gold,
                              ),
                              title: Text(
                                'Hādi remembers you',
                                style: AppText.body.copyWith(fontSize: 14),
                              ),
                              subtitle: Text(
                                'Share your name so Hādi can greet you '
                                'personally. Stored on this device only.',
                                style: AppText.bodyMuted.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              secondary: const Icon(
                                Icons.face_outlined,
                                size: 18,
                                color: AppColors.gold,
                              ),
                              onChanged: (bool v) async {
                                await prefs.setBool('ar.hadi.memory', v);
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
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.onboarding),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text('Replay the introduction →',
                              style: AppText.bodyMuted.copyWith(
                                  color: AppColors.gold, fontSize: 13)),
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
                                      fontSize: 11,
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
