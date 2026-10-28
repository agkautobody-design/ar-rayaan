/// The one place every outgoing share is built and sent.
///
/// A share can only be made from a [ShareDoc], and a [ShareDoc] can only be
/// made for one of the PUBLIC content kinds in [ShareKind]. There is no
/// "share this string" function: anything that is not on the list cannot be
/// shared by construction.
///
/// Never shareable, and never imported here (a test scans for it): anything
/// about the person (profile, location, saved or favourite lists, notes,
/// progress, counts), family or children data, chats (Hadi, Wasia, Sakina),
/// support or crisis content, prayer times, and games.
///
/// Rules every template follows:
///  * Qur'an Arabic comes only from the Qur'an registry (`quran.json`), never
///    typed here, and no translation is shared until its licence is settled.
///  * The fixed label "Scholar review needed" travels with every religious
///    text that carries it (see `lib/app/core/scholar_review.dart`).
///  * Every share ends with [shareFooter]: the credit, "Free to use, no
///    account needed" and one fixed link. No query, no referral, no tracking.
///  * No Arabic literal lives in this file.
library;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';

import '../../../app/core/scholar_review.dart';
import '../../quran/domain/quran_models.dart';
import 'share_text.dart';
import 'web_share.dart';

/// Every kind of thing that may be shared. This is the allow-list: a new
/// kind needs a change here AND in `test/share_service_test.dart`.
enum ShareKind {
  ayah,
  hadith,
  dua,
  dhikr,
  story,
  treePerson,
  lesson,
  calendarOccasion,
  mosque,
  halalPlace,
  guide,
  invite,
}

/// Credit for the Arabic of an ayah. The translation is not shared.
const String kAyahArabicCredit = 'Arabic: Tanzil Uthmani (tanzil.net).';

/// Map data credit, required by the OpenStreetMap licence (ODbL).
const String kOsmAttribution =
    'Map data: OpenStreetMap contributors (openstreetmap.org/copyright)';

/// The halal wording. The tag is community data and is never a certificate.
String halalTagLine({required bool fullyHalal}) =>
    '${fullyHalal ? 'Tagged fully halal' : 'Tagged halal'} in community map '
    'data — confirm before eating, in shaa Allah.';

/// A link to the place on openstreetmap.org. It carries the place's own
/// public coordinates, never the sender's.
String osmPlaceLink(double lat, double lon) {
  final String la = lat.toStringAsFixed(5);
  final String lo = lon.toStringAsFixed(5);
  return 'https://www.openstreetmap.org/?mlat=$la&mlon=$lo#map=18/$la/$lo';
}

/// One thing to share. Built only through the named constructors below, one
/// per allowed [ShareKind]. Holds public content and nothing else.
class ShareDoc {
  const ShareDoc._({
    required this.kind,
    this.title,
    this.arabic,
    this.body = '',
    this.source,
    this.extras = const <String>[],
    this.carriesReview = false,
    this.reviewKey,
  });

  final ShareKind kind;
  final String? title;

  /// Arabic exactly as the app's own data holds it. For the Qur'an it comes
  /// from the registry only.
  final String? arabic;
  final String body;

  /// Printed as `— source`.
  final String? source;

  /// Extra blocks after the source (a map link, an attribution, a caveat).
  final List<String> extras;

  /// True for religious teaching: the review label is added.
  final bool carriesReview;

  /// The scholar-review register id of the content, when it has one.
  final String? reviewKey;

  /// Qur'an Arabic from the registry for ayah [from] (to [to]) of [surah].
  /// No translation.
  factory ShareDoc.ayah({
    required String surahName,
    required int surah,
    required int from,
    int? to,
    required String arabic,
  }) =>
      ShareDoc._(
        kind: ShareKind.ayah,
        arabic: arabic,
        source: to == null || to == from
            ? '$surahName $surah:$from'
            : '$surahName $surah:$from-$to',
        extras: const <String>[kAyahArabicCredit],
      );

  factory ShareDoc.hadith({
    String? title,
    String? arabic,
    required String english,
    String? source,
    required String reviewKey,
  }) =>
      ShareDoc._(
        kind: ShareKind.hadith,
        title: title,
        arabic: arabic,
        body: english,
        source: source,
        carriesReview: true,
        reviewKey: reviewKey,
      );

