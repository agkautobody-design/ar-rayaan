import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../application/test_me_provider.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// True while "Hide text / test me" is on and this ayah has not been tapped
/// open. The transliteration and the translation are covered with the Arabic:
/// a learner who reads the Latin letters would otherwise be handed the answer.
bool ayahIsCovered(WidgetRef ref, int surah, int ayah) {
  if (!ref.watch(testMeProvider)) return false;
  final String key = ayahKey(surah, ayah);
  return !ref.watch(
    revealedAyahsProvider.select((Set<String> s) => s.contains(key)),
  );
}

/// Shows [child] (the Arabic of one ayah) as it is, or, while "Hide text /
/// test me" is on, a quiet box that shows the ayah when tapped.
class HideableArabic extends ConsumerWidget {
  const HideableArabic({
    required this.surah,
    required this.ayah,
    required this.child,
    super.key,
  });

  final int surah;
  final int ayah;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hiding = ref.watch(testMeProvider);
    if (!hiding) return child;
    final String key = ayahKey(surah, ayah);
    final bool shown = ref.watch(
      revealedAyahsProvider.select((Set<String> s) => s.contains(key)),
    );
    if (shown) return child;
    void reveal() => ref.read(revealedAyahsProvider.notifier).state =
        <String>{...ref.read(revealedAyahsProvider), key};
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Ayah $ayah is hidden. Tap to show it.',
      onTap: reveal,
      child: FocusRing(borderRadius: 12, child: InkWell(
        key: Key('hidden-ayah-$ayah'),
        onTap: reveal,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Text(
            'Ayah $ayah · tap to show',
            style: AppText.bodyMuted.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      )),
    );
  }
}
