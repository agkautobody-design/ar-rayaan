import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../quran/application/quran_snippets.dart';
import '../../quran/application/quran_translit.dart';
import 'arabic_block.dart';

/// "Are those who know equal to those who do not know?" (Qur'an 39:9) for the
/// Academy gate and home banner: the Arabic, its transliteration and the
/// meaning, all from the registry. If the registry cannot be read, only the
/// meaning and the reference are shown.
class KnowledgeVerseView extends ConsumerWidget {
  const KnowledgeVerseView({this.arabicSize = 20, super.key});

  final double arabicSize;

  /// The meaning line and reference when the Arabic is not available.
  static const String fallbackEnglish =
      'Are those who know equal to those who do not know?';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuranSnippet? v = ref.watch(quranSnippetsProvider).valueOrNull?['knowledge'];
    if (v == null) {
      return Text(
        '“$fallbackEnglish” — Qur’an 39:9',
        key: const Key('knowledge-verse-fallback'),
        textAlign: TextAlign.center,
        style: AppText.bodyMuted.copyWith(fontSize: 12),
      );
    }
    return Column(
      key: const Key('knowledge-verse'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ArabicBlock(
          arabic: v.arabic,
          translit: v.translit,
          meaning: v.english,
          needsReview: true,
          translitSource: 'quran-json',
          arabicSize: arabicSize,
          density: ArabicBlockDensity.compact,
          centered: true,
        ),
        const SizedBox(height: 4),
        Text(
          'Qur’an ${v.ref}',
          textAlign: TextAlign.center,
          style: AppText.bodyMuted.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

/// The Bismillah with its transliteration and meaning (same registry).
/// Shows the Arabic alone only if the registry cannot be read.
class BismillahView extends ConsumerWidget {
  const BismillahView({this.arabicSize = 26, this.centered = true, super.key});

  final double arabicSize;
  final bool centered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuranSnippet? v = ref.watch(quranSnippetsProvider).valueOrNull?['bismillah'];
    if (v == null) return const SizedBox.shrink();
    return ArabicBlock(
      key: const Key('bismillah-block'),
      arabic: v.arabic,
      translit: v.translit,
      meaning: v.english,
      needsReview: true,
      translitSource: 'quran-json',
      arabicSize: arabicSize,
      density: ArabicBlockDensity.compact,
      centered: centered,
    );
  }
}

/// Any named snippet from the registry ('increase' is 20:114, the last clause),
/// with its reference. Shows [fallback] if the registry cannot be read.
class QuranSnippetView extends ConsumerWidget {
  const QuranSnippetView({
    required this.name,
    this.arabicSize = 22,
    this.fallback,
    super.key,
  });

  final String name;
  final double arabicSize;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuranSnippet? v = ref.watch(quranSnippetsProvider).valueOrNull?[name];
    if (v == null) return fallback ?? const SizedBox.shrink();
    return Column(
      key: Key('quran-snippet-$name'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ArabicBlock(
          arabic: v.arabic,
          translit: v.translit,
          meaning: v.english,
          needsReview: true,
          translitSource: 'quran-json',
          arabicSize: arabicSize,
          density: ArabicBlockDensity.compact,
          centered: true,
        ),
        const SizedBox(height: 4),
        Text(
          'Qur’an ${v.ref}',
          textAlign: TextAlign.center,
          style: AppText.bodyMuted.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

/// Qur'an Arabic and meaning that the caller already has (from the registry),
/// with the transliteration of the ayah [ayahKey] ('2:255') added from the
/// dataset. If the dataset is not loaded the block says it is not available.
class QuranTranslitBlock extends ConsumerWidget {
  const QuranTranslitBlock({
    required this.arabic,
    required this.english,
    required this.ayahKey,
    this.arabicSize = 20,
    this.centered = false,
    this.density = ArabicBlockDensity.compact,
    super.key,
  });

  final String arabic;
  final String english;
  final String ayahKey;
  final double arabicSize;
  final bool centered;
  final ArabicBlockDensity density;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? tl = ref.watch(quranTranslitProvider).valueOrNull?[ayahKey];
    return ArabicBlock(
      arabic: arabic,
      translit: tl,
      meaning: english,
      needsReview: tl != null,
      translitSource: 'quran-json',
      arabicSize: arabicSize,
      density: density,
      centered: centered,
    );
  }
}
