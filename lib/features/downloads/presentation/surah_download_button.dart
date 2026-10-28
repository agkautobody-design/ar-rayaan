import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../application/download_manager.dart';
import '../domain/download_catalog.dart';

/// "Download recitation" for one surah, in the Qur'an reader. Uses the
/// reciter the person chose; the status is read back from the device, and
/// the full list (juz, whole Qur'an, delete) is on the Downloads screen.
class SurahDownloadButton extends ConsumerWidget {
  const SurahDownloadButton({required this.surah, super.key});

  final int surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DownloadsState s = ref.watch(downloadsProvider);
    final AudioPack pack = AudioCatalog.of(s.reciter).surahs[surah - 1];
    final PackPhase phase = s.audioPhase(pack);
    final int done = s.countStored(pack.refs);
    final DownloadsController c = ref.read(downloadsProvider.notifier);

    late final String label;
    late final String tip;
    late final IconData icon;
    VoidCallback? onTap;
    switch (phase) {
      case PackPhase.downloaded:
        label = 'Recitation downloaded';
        tip =
            'This surah’s recitation is on this device. Open Downloads '
            'to delete it.';
        icon = Icons.download_done_outlined;
        onTap = () => context.open('/downloads');
      case PackPhase.downloading:
      case PackPhase.queued:
        label = 'Downloading $done of ${pack.refs.length}';
        tip = 'Downloading this surah’s recitation. Open Downloads.';
        icon = Icons.downloading_outlined;
        onTap = () => context.open('/downloads');
      case PackPhase.paused:
        label = 'Download paused';
        tip = 'Resume this surah’s recitation download.';
        icon = Icons.play_arrow;
        onTap = c.resume;
      case PackPhase.failed:
        label = 'Download stopped. Try again';
        tip = s.failed[pack.id] ?? 'Try the download again.';
        icon = Icons.refresh;
        onTap = () => c.download(pack.id);
      case PackPhase.partial:
        label = 'Finish downloading ($done of ${pack.refs.length})';
        tip = 'Download the rest of this surah’s recitation.';
        icon = Icons.download_outlined;
        onTap = () => c.download(pack.id);
      case PackPhase.notDownloaded:
      case PackPhase.included:
        label = 'Download recitation';
        tip =
            'Save this surah’s recitation (${s.reciter.displayName}, '
            'about ${formatBytes(pack.estimatedBytes)}) to listen with no '
            'internet.';
        icon = Icons.download_outlined;
        onTap = () => c.download(pack.id);
    }

    return Tooltip(
      message: tip,
      child: TextButton.icon(
        key: const Key('reader-download'),
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.gold,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
