/// The one "Scholar review needed" label, and the one place a sign-off lives.
///
/// Religious-content standard (Abdul, 20 and 27 Oct 2026): nothing in the app
/// is called scholar-reviewed until a NAMED scholar and a DATE are recorded.
/// None is recorded yet, so every teaching, ruling, hadith grade, story, dua,
/// lesson step, Hadi answer, guide, Q&A answer and health or Sakina note
/// carries [kScholarReviewNeeded].
///
/// How a label goes away, and only then:
///  * add one entry to [kScholarSignoffs] with the scholar's real name and the
///    ISO date of the review (a test refuses an entry that lacks either), or
///  * pass `reviewedBy` and `reviewedOn` straight from a data record that
///    carries them.
/// An entry applies to its key and to everything beneath it: the key
/// `huda.guide.huda-wudu` signs off one guide, `huda.guide` all guides,
/// `huda` the whole Huda library. The keys are the ids in
/// `tool/scholar_review/register.json` (see `docs/SCHOLAR_REVIEW_REGISTER.md`).
///
/// Never invent a reviewer. Never write a name here that the scholar has not
/// agreed to have shown.
library;

import 'package:flutter/material.dart' hide Text;
import '../theme/widgets/tr_text.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The fixed label. One wording everywhere.
const String kScholarReviewNeeded = 'Scholar review needed';

/// One sentence of context, for screens that have room for it.
const String kScholarReviewNeededDetail =
    'No named scholar has reviewed this yet. For a ruling, ask a scholar '
    'you trust.';

final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// A named scholar's review of one key (and everything beneath it).
class ScholarSignoff {
  const ScholarSignoff({required this.reviewedBy, required this.reviewedOn});

  /// The scholar's name, exactly as they agreed to have it shown.
  final String reviewedBy;

  /// ISO date, yyyy-mm-dd.
  final String reviewedOn;

  /// A sign-off counts only with a name and a date.
  bool get isComplete =>
      reviewedBy.trim().isNotEmpty && _isoDate.hasMatch(reviewedOn);

  String get label => 'Reviewed by ${reviewedBy.trim()} on $reviewedOn';
}

/// Sign-offs by register id. Empty today: no named scholar has reviewed
/// anything. `test/scholar_review_test.dart` checks every entry.
const Map<String, ScholarSignoff> kScholarSignoffs =
    <String, ScholarSignoff>{};

/// The sign-off that covers [key], looking at [key] first and then at each
/// parent (`a.b.c`, `a.b`, `a`). Null when nobody has signed off.
ScholarSignoff? scholarSignoffFor(
  String key, {
  Map<String, ScholarSignoff> ledger = kScholarSignoffs,
}) {
  String k = key;
  while (true) {
    final ScholarSignoff? s = ledger[k];
    if (s != null && s.isComplete) return s;
    final int dot = k.lastIndexOf('.');
    if (dot < 0) return null;
    k = k.substring(0, dot);
  }
}

/// The clinician's label. Same rule as the scholar's: it goes away only when
/// a NAMED clinician and a DATE are recorded in [kClinicianSignoffs]. Every
/// support screen, support-pack snippet and Hadi support reply carries both
/// labels until then. Never invent a reviewer.
const String kClinicianReviewNeeded = 'Clinician review needed';

/// One sentence of context for [kClinicianReviewNeeded].
const String kClinicianReviewNeededDetail =
    'No named clinician has reviewed this yet. It is support and '
    'information, not medical or mental-health care.';

/// Sign-offs by register id for support content. Empty today: no clinician
/// has been named. `test/scholar_review_test.dart` checks every entry.
const Map<String, ScholarSignoff> kClinicianSignoffs =
    <String, ScholarSignoff>{};

/// "Clinician review needed", or the clinician's sign-off for [key] (or a
/// parent key).
String clinicianReviewText(
  String key, {
  Map<String, ScholarSignoff> ledger = kClinicianSignoffs,
}) {
  final ScholarSignoff? s = scholarSignoffFor(key, ledger: ledger);
  return s == null ? kClinicianReviewNeeded : s.label;
}

/// The review labels a support reply or screen shows: the scholar's and the
/// clinician's, each either "needed" or the sign-off. Keys are register ids.
List<String> supportReviewLabels(String scholarKey, String clinicianKey) =>
    <String>[
      scholarReviewText(scholarKey),
      clinicianReviewText(clinicianKey),
    ];

/// The words to print for [key]: "Scholar review needed", or the sign-off.
/// A data record that carries [reviewedBy] and [reviewedOn] wins.
String scholarReviewText(
  String key, {
  String? reviewedBy,
  String? reviewedOn,
  Map<String, ScholarSignoff> ledger = kScholarSignoffs,
}) {
  if (reviewedBy != null && reviewedOn != null) {
    final ScholarSignoff own =
        ScholarSignoff(reviewedBy: reviewedBy, reviewedOn: reviewedOn);
    if (own.isComplete) return own.label;
  }
  final ScholarSignoff? s = scholarSignoffFor(key, ledger: ledger);
  return s == null ? kScholarReviewNeeded : s.label;
}

/// The register id of a story: `story.<pack>.<id>`, except the New Muslim
/// path (`new-muslim.<id>`) and the daily duas (`dua.daily.<id>`).
String storyReviewKey(String collection, String id) {
  switch (collection) {
    case 'newmuslim':
      return 'new-muslim.$id';
    case 'dailyduas':
      return 'dua.daily.$id';
    default:
      return 'story.$collection.$id';
  }
}

/// True while [key] still needs a scholar.
bool scholarReviewStillNeeded(
  String key, {
  String? reviewedBy,
  String? reviewedOn,
  Map<String, ScholarSignoff> ledger = kScholarSignoffs,
}) =>
    scholarReviewText(key,
        reviewedBy: reviewedBy, reviewedOn: reviewedOn, ledger: ledger) ==
    kScholarReviewNeeded;

/// A small, quiet note: "Scholar review needed". Read aloud as one sentence.
/// Becomes "Reviewed by NAME on DATE" only when a sign-off exists for
/// [reviewKey] (or one is passed in as [reviewedBy] and [reviewedOn]).
class ScholarReviewNote extends StatelessWidget {
  const ScholarReviewNote({
    super.key,
    required this.reviewKey,
    this.reviewedBy,
    this.reviewedOn,
    this.detail,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  /// Register id of what this note sits on.
  final String reviewKey;

  /// Optional sign-off carried by the data itself.
  final String? reviewedBy;
  final String? reviewedOn;

  /// Optional second sentence ([kScholarReviewNeededDetail] for example),
  /// shown only while the review is still needed.
  final String? detail;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final String text = scholarReviewText(reviewKey,
        reviewedBy: reviewedBy, reviewedOn: reviewedOn);
    final bool needed = text == kScholarReviewNeeded;
    final String? more = needed ? detail : null;
    final String spoken = more == null ? text : '$text. $more';
    return Padding(
      padding: padding,
      child: Semantics(
        container: true,
        label: spoken,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.rate_review_outlined,
                    size: 14, color: AppColors.sand),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  more == null ? text : '$text. $more',
                  style: AppText.caption.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.sand,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
