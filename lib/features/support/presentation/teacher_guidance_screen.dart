import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import 'parent_listening_screen.dart' show ListeningSection;
import 'support_widgets.dart';

/// For a teacher, madrasa or halaqa leader, or a mentor: what to do when a
/// young person in their care seems to be struggling, or says something
/// worrying. Guidance only. The app collects nothing about the young person,
/// stores nothing and sends nothing: this page is text on the device.
///
/// CLINICIAN, SAFEGUARDING and (for the faith line) SCHOLAR REVIEW NEEDED:
/// registered as `support.teacher-guidance`. Not legal advice: the duty to
/// report differs by country and by school, so the page sends the reader to
/// their own safeguarding lead.
const List<ListeningSection> kTeacherGuidanceSections = <ListeningSection>[
  ListeningSection('BEFORE ANYTHING ELSE', <String>[
    'Know who your safeguarding lead is, and your organisation’s policy. If you have none, ask for one: a child-protection service can tell you what the law asks of you where you live.',
    'You are not expected to investigate, to be sure, or to treat. You are expected to notice, to listen, and to pass it on to the right person.',
  ]),
  ListeningSection('WHAT YOU MIGHT NOTICE', <String>[
    'A student who has gone quiet, stopped joining in, cries, or is often tired, hungry or unwell.',
    'Bruises or injuries that do not fit the explanation, or a sudden fear of going home or of one person.',
    'A change that lasts more than a few days. None of these proves anything. They are a reason to ask gently and to write it down.',
  ]),
  ListeningSection('IF A YOUNG PERSON TELLS YOU SOMETHING', <String>[
    'Stay calm. Listen. Let them say it in their own words. Do not ask leading questions or make them repeat it.',
    'Tell them: “Thank you for telling me. I believe you. It is not your fault.”',
    'Do not promise to keep it secret. Promise to do everything you can to keep them safe, and say you may need to tell the people whose job it is to help.',
    'Do not confront the person they named, and do not contact the family before you have advice from your safeguarding lead or a child-protection service.',
    'If the child is in danger now, or needs medical care, call your local emergency number.',
  ]),
  ListeningSection('WRITE IT DOWN AND PASS IT ON', <String>[
    'Write what was said, in the child’s own words, with the date, the time and who was there. Keep it factual: what you saw and heard, not what you think it means.',
    'Give it to your safeguarding lead the same day, or call a child-protection line (below) if you have none.',
    'Keep it to the people who need to know. Do not discuss it in the staff room or in a group chat.',
  ]),
  ListeningSection('WHEN IT IS NOT AN EMERGENCY', <String>[
    'A student who seems low or worried: find a calm, private moment, side by side rather than face to face. “You have seemed quieter lately. I am not cross. I would like to understand.”',
    'Tell the parents or carers what you have noticed, unless you have a reason to think that would put the child at risk. If you do, speak to the safeguarding lead first.',
    'If a student talks about hurting themselves or not wanting to live, do not leave them alone, and get a trusted adult and the school’s lead now. The help lines below include crisis lines.',
  ]),
  ListeningSection('A WORD FROM THE FAITH', <String>[
    'Abu Huraira reported that the Prophet (peace be upon him) kissed his grandson al-Hasan. A man said he had ten children and had never kissed any of them, and the Prophet said: whoever is not merciful will not be shown mercy. Gentleness with a young person is part of the trust you have been given.',
    'Source: Sahih al-Bukhari 5997; Sahih Muslim 2318. Scholar review of the wording is still needed.',
  ]),
];

class TeacherGuidanceScreen extends ConsumerWidget {
  const TeacherGuidanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(children: <Widget>[
        const ScenicBackground.pattern(),
        SafeArea(
          child: Column(children: <Widget>[
            const ScreenHeader(title: 'For teachers and mentors', showSettings: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  Text(
                    'Guidance for a teacher, madrasa or halaqa leader, or a '
                    'mentor, when a young person seems to be struggling or '
                    'says something worrying. It is not legal advice, not a '
                    'diagnosis and not a replacement for your safeguarding '
                    'lead. This app collects nothing about the young person, '
                    'saves nothing and sends nothing.',
                    key: const Key('teacher-guidance-intro'),
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                  for (final ListeningSection sec in kTeacherGuidanceSections) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                      child: Text(sec.title, style: AppText.eyebrow),
                    ),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        for (final String p in sec.points)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $p', style: AppText.body.copyWith(fontSize: 14, height: 1.5)),
                          ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const SupportHelpLines(scope: 'child'),
                  const SizedBox(height: 12),
                  for (final String l in supportReviewLabels('support.teacher-guidance', 'support.teacher-guidance'))
                    Text(l, key: const Key('teacher-review'), style: AppText.caption.copyWith(color: AppColors.gold)),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
