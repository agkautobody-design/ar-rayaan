import '../../../app/core/scholar_review.dart';
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
import '../../share/application/share_text.dart';
import '../../share/presentation/share_actions.dart';
import '../application/noor_providers.dart';
import '../domain/noor_entry.dart';
import '../../../app/theme/widgets/focus_ring.dart';

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
  Future<void> _confirmDelete(int index) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        semanticLabel: 'Delete this reflection?',
        title: const Text('Delete this reflection?'),
        content: const Text('It will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            key: const Key('reflection-delete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes ?? false) {
      await ref.read(noorReflectionsProvider.notifier).removeAt(index);
    }
  }

  Future<void> _openReflectionSheet() async {
    final TextEditingController controller = TextEditingController();
    final ValueNotifier<String?> emptyHint = ValueNotifier<String?>(null);
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
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.sand.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String?>(
                  valueListenable: emptyHint,
                  builder: (BuildContext _, String? hint, Widget? _) =>
                      Semantics(label: 'What did this NOOR stir in your heart?', child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  style: AppText.body,
                  onChanged: (_) => emptyHint.value = null,
                  decoration: InputDecoration(
                    errorText: hint,
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
                  )),
                ),
                const SizedBox(height: 12),
                GoldButton(
                  label: 'Save Reflection',
                  onPressed: () {
                    final String text = controller.text.trim();
                    if (text.isEmpty) {
                      emptyHint.value = 'Write a few words first';
                      return;
                    }
                    Navigator.of(sheetContext).pop(text);
                  },
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
                const ScholarReviewNote(
                  reviewKey: 'noor',
                  padding: const EdgeInsets.only(bottom: 8),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      GlassCard(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // The picture fills whatever height the words need
                              // (at large text they outgrow a fixed 260).
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/images/bg_noor.jpg',
                                  fit: BoxFit.cover,
                                ),
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
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(
                                      minHeight: 260,
                                      minWidth: double.infinity,
                                    ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 16, 20, 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      noor.when(
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
                                          Expanded(
                                            child: Text(
                                              '— ${entry.source.toUpperCase()}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  AppText.bodyMuted.copyWith(
                                                fontSize: 12,
                                                color: AppColors.gold,
                                              ),
                                            ),
                                          ),
                                          SpeakButton(
                                            text:
                                                '${entry.english} ${entry.prompt}',
                                            size: 32,
                                            minTapTarget:
                                                SpeakButton.minTarget,
                                          ),
                                          _ShareNoorButton(entry: entry),
                                        ],
                                      ),
                                    ],
                                  ),
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
                        for (int i = 0; i < reflections.length; i++)
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
                                      reflections[i],
                                      style: AppText.body.copyWith(height: 1.5),
                                    ),
                                  ),
                                  IconButton(
                                    key: Key('reflection-delete-$i'),
                                    tooltip: 'Delete reflection',
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.sand.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    onPressed: () => _confirmDelete(i),
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

/// Copies today's NOOR (Arabic, translation, source) so it can be pasted into
/// a message, and says so. A 48dp tap target around the 32dp circle.
class _ShareNoorButton extends StatelessWidget {
  const _ShareNoorButton({required this.entry});

  final NoorEntry entry;

  Future<void> _copy(BuildContext context) => shareWithFeedback(
        context,
        composeShareText(
          arabic: entry.arabic,
          body: entry.english,
          source: entry.source,
        ),
        title: 'Today\u2019s NOOR',
      );

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copy today’s NOOR to share',
      child: Semantics(
      button: true,
      label: 'Copy today’s NOOR to share',
      excludeSemantics: true,
      onTap: () => _copy(context),
      child: FocusableTap(
        key: const Key('noor-share'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _copy(context),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.night.withValues(alpha: 0.4),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.share_outlined,
                size: 16,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
