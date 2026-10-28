/// One layout for everything Arabic in the app: the Arabic, then its
/// transliteration (a reading aid), then its meaning.
///
/// Rules this widget keeps in one place:
///  * the Arabic is right to left (`lang ar`); the transliteration and the
///    meaning are left to right (`lang und-Latn` for the transliteration) even
///    on an Arabic, Urdu or Bangla screen;
///  * nothing is ever typed here: the text comes from a registry or dataset
///    and the caller passes it in;
///  * a missing transliteration is said, never invented;
///  * nothing is smaller than 12, and Elder Mode never goes below 18;
///  * in "Hide text / test me" the three layers are covered together.
library;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as m show Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../elder/application/elder_mode.dart';
import '../application/generated_translit.dart';
import '../application/reading_prefs.dart';

/// The colour of a transliteration line.
const Color kTranslitColor = Color(0xFFCFBE92);

/// Marks a text span as Latin letters for a screen reader and for font
/// choice. It is not English; it is Arabic written in Latin letters.
const Locale kLatinLocale = Locale.fromSubtags(
  languageCode: 'und',
  scriptCode: 'Latn',
);

/// Shown instead of a transliteration that does not exist yet.
const String kTranslitMissing = 'Transliteration not available yet';

/// How tight the block is.
enum ArabicBlockDensity {
  /// A list row: no "Meaning" label.
  compact,

  /// The normal layout.
  regular,
}

/// A transliteration line. Always left to right.
class TranslitLine extends StatelessWidget {
  const TranslitLine(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.centered = false,
  });

  final String text;
  final double fontSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        child: m.Text(
          text,
          key: const Key('arabic-block-translit'),
          textAlign: centered ? TextAlign.center : TextAlign.left,
          locale: kLatinLocale,
          semanticsLabel: 'Transliteration: $text',
          style: AppText.body.copyWith(
            fontSize: fontSize < 12 ? 12 : fontSize,
            height: 1.6,
            fontStyle: FontStyle.italic,
            color: kTranslitColor,
          ),
        ),
      ),
    );
  }
}

/// A meaning line, with its small label unless [compact].
class MeaningLine extends StatelessWidget {
  const MeaningLine(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.compact = false,
    this.rtl = false,
    this.centered = false,
  });

  final String text;
  final double fontSize;
  final bool compact;
  final bool centered;

  /// True for a translation that reads right to left (Urdu, Arabic).
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final double size = fontSize < 12 ? 12 : fontSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!compact)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: Text(
                'Meaning',
                style: AppText.eyebrow.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Align(
            alignment: centered
                ? Alignment.center
                : (rtl ? Alignment.centerRight : Alignment.centerLeft),
            child: m.Text(
              text,
              key: const Key('arabic-block-meaning'),
              textAlign: centered ? TextAlign.center : null,
              semanticsLabel: 'Meaning: $text',
              style: AppText.bodyMuted.copyWith(fontSize: size, height: 1.55),
            ),
          ),
        ),
      ],
    );
  }
}

/// The small "Scholar review needed" line under a machine-made or
/// author-made transliteration.
class TranslitReviewNote extends StatelessWidget {
  const TranslitReviewNote({super.key, this.source, this.centered = false});

  /// Where the transliteration came from, in a few words.
  final String? source;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final String s = source == null || source!.trim().isEmpty
        ? ''
        : ' · ${source!.trim()}';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        child: m.Text(
          '$kScholarReviewNeeded$s',
          key: const Key('arabic-block-review'),
          textAlign: centered ? TextAlign.center : null,
          style: AppText.caption.copyWith(fontSize: 12, height: 1.4),
        ),
      ),
    );
  }
}

/// The transliteration with its review note, either shown or behind a
/// "Read it" button, depending on [view]. [view] is never
/// [LayerView.hidden] here: a caller that hides the layer does not build this.
class TranslitLayer extends StatefulWidget {
  const TranslitLayer({
    required this.text,
    required this.view,
    this.fontSize = 14,
    this.needsReview = false,
    this.source,
    this.centered = false,
    super.key,
  });

  final String text;
  final LayerView view;
  final double fontSize;
  final bool needsReview;
  final String? source;
  final bool centered;

  @override
  State<TranslitLayer> createState() => _TranslitLayerState();
}

class _TranslitLayerState extends State<TranslitLayer> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final bool button = widget.view == LayerView.button;
    if (button && !_open) {
      return Align(
        alignment: widget.centered ? Alignment.center : Alignment.centerLeft,
        child: TextButton(
          key: const Key('arabic-block-read-it'),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: AppColors.goldLight,
          ),
          onPressed: () => setState(() => _open = true),
          child: const Text('Read it'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TranslitLine(
          widget.text,
          fontSize: widget.fontSize,
          centered: widget.centered,
        ),
        if (widget.needsReview)
          TranslitReviewNote(source: widget.source, centered: widget.centered),
        if (button)
          Align(
            alignment:
                widget.centered ? Alignment.center : Alignment.centerLeft,
            child: TextButton(
              key: const Key('arabic-block-hide-it'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.goldLight,
              ),
              onPressed: () => setState(() => _open = false),
              child: const Text('Hide it'),
            ),
          ),
      ],
    );
  }
}

