/// Audio packs — download Al-Husary recitation per surah.
/// Wi-Fi recommended, on-device only, prune control for storage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/audio_packs_provider.dart';

class AudioPacksScreen extends ConsumerStatefulWidget {
  const AudioPacksScreen({super.key});

  @override
  ConsumerState<AudioPacksScreen> createState() => _AudioPacksScreenState();
}

class _AudioPacksScreenState extends ConsumerState<AudioPacksScreen> {
  int _tick = 0; // progress listener repaints

  @override
  void initState() {
    super.initState();
    ref.read(audioPacksProvider.notifier).addProgressListener(() {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Set<int> packs = ref.watch(audioPacksProvider);
    final AudioPacksNotifier notifier =
        ref.read(audioPacksProvider.notifier);

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const ScreenHeader(title: 'Audio Packs'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.wifi, color: AppColors.gold, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${packs.length} of 114 surahs downloaded · '
                          'Wi-Fi recommended · stored on this device only',
                          style: AppText.caption,
                        ),
                      ),
                      if (packs.length > 6)
                        TextButton(
                          onPressed: () => notifier.pruneTo(6),
                          child: Text('Keep 6',
                              style: AppText.caption
                                  .copyWith(color: AppColors.gold)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: AudioPacksNotifier.kAllSurahs.length,
                  itemBuilder: (context, i) {
                    final int surah = AudioPacksNotifier.kAllSurahs[i];
                    final bool has = packs.contains(surah);
                    final double prog = notifier.progressOf(surah);
                    final bool downloading = prog > 0 && prog < 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: GlassCard(
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                          dense: true,
                          leading: Text(
                            surah.toString().padLeft(3, '0'),
                            style: AppText.caption
                                .copyWith(color: AppColors.gold),
                          ),
                        ),
                          title: Text('Surah $surah', style: AppText.body),
                          subtitle: downloading
                              ? LinearProgressIndicator(
                                  value: prog,
                                  minHeight: 3,
                                  backgroundColor:
                                      AppColors.gold.withValues(alpha: 0.15),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppColors.gold),
                                )
                              : null,
                          trailing: has
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.gold, size: 20),
                                  onPressed: () => notifier.remove(surah),
                                )
                              : IconButton(
                                  icon: const Icon(
                                      Icons.download_for_offline_outlined,
                                      color: AppColors.gold,
                                      size: 20),
                                  onPressed: downloading
                                      ? null
                                      : () => notifier.download(surah),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
