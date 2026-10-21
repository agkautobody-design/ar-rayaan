import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

/// How Ar-Rayaan treats religious content: what is quoted from where, how
/// hadith are graded, how earlier accounts are labelled and kept apart, and
/// the plain fact that no named scholar has reviewed the app yet.
///
/// The wording is deliberately fixed in code (not fetched) so it cannot be
/// changed remotely, and `test/content_policy_test.dart` pins the claims.
class ContentPolicyScreen extends StatelessWidget {
  const ContentPolicyScreen({super.key});

  /// The honest review status, shown on this page and reusable elsewhere.
  static const String reviewStatus = 'Not yet scholar-reviewed';

  /// Fixed badge text for anything from before the Qur’an era or from the
  /// People of the Book.
  static const String earlierBadge = 'Not from the Qur’an';

  static const List<(String, List<String>)> sections = <(String, List<String>)>[
    (
      'Review status',
      <String>[
        '$reviewStatus. No named scholar has reviewed this app yet. We '
            'check every citation we can, we say so when we cannot, and we '
            'will name a reviewer here only once one has agreed to be named.',
      ],
    ),
    (
      'The Qur’an',
      <String>[
        'The Arabic is the Tanzil Uthmani text bundled in the app and shown '
            'exactly as supplied. Qur’an is never quoted from memory, and '
            'never produced by an AI.',
        'The English is Saheeh International, as supplied by Tanzil, with '
            'its own punctuation. It is a translation of the meaning, not '
            'the Qur’an itself.',
      ],
    ),
    (
      'Hadith',
      <String>[
        'We draw on the six books (Kutub al-Sittah). Sahih al-Bukhari and '
            'Sahih Muslim are cited by book and number.',
        'Abu Dawud, at-Tirmidhi, an-Nasa’i and Ibn Majah are shown with the '
            'grade and who gave it. Their grades differ between scholars, so '
            'we never show a bare “sahih”.',
        'Anything outside the six must name the text it comes from, or it '
            'is labelled, or it is removed. If a citation cannot be checked '
            'we drop the number and the grade and say it is “reported”.',
      ],
    ),
    (
      'Labels you will see',
      <String>[
        'Qur’an · Hadith (with grade and grader) · Seerah report · '
            'Scholarly explanation · Reflection · Disputed in the sources.',
        'A reflection is our own thinking and is not evidence. Where '
            'scholars differ we say that they differ.',
      ],
    ),
    (
      'Earlier accounts',
      <String>[
        'Accounts from before the Qur’an era, and material from the People '
            'of the Book, sit apart and carry the badge “$earlierBadge”.',
        'We sort them in three: confirmed by our sources; silent, where we '
            'neither believe nor disbelieve (Sahih al-Bukhari 4485); and '
            'contradicted, which we leave out. Relating such accounts is '
            'permitted (Sahih al-Bukhari 3461).',
      ],
    ),
    (
      'Rulings',
      <String>[
        'A ruling names the published scholar or fatwa body it comes from. '
            'Without one, we say “ask a scholar”. The app does not issue '
            'fatwas, and an AI answer is never a fatwa.',
      ],
    ),
    (
      'No images of prophets',
      <String>[
        'No image of any prophet appears anywhere in Ar-Rayaan, in any '
            'screen, card or lesson.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ScenicScaffold.pattern(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const ScreenHeader(title: 'How we handle religious content'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  for (final (String, List<String>) section in sections) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 14, bottom: 8),
                      child: Semantics(
                        header: true,
                        child: Text(
                          section.$1.toUpperCase(),
                          style: AppText.eyebrow.copyWith(fontSize: 12),
                        ),
                      ),
                    ),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (int i = 0; i < section.$2.length; i++) ...<Widget>[
                            if (i > 0) const SizedBox(height: 10),
                            Text(
                              section.$2[i],
                              style: AppText.body.copyWith(height: 1.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    reviewStatus.toUpperCase(),
                    style: AppText.eyebrow.copyWith(
                      fontSize: 12,
                      color: AppColors.gold.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
