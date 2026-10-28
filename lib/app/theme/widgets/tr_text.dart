import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as m show Text;

import '../../core/i18n/bidi.dart';
import '../../core/i18n/ui_phrases.dart';

/// The language code the screen is shown in; `en` when there is no
/// Localizations above [context] (a bare test widget).
String uiLang(BuildContext context) =>
    Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

/// [english] in the language of the screen when the phrase table has it,
/// otherwise [english] unchanged. See ui_phrases.dart for the rules (nothing
/// that quotes scripture is ever translated; every ar/ur/bn phrase is a
/// machine draft that a native speaker still has to check).
String trUi(BuildContext context, String english) =>
    translatePhrase(english, uiLang(context));

extension UiTranslate on BuildContext {
  /// Shorthand for [trUi].
  String tr(String english) => trUi(this, english);
}

/// A clock time such as "4:39 AM" that keeps its order inside a right-to-left
/// sentence ("4:39 AM", never "AM 4:39").
String clockText(BuildContext context, String formatted) =>
    kPhraseRtl.contains(uiLang(context)) ? isolateLtr(formatted) : formatted;

/// Drop-in replacement for Flutter's [m.Text] (files import material with
/// `hide Text` and this file). It does two things Flutter's Text does not:
///  * a string that is in the phrase table is shown in the screen's language
///    (Arabic, Urdu or Bangla); anything else is shown as written;
///  * Latin-script text on a right-to-left screen is laid out left-to-right,
///    so a full stop or question mark stays at the end of an English
///    sentence and a time such as "4:39 AM" keeps its order.
/// It builds an ordinary Flutter Text underneath, so finders, semantics and
/// selection behave as before.
class Text extends StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final String? d = data;
    if (d == null) {
      return m.Text.rich(
        textSpan!,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    final String lang = uiLang(context);
    final String shown = lang == 'en' ? d : translatePhrase(d, lang);
    TextDirection? dir = textDirection;
    TextAlign? align = textAlign;
    if (dir == null &&
        Directionality.maybeOf(context) == TextDirection.rtl &&
        startsWithLatin(shown)) {
      dir = TextDirection.ltr;
      if (align == null || align == TextAlign.start) {
        align = TextAlign.right;
      } else if (align == TextAlign.end) {
        align = TextAlign.left;
      }
    }
    return m.Text(
      shown,
      style: style,
      strutStyle: strutStyle,
      textAlign: align,
      textDirection: dir,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel == null || lang == 'en'
          ? semanticsLabel
          : translatePhrase(semanticsLabel!, lang),
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

/// The "Native-speaker review needed" label. Shown on screens that carry
/// support, safety or religious content when the screen is in Arabic, Urdu or
/// Bangla, because every phrase in those languages is a machine draft.
/// Renders nothing in English. With [safety] it also says that some lines
/// stay in English until they have been checked.
class NativeReviewNote extends StatelessWidget {
  const NativeReviewNote({super.key, this.safety = false, this.inset = false});

  final bool safety;

  /// Adds the 20px side gutter for screens whose column has no padding.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final String lang = uiLang(context);
    if (!hasPhraseLanguage(lang)) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: 'Native-speaker review needed',
      child: Container(
        key: const Key('native-review-note'),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: inset ? 20 : 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x66C9A24B)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            m.Text(
              translatePhrase('Native-speaker review needed', lang),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            m.Text(
              translatePhrase(
                  'This translation is a machine draft. A native speaker has not checked it yet.',
                  lang),
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
            if (safety) ...<Widget>[
              const SizedBox(height: 2),
              m.Text(
                translatePhrase(
                    'Some lines on this screen are still in English until a native speaker has checked them. If you are in danger, call your local emergency number.',
                    lang),
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
            const SizedBox(height: 2),
            const m.Text(
              'Native-speaker review needed',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
