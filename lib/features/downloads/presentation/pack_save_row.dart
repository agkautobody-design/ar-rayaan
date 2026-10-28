import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../application/download_manager.dart';
import '../domain/download_catalog.dart';

/// "Save for offline" for a group of text packs, shown on the library
/// screens (Stories, Huda). It appears only in the browser: the phone apps
/// already carry this text inside the install, so there is nothing to save
/// and nothing is drawn.
class PackSaveRow extends ConsumerWidget {
  const PackSaveRow({required this.packIds, super.key});

  /// Ids from [kTextPackSpecs].
  final List<String> packIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(downloadTextBundledProvider)) return const SizedBox.shrink();
    final DownloadsState s = ref.watch(downloadsProvider);
    final DownloadsController c = ref.read(downloadsProvider.notifier);
    final List<TextPackSpec> specs = <TextPackSpec>[
      for (final String id in packIds)
        if (textPackById(id) != null) textPackById(id)!,
    ];
    final List<PackPhase> phases = <PackPhase>[
      for (final TextPackSpec t in specs) s.textPhase(t, bundled: false),
    ];
    final bool allSaved = phases.every(
      (PackPhase p) => p == PackPhase.downloaded,
    );
    final bool working = phases.any(
      (PackPhase p) =>
          p == PackPhase.downloading ||
          p == PackPhase.queued ||
          p == PackPhase.paused,
    );
    final bool failed = phases.any((PackPhase p) => p == PackPhase.failed);
    final int bytes = specs
        .where((TextPackSpec t) => !s.textStored.contains(t.id))
        .fold<int>(0, (int a, TextPackSpec t) => a + t.estimatedBytes);

    final String message = allSaved
        ? 'Saved in this browser: opens with no internet once the app is '
              'open.'
        : working
        ? 'Saving for offline…'
        : failed
        ? 'Could not save these. Check your connection and try again.'
        : 'Not saved yet: needs internet to read.';

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Icon(
            allSaved
                ? Icons.download_done_outlined
                : Icons.download_for_offline_outlined,
            size: 18,
            color: AppColors.gold,
          ),
          Text(message, style: AppText.bodyMuted),
          if (!allSaved && !working)
            TextButton(
              key: const Key('pack-save-row-save'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.gold,
              ),
              onPressed: () {
                for (final TextPackSpec t in specs) {
                  if (!s.textStored.contains(t.id)) c.download(t.id);
                }
              },
              child: Text(
                failed ? 'Try again' : 'Save (about ${formatBytes(bytes)})',
              ),
            ),
          TextButton(
            key: const Key('pack-save-row-open'),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: AppColors.gold,
            ),
            onPressed: () => context.open('/downloads'),
            child: const Text('All downloads'),
          ),
        ],
      ),
    );
  }
}