  factory ShareDoc.dua({
    required String title,
    String? arabic,
    required String meaning,
    String? when,
    String? source,
    required String reviewKey,
  }) =>
      ShareDoc._(
        kind: ShareKind.dua,
        title: title,
        arabic: arabic,
        body: when == null || when.trim().isEmpty
            ? meaning
            : '$meaning\n\nWhen: ${when.trim()}',
        source: source,
        carriesReview: true,
        reviewKey: reviewKey,
      );

  factory ShareDoc.dhikr({
    required String title,
    String? arabic,
    required String translation,
    String? source,
    required String reviewKey,
  }) =>
      ShareDoc._(
        kind: ShareKind.dhikr,
        title: title,
        arabic: arabic,
        body: translation,
        source: source,
        carriesReview: true,
        reviewKey: reviewKey,
      );

  /// A story or khutbah chapter. [source] already carries the story's
  /// honesty label when it is not "Established".
  factory ShareDoc.story({
    required String title,
    String? arabic,
    required String body,
    String? source,
    required String reviewKey,
  }) =>
      ShareDoc._(
        kind: ShareKind.story,
        title: title,
        arabic: arabic,
        body: body,
        source: source,
        carriesReview: true,
        reviewKey: reviewKey,
      );

  /// One person in the Messengers' Tree. Words only: no image, ever.
  factory ShareDoc.treePerson({
    required String name,
    required String era,
    required String label,
    required String description,
    String? lineage,
    String? lineageNote,
    List<String> sources = const <String>[],
  }) =>
      ShareDoc._(
        kind: ShareKind.treePerson,
        title: name,
        body: <String>[
          '$era · $label',
          description,
          if (lineage != null && lineage.trim().isNotEmpty) lineage.trim(),
          if (lineageNote != null && lineageNote.trim().isNotEmpty)
            'How we know this link: ${lineageNote.trim()}',
        ].join('\n\n'),
        source: sources.isEmpty ? null : sources.join('; '),
        carriesReview: true,
      );

  /// What a lesson teaches: its own text. Never that anyone did, finished or
  /// is studying it.
  factory ShareDoc.lesson({
    required String title,
    String? arabic,
    required String body,
    String? source,
    String? note,
    required String reviewKey,
  }) =>
      ShareDoc._(
        kind: ShareKind.lesson,
        title: title,
        arabic: arabic,
        body: body,
        source: source,
        extras: <String>[
          if (note != null && note.trim().isNotEmpty) note.trim(),
        ],
        carriesReview: true,
        reviewKey: reviewKey,
      );

  /// A public occasion in the Islamic calendar: its name, the date line the
  /// screen prints, how firmly it is established, and its source. Never a
  /// personal reminder.
  factory ShareDoc.calendarOccasion({
    required String name,
    required String dateLine,
    required String basis,
    String? about,
    String? source,
    required String reviewKey,
  }) =>
      ShareDoc._(
        kind: ShareKind.calendarOccasion,
        title: name,
        body: <String>[
          dateLine,
          basis,
          if (about != null && about.trim().isNotEmpty) about.trim(),
          'Dates follow the Umm al-Qura calendar; confirm by local moon '
              'sighting.',
        ].join('\n\n'),
        source: source,
        carriesReview: true,
        reviewKey: reviewKey,
      );

  /// A mosque from open map data: name, address, a link to the place on
  /// OpenStreetMap, and the attribution. No phone, no distance, no hours,
  /// nothing about the person sharing.
  factory ShareDoc.mosque({
    required String name,
    String? address,
    required double lat,
    required double lon,
  }) =>
      ShareDoc._(
        kind: ShareKind.mosque,
        title: name,
        body: _cleanAddress(address) ?? '',
        extras: <String>[osmPlaceLink(lat, lon), kOsmAttribution],
      );

  /// A restaurant tagged halal in open map data. Always carries the "confirm
  /// before eating" line; never a bare claim that the food is halal.
  factory ShareDoc.halalPlace({
    required String name,
    String? cuisine,
    String? address,
    required double lat,
    required double lon,
    bool fullyHalal = false,
  }) =>
      ShareDoc._(
        kind: ShareKind.halalPlace,
        title: name,
        body: <String>[
          if (cuisine != null && cuisine.trim().isNotEmpty) cuisine.trim(),
          if (_cleanAddress(address) != null) _cleanAddress(address)!,
        ].join('\n'),
        extras: <String>[
          halalTagLine(fullyHalal: fullyHalal),
          osmPlaceLink(lat, lon),
          kOsmAttribution,
        ],
      );

