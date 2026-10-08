import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/sound/sound_services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../application/noor_providers.dart';
import '../domain/noor_entry.dart';

/// Screen 7 · Today's NOOR — daily ayah/hadith + reflection.
///
/// Locked layout preserved; the quote area now shows the daily NOOR from the
/// bundled collection (Arabic + translation + real source), and reflections
/// persist locally (sync after O-4). Content change pending Founder approval.
class NoorScreen extends ConsumerStatefulWidget {
  const NoorScreen({super.key});

  @override
  ConsumerState<NoorScreen> createState() => _NoorScreenState();
}

class _NoorScreenState extends ConsumerState<NoorScreen>
    with AmbientHost<NoorScreen> {
  Future<void> _openReflectionSheet() async {
    final TextEditingController controller = TextEditingController();
    final String? saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: GlassCard(
            strong: true,
            borderRadius: 24,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your Reflection',
                        style: AppText.titleMedium,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.sand.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  style: AppText.body,
                  decoration: InputDecoration(
                    hintText: 'What did this NOOR stir in your heart?',
                    hintStyle: AppText.bodyMuted.copyWith(
                      color: AppColors.textFaint,
                    ),
                    filled: true,
                    fillColor: AppColors.night.withValues(alpha: 0.5),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GoldButton(
                  label: 'Save Reflection',
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(controller.text.trim()),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (saved != null && saved.isNotEmpty) {
      await ref.read(noorReflectionsProvider.notifier).add(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<NoorEntry> noor = ref.watch(todayNoorProvider);
    final List<String> reflections = ref.watch(noorReflectionsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const ScenicBackground.pattern(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const ScreenHeader(title: 'Today’s NOOR'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      GlassCard(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/bg_noor.jpg',
                                height: 260,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.night.withValues(alpha: 0.1),
                                        AppColors.night.withValues(alpha: 0.85),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 20,
                                right: 20,
                                bottom: 16,
                                child: noor.when(
                                  loading: () => Text(
                                    '…',
                                    style: AppText.titleMedium.copyWith(
                                      fontSize: 19,
                                      height: 1.5,
                                    ),
                                  ),
                                  error: (_, _) => Text(
                                    'So remember Me; I will remember you.',
                                    style: AppText.titleMedium.copyWith(
                                      fontSize: 19,
                                      height: 1.5,
                                    ),
                                  ),
                                  data: (NoorEntry entry) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                          entry.arabic,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          style: AppText.arabicLarge.copyWith(
                                            fontSize: 17,
                                            height: 1.7,
                                            color: AppColors.goldLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        entry.english,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.titleMedium.copyWith(
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Text(
                                            '— ${entry.source.toUpperCase()}',
                                            style: AppText.bodyMuted.copyWith(
                                              fontSize: 12,
                                              color: AppColors.gold,
                                            ),
                                          ),
                                          const Spacer(),
                                          SpeakButton(
                                            text:
                                                '${entry.english} ${entry.prompt}',
                                            size: 32,
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.night.withValues(
                                                alpha: 0.4,
                                              ),
                                              border: Border.all(
                                                color: AppColors.gold
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.share_outlined,
                                              size: 14,
                                              color: AppColors.gold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reflection', style: AppText.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              noor.valueOrNull?.prompt ??
                                  'Take a moment to reflect on this message.',
                              style: AppText.bodyMuted.copyWith(
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GoldButton(
                              label: 'Reflect Now',
                              onPressed: _openReflectionSheet,
                            ),
                          ],
                        ),
                      ),
                      if (reflections.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            top: 20,
                            bottom: 8,
                          ),
                          child: Text(
                            'YOUR REFLECTIONS',
                            style: AppText.eyebrow,
                          ),
                        ),
                        for (final r in reflections)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.favorite_outline,
                                    size: 16,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      r,
                                      style: AppText.body.copyWith(height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