/// Arabic, then transliteration, then meaning.
class ArabicBlock extends ConsumerStatefulWidget {
  const ArabicBlock({
    required this.arabic,
    this.translit,
    this.meaning,
    this.translitSource,
    this.meaningCredit,
    this.needsReview = false,
    this.arabicSize = 22,
    this.density = ArabicBlockDensity.regular,
    this.mastered = false,
    this.testMode = false,
    this.meaningRtl = false,
    this.showMissingNote = true,
    this.centered = false,
    super.key,
  });

  /// The Arabic, exactly as the dataset holds it.
  final String arabic;

  /// The transliteration from a registry or dataset, or null if there is none.
  final String? translit;

  /// The meaning in English, or null.
  final String? meaning;

  /// Short source of the transliteration, shown after "Scholar review needed".
  final String? translitSource;

  /// The credit line for the meaning, where the translation's terms ask for one.
  final String? meaningCredit;

  /// True when the transliteration is machine-made or unreviewed.
  final bool needsReview;

  final double arabicSize;
  final ArabicBlockDensity density;

  /// True when the person has mastered this item (Learning mode only).
  final bool mastered;

  /// True while "Hide text / test me" is on: all three layers are covered
  /// until the block is tapped.
  final bool testMode;

  final bool meaningRtl;

  /// Say "Transliteration not available yet" when there is none.
  final bool showMissingNote;

  /// Centre every line (a banner), instead of starting each at its own edge.
  final bool centered;

  @override
  ConsumerState<ArabicBlock> createState() => _ArabicBlockState();
}

class _ArabicBlockState extends ConsumerState<ArabicBlock> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final ReadingPrefs prefs = ref.watch(readingPrefsProvider);
    final bool elder = ref.watch(elderModeProvider);
    final bool compact = widget.density == ArabicBlockDensity.compact;

    if (widget.testMode && !_revealed) {
      return InkWell(
        key: const Key('arabic-block-covered'),
        onTap: () => setState(() => _revealed = true),
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          button: true,
          label: 'Hidden while you test yourself. Tap to show.',
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Hidden while you test yourself. Tap to show.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(fontSize: 12),
            ),
          ),
        ),
      );
    }

    final double tlSize = _size(widget.arabicSize * 0.62, elder, 13);
    final double enSize = _size(widget.arabicSize * 0.62, elder, 14);
    // A registry's own transliteration wins; otherwise a program-made one from
    // the generated file (labelled Scholar review needed), otherwise nothing.
    String? tlText = widget.translit;
    String? tlSource = widget.translitSource;
    bool tlReview = widget.needsReview;
    if (tlText == null || tlText.trim().isEmpty) {
      final Map<String, String>? gen =
          ref.watch(generatedTranslitProvider).valueOrNull;
      final String? hit = gen?[normaliseArabicKey(widget.arabic)];
      if (hit != null) {
        tlText = hit;
        tlSource = kGeneratedTranslitSource;
        tlReview = true;
      }
    }
    final bool hasTl = tlText != null && tlText.trim().isNotEmpty;
    final bool hasMeaning =
        widget.meaning != null && widget.meaning!.trim().isNotEmpty;

    LayerView tv = prefs.translit(mastered: widget.mastered);
    // Elder Mode keeps the transliteration in view (unless switched off).
    if (elder && tv == LayerView.button) tv = LayerView.shown;

    final List<Widget> kids = <Widget>[
      Directionality(
        textDirection: TextDirection.rtl,
        child: m.Text(
          widget.arabic,
          key: const Key('arabic-block-arabic'),
          locale: const Locale('ar'),
          textAlign: widget.centered ? TextAlign.center : null,
          style: AppText.arabicLarge.copyWith(
            fontSize: widget.arabicSize,
            height: 1.8,
          ),
        ),
      ),
    ];

    if (tv != LayerView.hidden) {
      if (!hasTl) {
        if (widget.showMissingNote) {
          kids
            ..add(const SizedBox(height: 4))
            ..add(
              Directionality(
                textDirection: TextDirection.ltr,
                child: Align(
                  alignment:
                      widget.centered ? Alignment.center : Alignment.centerLeft,
                  child: Text(
                    kTranslitMissing,
                    key: const Key('arabic-block-missing'),
                    style: AppText.caption.copyWith(fontSize: 12),
                  ),
                ),
              ),
            );
        }
      } else {
        kids
          ..add(const SizedBox(height: 4))
          ..add(
            TranslitLayer(
              text: tlText!.trim(),
              view: tv,
              fontSize: tlSize,
              needsReview: tlReview,
              source: tlSource,
              centered: widget.centered,
            ),
          );
      }
    }

    if (prefs.meaning == LayerView.shown && hasMeaning) {
      kids
        ..add(SizedBox(height: compact ? 4 : 8))
        ..add(
          MeaningLine(
            widget.meaning!.trim(),
            fontSize: enSize,
            compact: compact,
            rtl: widget.meaningRtl,
            centered: widget.centered,
          ),
        );
      final String? credit = widget.meaningCredit;
      if (credit != null && credit.trim().isNotEmpty) {
        kids.add(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment:
                  widget.centered ? Alignment.center : Alignment.centerLeft,
              child: m.Text(
                credit.trim(),
                style: AppText.caption.copyWith(fontSize: 12),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kids,
    );
  }

  /// [raw] scaled for the screen, never under 12, never under 18 in Elder Mode.
  static double _size(double raw, bool elder, double normalFloor) {
    final double floor = elder ? 18 : normalFloor;
    return raw < floor ? floor : raw;
  }
}
