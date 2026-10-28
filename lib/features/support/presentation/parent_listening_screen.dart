import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import 'support_widgets.dart';

/// One block of the guide.
class ListeningSection {
  const ListeningSection(this.title, this.points);

  final String title;
  final List<String> points;
}

/// The source of the hadith in the faith line, from the app's hadith
/// register (tool/hadith_verdicts: both references have an `ok` verdict).
const String kListeningHadithSource =
    'Source: Sahih al-Bukhari 5997; Sahih Muslim 2318. Scholar review of the '
    'wording is still needed.';

/// "How to listen to a child who is hurting": for a parent whose child is
/// bullied, afraid of school, or has said something worrying. Plain words, no
/// diagnosis, no ruling. It points to the school, a doctor and child-protection
/// services, and never to blaming the child. (CLINICIAN AND SAFEGUARDING
/// REVIEW NEEDED; the Islamic line is for SCHOLAR REVIEW.)
const List<ListeningSection> kParentListeningSections = <ListeningSection>[
  ListeningSection('SIGNS TO NOTICE', <String>[
    'Not wanting to go to school, tummy aches or headaches on school mornings.',
    'Going quiet, crying more, sleeping badly, or being angry more often than usual.',
    'Things lost or broken, torn clothes, or a sudden wish to stop seeing a friend.',
    'Not wanting to use a phone or a game they used to love.',
    'None of these proves anything. They are a reason to ask gently.',
  ]),
  ListeningSection('HOW TO OPEN THE CONVERSATION', <String>[
    'Pick a calm moment side by side, in the car, walking, or at bedtime, not a face-to-face interview.',
    'Start small: “You have seemed quieter lately. I am not cross. I would like to understand.”',
    'Let them take their time. Silence is fine. You can come back to it tomorrow.',
    'If they will not talk to you, say that someone else is fine too: an aunt, a teacher, a school counsellor, or a child helpline.',
  ]),
  ListeningSection('WHAT TO SAY', <String>[
    '“Thank you for telling me.”',
    '“I believe you.”',
    '“It is not your fault.”',
    '“You are not in trouble.”',
    '“We will work out what to do together, and I will not do anything without telling you first.”',
  ]),
  ListeningSection('WHAT NOT TO SAY OR DO', <String>[
    'Do not ask “What did you do to make them?” or say “Just ignore it” or “Hit them back.”',
    'Do not promise to keep it secret. Promise to keep them safe.',
    'Do not storm into school or confront the other child or family in anger.',
    'Do not take away their phone or games as a punishment for telling you.',
    'Do not compare them with a brother, a sister or another child.',
  ]),
  ListeningSection('WHAT TO DO NEXT', <String>[
    'Write down what happened, when and who was there. Keep screenshots and messages.',
    'Ask the school for a meeting with the class teacher or the safeguarding lead. Ask what they will do and when you will hear back.',
    'If your child will not go to school at all, or the worry lasts weeks, speak to a doctor or the school counsellor early. Long absences usually make it harder.',
    'If your child is in danger, or someone is hurting them, call your country’s emergency number or a child-protection service.',
  ]),
  ListeningSection('IF THE HARM IS AT HOME OR FROM A TRUSTED PERSON', <String>[
    'If a child says someone at home or someone they know hurts or frightens them, believe them, stay calm, and do not confront the person in front of the child.',
    'Contact a child-protection service or a child helpline for advice before you act. They can help you make a safe plan.',
  ]),
  ListeningSection('A WORD FROM THE FAITH', <String>[
    'Abu Huraira reported that the Prophet (peace be upon him) kissed his grandson al-Hasan. A man said he had ten children and had never kissed any of them, and the Prophet said: whoever is not merciful will not be shown mercy. Listening to a hurting child is part of that mercy.',
    kListeningHadithSource,
  ]),
];

class ParentListeningScreen extends ConsumerWidget {
  const ParentListeningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(children: <Widget>[
        const ScenicBackground.pattern(),
        SafeArea(
          child: Column(children: <Widget>[
            const ScreenHeader(title: 'Listening to your child', showSettings: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  Text(
                    'For a parent whose child is being bullied, is afraid of school, '
                    'or has said something worrying. This is not a diagnosis and '
                    'not a replacement for a doctor, the school or a child-protection '
                    'service. Nothing here is saved.',
                    key: const Key('parent-listening-intro'),
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                  for (final ListeningSection sec in kParentListeningSections) ...<Widget>[
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
                  for (final String l in supportReviewLabels('support.parent-listening', 'support.parent-listening'))
                    Text(l, key: const Key('listening-review'), style: AppText.caption.copyWith(color: AppColors.gold)),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
