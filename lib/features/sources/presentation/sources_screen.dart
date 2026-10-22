import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/core/safe_url.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../quran/domain/quran_texts.dart';
import '../../academy/domain/recitation_audio.dart';

/// Our Sources — every text, translation, recitation, and scholarly
/// reference used in Ar-Rayaan, chosen by the Founder.
///
/// Hadith sources: the six canonical collections (al-Kutub as-Sittah),
/// approved by the Founder with his own descriptions. Knowledge & guidance: Shaykh Muhammad Saqib
/// Iqbal. Recorded in Build Sheet v1.14 (O-5 hadith portion resolved).
class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  static final Uri _shaykhChannel = Uri.https(
    'youtube.com',
    '/@ShaykhSaqibIqbal',
  );

  /// The six canonical collections — Founder-approved, with his descriptions.
  static const List<(String, String, String)> _sixBooks = [
    (
      'Sahih al-Bukhari',
      'Imam Muhammad al-Bukhari (d. 870 CE)',
      'Widely considered the most authentic book after the Qur’an.',
    ),
    (
      'Sahih Muslim',
      'Imam Muslim ibn al-Hajjaj (d. 875 CE)',
      'Nearly equal to Sahih al-Bukhari in authenticity.',
    ),
    (
      'Sunan Abu Dawood',
      'Abu Dawood al-Sijistani (d. 889 CE)',
      'Primarily focuses on rulings of Islamic law (fiqh).',
    ),
    (
      'Jami’ al-Tirmidhi',
      'Imam al-Tirmidhi (d. 892 CE)',
      'Notable for detailed classifications of hadith and notes on the different legal schools.',
    ),
    (
      'Sunan an-Nasa’i',
      'Al-Nasa’i (d. 915 CE)',
      'Highly respected for the strict criteria the author used in selecting narrators.',
    ),
    (
      'Sunan Ibn Majah',
      'Ibn Majah (d. 887 CE)',
      'Added as the sixth book by the scholar Ibn al-Qaisarani in the 11th century — completing the six canonical collections (al-Kutub as-Sittah).',
    ),
  ];

  Future<void> _openChannel() async {
    try {
      await launchUrl(_shaykhChannel, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuranTexts texts =
        ref.watch(quranTextsProvider).value ?? QuranTexts.fallback;
    return ScenicScaffold.pattern(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Our Sources'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // ---------------- THE QUR'AN ----------------
                  _SectionLabel('THE QUR’AN'),
                  GlassCard(
                    child: Column(
                      children: [
                        _SourceRow(
                          title: texts.arabic.title,
                          subtitle:
                              '${texts.arabic.note} Source: ${texts.arabic.credit}.',
                          link: texts.arabic.url,
                        ),
                        const _Divider(),
                        _SourceRow(
                          title: texts.translation.title,
                          subtitle:
                              '${texts.translation.note} Source: ${texts.translation.credit}.',
                          link: texts.translation.url,
                        ),
                        const _Divider(),
                        _SourceRow(
                          title: 'Recitation · ${ReciterPack.all.length} reciters',
                          subtitle:
                              'Real recorded recitation, never AI voices for Qur’an. Streamed ayah by ayah from everyayah.com: ${ReciterPack.all.map((ReciterPack r) => r.displayName).join('; ')}. Each reciter is named on screen while playing.',
                          link: 'https://everyayah.com',
                        ),
                        const _Divider(),
                        _SourceRow(
                          title: 'How we handle religious content',
                          subtitle:
                              'What we quote, what we label, what we leave out: Qur’an, hadith grades, earlier accounts, images, and scholar review status.',
                          onTap: () => context.push(AppRoutes.sourcesPolicy),
                        ),
                      ],
                    ),
                  ),

                  // ---------------- HADITH ----------------
                  _SectionLabel('HADITH · THE SIX COLLECTIONS'),
                  GlassCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < _sixBooks.length; i++) ...[
                          if (i > 0) const _Divider(),
                          _SourceRow(
                            title: _sixBooks[i].$1,
                            subtitle: '${_sixBooks[i].$2} — ${_sixBooks[i].$3}',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only Bukhari and Muslim are known as the two Sahihayn. '
                    'The four Sunan contain sahih, hasan and weaker reports, so '
                    'every hadith in Ar-Rayaan names its collection and number '
                    'and carries a grade only where one has been checked '
                    '(against sunnah.com and the hadith-api editions of '
                    'fawazahmed0, with grades from the compilers and '
                    'al-Albani). Where a grade could not be checked, it is '
                    'left off.\n\n'
                    'Readable now in-app: The Forty Hadith of Imam an-Nawawi '
                    '(42 narrations) and the daily hadith. The full six-book '
                    'library arrives in a coming update.',
                    style: AppText.bodyMuted.copyWith(
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),

                  // ---------------- KNOWLEDGE & GUIDANCE ----------------
                  _SectionLabel('KNOWLEDGE & GUIDANCE'),
                  GlassCard(
                    onTap: _openChannel,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            size: 20,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shaykh Muhammad Saqib Iqbal',
                                style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Lectures on creed, fiqh, seerah and purification of the heart · Official YouTube channel',
                                style: AppText.bodyMuted.copyWith(
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 15,
                          color: AppColors.gold.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),

                  // ---------------- ALSO IN AR-RAYAAN ----------------
                  _SectionLabel('ALSO IN AR-RAYAAN'),
                  const GlassCard(
                    child: Column(
                      children: [
                        _SourceRow(
                          title: 'Adhkar · Hisn al-Muslim',
                          subtitle:
                              'Arabic from the Hisn al-Muslim of Sa’id al-Qahtani (rn0x/Adhkar-json); English meanings abridged from the Darussalam rendering. Each dhikr lists its hadith source and grade where verified.',
                        ),
                        _Divider(),
                        _SourceRow(
                          title: 'Prayer Times · Aladhan',
                          subtitle:
                              'Live calculation by your city and method (Founder-approved source)',
                        ),
                        _Divider(),
                        _SourceRow(
                          title: 'Adhan · Masjid al-Haram',
                          subtitle:
                              'The call to prayer from the Sacred Mosque, Makkah',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'CHECKED · CITED · NOT YET SCHOLAR-REVIEWED',
                    style: AppText.eyebrow.copyWith(
                      fontSize: 12,
                      color: AppColors.gold.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 14, bottom: 8),
      child: Text(text, style: AppText.eyebrow),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.title,
    required this.subtitle,
    this.link,
    this.onTap,
  });

  final String title;
  final String subtitle;

  /// External page for the source (opened in the browser).
  final String? link;

  /// In-app destination; takes precedence over [link].
  final VoidCallback? onTap;

  Future<void> _open() async {
    final String? l = link;
    if (l == null) return;
    try {
      final Uri? u = SafeUrl.web(l);
      if (u == null) return;
      await launchUrl(u, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool tappable = onTap != null || link != null;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              Icons.verified_outlined,
              size: 15,
              color: AppColors.gold.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!tappable) return row;
    return Semantics(
      button: true,
      label: link != null ? '$title, opens $link' : title,
      child: InkWell(onTap: onTap ?? _open, child: row),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: AppColors.gold.withValues(alpha: 0.1),
      indent: 40,
    );
  }
}
