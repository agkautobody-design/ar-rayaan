import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';

/// Recitation audio packs. The downloads themselves live in Downloads (the
/// whole Qur'an, one juz or one surah, for the reciter the person chose);
/// this page points there so the older doorway still lands somewhere useful.
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
                child: Text('RECITATION DOWNLOADS', style: AppText.eyebrow),
              ),
              GlassCard(
                child: Text(
                  'Recitation packs are in Downloads. Choose a reciter, then '
                  'download the whole Qur’an, one juz or one surah to '
                  'listen with no internet. Real recorded recitation only, '
                  'never an AI voice.',
                  style: AppText.bodyMuted.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const Key('audio-packs-open-downloads'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.night,
                  ),
                  onPressed: () => context.open('/downloads'),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Open Downloads'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
