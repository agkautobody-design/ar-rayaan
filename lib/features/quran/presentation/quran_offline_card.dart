import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content_loader.dart';
import '../../../app/core/web_offline.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../application/quran_offline.dart';

/// "Save Qur'an for offline": says whether the Qur'an opens with no internet
/// and, in the browser, saves it to this device with visible progress.
///
/// [compact] is the hint on the Qur'an screen: it shows only while there is
/// something to do (web, not saved yet, saving, or a failed attempt) and is
/// otherwise empty. The full card lives in Settings and always shows.
class QuranOfflineCard extends ConsumerWidget {
  const QuranOfflineCard({this.compact = false, this.web, super.key});

  final bool compact;

  /// Forces the web or phone wording (defaults to the running platform).
  final bool? web;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool onWeb = web ?? WebOffline.isWeb;
    final QuranSaveState save = ref.watch(quranOfflineSaveProvider);
    // Unknown (still checking) counts as "not stored" only for the button.
    final bool stored =
        ref.watch(quranOfflineReadyProvider).valueOrNull ?? false;
    final bool done =
        save.phase == QuranSavePhase.saved ||
        (save.phase == QuranSavePhase.idle && stored);
    final bool saving = save.phase == QuranSavePhase.saving;

    if (compact && (!onWeb || done)) return const SizedBox.shrink();

    final String message = quranOfflineMessage(
      save.phase,
      web: onWeb,
      alreadyStored: stored,
    );
    final bool canSave = onWeb && !saving && !done;
    final String label =
        save.phase == QuranSavePhase.failed ||
            save.phase == QuranSavePhase.notKept ||
            save.phase == QuranSavePhase.offline
        ? 'Try again'
        : 'Save Qur’an for offline';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                done || !onWeb
                    ? Icons.download_done_outlined
                    : Icons.download_for_offline_outlined,
                size: 20,
                color: AppColors.gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Read the Qur’an offline',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: AppText.bodyMuted.copyWith(height: 1.5),
            ),
          ),
          if (saving) ...<Widget>[
            const SizedBox(height: 12),
            Semantics(
              label: 'Saving the Qur\u2019an',
              value: '${save.done} of ${save.total} files',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: save.fraction,
                  minHeight: 6,
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('${save.done} of ${save.total} files', style: AppText.caption),
          ],
          if (canSave) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.gold,
              ),
              onPressed: () =>
                  ref.read(quranOfflineSaveProvider.notifier).save(),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}
