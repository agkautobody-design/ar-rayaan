import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../application/translation_providers.dart';
import '../data/translation_pack_loader.dart';
import '../domain/quran_texts.dart';
import '../domain/translation_pack.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// Settings > Qur'an translation: which translation the reader shows, its
/// credit and licence reference, and an honest note while the default (The
/// Clear Quran) text is still being added.
class QuranTranslationCard extends ConsumerWidget {
  const QuranTranslationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuranTexts texts =
        ref.watch(quranTextsProvider).value ?? QuranTexts.fallback;
    final ActiveTranslation? active = ref.watch(activeTranslationProvider).value;
    final String? chosen = ref.watch(translationSelectionProvider);
    final List<TranslationChoice> choices =
        ref.watch(availableTranslationsProvider).value ??
        const <TranslationChoice>[];
    final bool clearInstalled = choices.any(
      (TranslationChoice c) => c.id == kClearQuranId,
    );

    final List<Widget> rows = <Widget>[
      _Row(
        key: const Key('translation-default'),
        title: 'The Clear Quran (Dr. Mustafa Khattab), default',
        subtitle: clearInstalled
            ? 'English'
            : 'Not installed yet: its text is being added. Until then the '
                  'interim translation is shown.',
        // Only "selected" when its text is really what the reader shows.
        selected: chosen == null && clearInstalled,
        onTap: () {
          ref.read(translationSelectionProvider.notifier).choose(null);
          // The row looks like a choice but there is nothing to switch to
          // yet: say so instead of a tap that appears to do nothing.
          if (!clearInstalled) {
            ScaffoldMessenger.maybeOf(context)
              ?..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    'The Clear Quran text is not installed yet. The interim '
                    'translation keeps showing until it is.',
                  ),
                ),
              );
          }
        },
      ),
      for (final TranslationChoice c in choices)
        if (c.id != kClearQuranId)
          _Row(
            key: Key('translation-${c.id}'),
            title: c.title,
            subtitle: c.language.toUpperCase(),
            selected: chosen == c.id,
            onTap: () =>
                ref.read(translationSelectionProvider.notifier).choose(c.id),
          ),
      _Row(
        key: const Key('translation-interim'),
        title: 'Saheeh International (interim)',
        subtitle: 'English. Used only until the licensed text is in place.',
        selected:
            chosen == kInterimEnglishId || (chosen == null && !clearInstalled),
        onTap: () => ref
            .read(translationSelectionProvider.notifier)
            .choose(kInterimEnglishId),
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            active?.isInterim ?? true
                ? 'Showing: interim translation'
                : 'Showing: ${active!.pack!.title}',
            style: AppText.body,
          ),
          const SizedBox(height: 6),
          Text(
            '${texts.translation.note} Source: ${texts.translation.credit}.',
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: FocusRing(borderRadius: 12, child: InkWell(
        onTap: onTap,
        // The label above says it all; the words inside would be read a
        // second time (and make a second stop).
        child: ExcludeSemantics(child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: AppColors.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: AppText.body),
                      Text(subtitle, style: AppText.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )),
      )),
    );
  }
}
