import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/i18n/app_locale.dart';
import '../../../app/core/sound/sound_services.dart';
import '../../../app/core/providers.dart';
import '../../../app/core/text_size.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/switch_row.dart';
import '../../elder/application/elder_mode.dart';
import '../../habits/application/return_loop.dart';
import '../../legal/legal_routes.dart';
import '../../quran/presentation/quran_offline_card.dart';
import '../../quran/presentation/quran_translation_card.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// Settings — begins with the Sound toggle promised on the locked splash
/// artwork ("Sound can be turned off in settings").
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SoundSettings settings = ref.watch(soundSettingsProvider);
    final L10n l10n = ref.watch(l10nProvider);
    final bool elder = ref.watch(elderModeProvider);
    final TextSizeChoice textSize = ref.watch(textSizeProvider);

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
                        child: Text('TEXT SIZE & ELDER MODE', style: AppText.eyebrow),
                      ),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Text size',
                              style: AppText.body.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Makes the words in the whole app bigger or '
                              'smaller. The Arabic A+ and A- in the Qur\u2019an '
                              'reader still work on top of this.',
                              style: AppText.bodyMuted,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final TextSizeChoice c
                                    in TextSizeChoice.values)
                                  ChoiceChip(
                                    key: Key('text-size-${c.id}'),
                                    label: Text(c.label),
                                    selected: c == textSize,
                                    showCheckmark: false,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.padded,
                                    selectedColor: AppColors.gold.withValues(
                                      alpha: 0.35,
                                    ),
                                    onSelected: (_) => unawaited(
                                      ref
                                          .read(textSizeProvider.notifier)
                                          .set(c),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: SwitchRow(
                          icon: Icons.elderly_outlined,
                          title: 'Elder Mode',
                          subtitle: 'Big words, big buttons, a simple home.',
                          value: elder,
                          onChanged: (bool v) async {
                            await ref
                                .read(elderModeProvider.notifier)
                                .set(v);
                            if (v && context.mounted) {
                              context.go(ElderMode.homeRoute);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(l10n.ui('ui.language').toUpperCase(), style: AppText.eyebrow),
                      ),
                      GlassCard(
                        onTap: () => context.open('/settings/language'),
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
                                    'Choose your language. Menus and home '
                                    'titles are translated for Arabic, '
                                    'Bangla and Urdu; other languages are not '
                                    'translated yet. Lessons, stories and '
                                    'answers stay in English.',
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
                        child: Text('OFFLINE', style: AppText.eyebrow),
                      ),
                      const QuranOfflineCard(),
                      const SizedBox(height: 12),
                      GlassCard(
                        key: const Key('settings-downloads'),
                        onTap: () => context.open(AppRoutes.downloads),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.download_for_offline_outlined,
                              size: 18,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Downloads',
                                    style: AppText.body.copyWith(fontSize: 14),
                                  ),
                                  Text(
                                    'Recitation audio, stories, guides and '
                                    'duas to keep on this device. Download '
                                    'everything, or one surah or juz at a '
                                    'time.',
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
                        child: Text('QUR’AN TRANSLATION', style: AppText.eyebrow),
                      ),
                      const QuranTranslationCard(),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('SUPPORT & WELLBEING', style: AppText.eyebrow),
                      ),
                      GlassCard(
                        key: const Key('settings-support'),
                        onTap: () => context.open(AppRoutes.supportSettings),
                        semanticsLabel: 'Support and wellbeing. Check-ins, what Hadi remembers, '
                            'private mode, quick exit and safe word.',
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_outline, size: 18, color: AppColors.gold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Support & wellbeing', style: AppText.body.copyWith(fontSize: 14)),
                                  Text(
                                    'Check-ins, what Hadi remembers, private mode, quick '
                                    'exit, safe word, language',
                                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: AppColors.gold.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(l10n.ui('ui.about').toUpperCase(), style: AppText.eyebrow),
                      ),
                      GlassCard(
                        onTap: () => context.open(AppRoutes.sources),
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
                          'advanced: it is under the More options menu '
                          '(top right) on the Hādi screen.',
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
                      if (kReturnLoopEnabled) ...<Widget>[
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('COMING BACK', style: AppText.eyebrow),
                        ),
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: SwitchRow(
                            icon: Icons.wb_twilight_outlined,
                            title: 'Keep a private log',
                            subtitle: 'Totals and a calendar for Qur\u2019an '
                                'reading, dhikr and lessons, kept on this '
                                'device only. Prayers and fasting come from '
                                'your own logs and are never shared.',
                            value: ref.watch(returnLoopEnabledProvider),
                            onChanged: (bool v) => unawaited(
                              ref
                                  .read(returnLoopEnabledProvider.notifier)
                                  .set(v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'It only adds up what you log. Switching this off '
                          'erases the days it saved.',
                          style: AppText.bodyMuted.copyWith(
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          key: const Key('open-my-log'),
                          onPressed: () => context.open(AppRoutes.tracking),
                          child: const Text('Open my log'),
                        ),
                      ],
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
                              subtitle: 'Lets Hādi greet you by the name on your '
                                  'account when it answers through an AI '
                                  'service you set up; the name is sent to that '
                                  'service with your question. It needs a '
                                  'signed-in account: as a guest there is no '
                                  'name to share, so this changes nothing. '
                                  'Off by default.',
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
                        child: FocusableTap(
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
                        child: FocusableTap(
                          onTap: () => context.open(LegalRoutes.terms),
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
                        child: FocusableTap(
                          onTap: () => context.open(LegalRoutes.privacy),
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
                        child: FocusableTap(
                          onTap: () => context.open(LegalRoutes.deleteAccount),
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
