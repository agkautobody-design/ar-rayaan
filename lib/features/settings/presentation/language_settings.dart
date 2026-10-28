import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/i18n/app_locale.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/focus_ring.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = ref.watch(l10nProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Language & Voice', close: true),
              Padding(padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text('YOUR TONGUE, YOUR CHOICE', style: AppText.eyebrow)),
              Text(l10n.t('settings.language.sub'), style: AppText.bodyMuted),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.t('settings.language'), style: AppText.eyebrow),
                  const SizedBox(height: 10),
                  for (final e in LocaleController.supported.entries)
                    Semantics(
                      button: true,
                      selected: locale == e.key,
                      child: FocusableTap(
                        onTap: () =>
                            ref.read(localeProvider.notifier).setLocale(e.key),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: locale == e.key
                                ? AppColors.gold
                                : AppColors.sand.withValues(alpha: 0.2)),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.value, style: AppText.body),
                                  Text(
                                    LocaleController.translationScope(e.key),
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                            ),
                            if (locale == e.key)
                              const Icon(Icons.check_circle,
                                  color: AppColors.goldLight, size: 20),
                          ]),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'What is translated today, in Arabic, Bangla and Urdu: the menus and tab names, Home, the first questions, Prayer Times, Qibla, the H\u0101di screen and its buttons, the Qur\u2019an screen labels, Faith, Family, You, Settings, Support & wellbeing, Our Sources, the Need help now sheet and the main crisis and support replies. Every one of these is a machine draft that no native speaker has checked yet, and the screens that carry support, safety or religious content say so on screen. Lessons, stories, hadith, H\u0101di\u2019s answers and long religious texts are still English, with the original Arabic for scripture. Arabic and Urdu also turn the layout right-to-left. Indonesian has only the Language & Voice labels; French, Turkish and Malay are not translated yet and the app stays in English.',
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.t('settings.voice'), style: AppText.eyebrow),
                  const SizedBox(height: 4),
                  Text(l10n.t('settings.voice.sub'), style: AppText.bodyMuted),
                  const SizedBox(height: 10),
                  Text('Natural, human-sounding voices are not available yet. '
                      'Until they are, the device reads the words in its own '
                      'voice.',
                      style: AppText.bodyMuted.copyWith(height: 1.5)),
                ]),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('THE SADAQAH JARIYAH PRINCIPLE', style: AppText.eyebrow),
                  const SizedBox(height: 8),
                  Text(
                    'This app is a continuing charity. Its knowledge keeps teaching '
                    'after its builders rest; its translations carry the deen across '
                    'tongues its founders never spoke. Every language added here is '
                    'an inheritance for a family the founder will never meet.',
                    style: AppText.bodyMuted.copyWith(height: 1.6),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
