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
                child: Text('NOT AVAILABLE YET', style: AppText.eyebrow),
              ),
              GlassCard(
                child: Text(
                  'Downloadable recitation packs are not available yet, and nothing '
                  'below can be downloaded. You can listen to recitation in the '
                  'Qur\u2019an reader today. The list shows what we plan to offer.',
                  style: AppText.bodyMuted.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 12),
              for (final s in const ['Planned: full Qur\u2019an pack', 'Planned: Al-Fatihah and the short surahs', 'Planned: Juz Amma memorization pack', 'Planned: reciter comparison set'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Row(children: [
                      const Icon(Icons.schedule,
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