  /// A guide entry: its title, its steps and its sources.
  factory ShareDoc.guide({
    required String title,
    String? subtitle,
    required List<String> steps,
    List<String> sources = const <String>[],
    required String reviewKey,
  }) =>
      ShareDoc._(
        kind: ShareKind.guide,
        title: title,
        body: <String>[
          if (subtitle != null && subtitle.trim().isNotEmpty) subtitle.trim(),
          for (int i = 0; i < steps.length; i++) '${i + 1}. ${steps[i].trim()}',
        ].join('\n\n'),
        source: sources.isEmpty ? null : sources.join('; '),
        carriesReview: true,
        reviewKey: reviewKey,
      );

  /// The neutral invitation. Nothing personal.
  factory ShareDoc.invite() => const ShareDoc._(
        kind: ShareKind.invite,
        body: 'Ar-Rayaan: Qur’an, adhkar and Islamic learning in one '
            'place. You are welcome to try it.',
      );
}

/// "12 Main St, Springfield," becomes "12 Main St, Springfield"; empty
/// becomes null.
String? _cleanAddress(String? raw) {
  if (raw == null) return null;
  String s = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  s = s.replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '');
  return s.isEmpty ? null : s;
}

abstract final class ShareService {
  /// Builds the exact text that will be shown in the preview and sent.
  static String build(
    ShareDoc doc, {
    Map<String, ScholarSignoff> ledger = kScholarSignoffs,
  }) {
    assert(ShareKind.values.contains(doc.kind));
    bool has(String? s) => s != null && s.trim().isNotEmpty;
    final List<String> blocks = <String>[
      if (has(doc.title)) doc.title!.trim(),
      if (has(doc.arabic)) doc.arabic!.trim(),
      if (has(doc.body)) doc.body.trim(),
      if (has(doc.source)) '— ${doc.source!.trim()}',
      for (final String e in doc.extras)
        if (has(e)) e.trim(),
      if (doc.carriesReview)
        scholarReviewText(
          doc.reviewKey ?? 'share.${doc.kind.name}',
          ledger: ledger,
        ),
      shareFooter(),
    ];
    return blocks.join('\n\n');
  }

  /// The text of the neutral invitation.
  static String inviteText() => build(ShareDoc.invite());

  /// The Qur'an Arabic for ayah [from] (to [to]) of [surah], read from the
  /// registry list [all] (`quranAllProvider`). Null when the reference is not
  /// a real ayah range.
  static ShareDoc? ayahFromRegistry(
    List<Surah> all,
    int surah,
    int from, [
    int? to,
  ]) {
    if (surah < 1 || surah > all.length) return null;
    final Surah s = all[surah - 1];
    final int end = to ?? from;
    if (from < 1 || end < from || end > s.ayahs.length) return null;
    final String arabic = s.ayahs
        .sublist(from - 1, end)
        .map((Ayah a) => a.arabic.trim())
        .join(' ');
    return ShareDoc.ayah(
      surahName: s.meta.transliteration,
      surah: surah,
      from: from,
      to: end == from ? null : end,
      arabic: arabic,
    );
  }

  /// True when there is a real share sheet: the browser's on the web, the
  /// system's on Android and iOS.
  static bool get hasShareSheet => webShareSupported || !kIsWeb;

  /// Replaced in tests. Returns true when the system sheet was shown.
  @visibleForTesting
  static Future<bool> Function(String text, String? subject) nativeShare =
      _plusShare;

  static Future<bool> _plusShare(String text, String? subject) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the share sheet for [doc], or copies when there is none or it
  /// fails, and says which. Call it straight from the tap: a browser only
  /// allows its share sheet from one.
  static Future<void> send(BuildContext context, ShareDoc doc) async {
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    final String text = build(doc);
    if (kIsWeb) {
      if (webShareSupported && await webShare(text, title: doc.title)) return;
    } else {
      if (await nativeShare(text, doc.title)) return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      _say(messenger, kShareCopyBlockedMessage);
      return;
    }
    _say(messenger, kShareCopiedMessage);
  }

  static void _say(ScaffoldMessengerState? messenger, String message) {
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Shown after a copy.
const String kShareCopiedMessage = 'Copied. Paste it into any message.';

/// Shown when the browser or device refused the clipboard.
const String kShareCopyBlockedMessage =
    'Could not copy automatically. Select the text and copy it by hand.';
