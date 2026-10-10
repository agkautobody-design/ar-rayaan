import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';

/// Recitation audio packs. The per-surah downloader returns with the
/// reciter vault; until then the packs are listed honestly and the
/// repeat-after-reciter loops stay available in the recitation school.
class AudioPacksScreen extends StatelessWidget {
  const AudioPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Audio Packs', close: true),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text('RECITATION, COMING WITH THE VAULT', style: AppText.eyebrow),
              ),
              GlassCard(
                child: Text(
                  'Per-surah recitation packs (multiple ijazah-certified reciters, '
                  'offline-ready) arrive with the reciter vault — the same delivery '
                  'that carries word-by-word and tajweed colors. The packs below are '
                  'the promised library; the vault is the key.',
                  style: AppText.bodyMuted.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 12),
              for (final s in const ['Juz 1-30 — full khatm pack', 'Al-Fatihah & the short surahs — prayer pack', 'Juz Amma — memorization pack', 'Reciter comparison set — four voices, one mushaf'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Row(children: [
                      const Icon(Icons.audiotrack_outlined,
                          size: 20, color: AppColors.goldLight),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(s, style: AppText.body.copyWith(fontSize: 13.5))),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
