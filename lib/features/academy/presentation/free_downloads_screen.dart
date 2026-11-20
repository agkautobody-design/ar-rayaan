import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/core/open_link.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../domain/free_downloads.dart';

/// Names the recordings a person may download for themselves, and opens the
/// source's own page for each. Nothing is hosted, copied or re-served here.
class FreeDownloadsScreen extends ConsumerWidget {
  const FreeDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'Free downloads'),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'These recordings are offered for download by the sites '
                    'named below. Ar-Rayaan does not host or copy them: the '
                    'button opens the site\'s own page and you download your '
                    'own copy there, for yourself. Each site\'s terms apply, '
                    'and the rights stay with the people who made them.',
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final FreeDownload d in kFreeDownloads) ...<Widget>[
                GlassCard(
                  key: Key('dl-${d.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(d.title, style: AppText.titleMedium),
                        const SizedBox(height: 4),
                        Text(d.by, style: AppText.bodyMuted),
                        const SizedBox(height: 8),
                        Text(d.terms,
                            style: AppText.bodyMuted
                                .copyWith(fontSize: 12, height: 1.4)),
                        if (d.credit.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text('Credit: ${d.credit}',
                              style: AppText.bodyMuted
                                  .copyWith(fontSize: 12, height: 1.4)),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: OutlinedButton.icon(
                            key: Key('dl-open-${d.id}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.gold,
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: () => openLinkWithFeedback(
                                context, Uri.tryParse(d.pageUrl)),
                            icon: const Icon(Icons.download_outlined),
                            label: Text('Get it from ${d.source}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
