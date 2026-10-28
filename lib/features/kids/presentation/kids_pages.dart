import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../academy/presentation/wasia_lessons.dart'
    show WasiaAiCaption, WasiaAskBox;

/// What a child is told about who can see what. The words follow
/// `children_privacy.dart` (the parent sees the nickname, the age band, the
/// lessons finished and the exam scores; nobody sees what is typed to Wasia).
/// If that text changes, change this one in the same commit.
///
/// CHILD-PROTECTION and CLINICIAN REVIEW NEEDED (`support.kids-grownups-page`).
const List<String> kGrownupsCanSee = <String>[
  'A grown-up who looks after this app can see your nickname, which lessons you have finished, and your scores in the little tests.',
  'They cannot see what you type to Wasia, or what you say when Wasia asks how you are.',
  'Wasia does not keep what you say. Wasia cannot tell anyone for you, and the app does not tell anyone.',
];

const List<String> kGrownupsAdvice = <String>[
  'If something is making you sad or scared, or someone is hurting you, the best thing is to tell a grown-up you trust: a parent, a teacher, an aunt or uncle. You can tell them more than once, until someone listens.',
  'If you do not know who to tell, press “Need to talk to someone?” on the Kids Corner page. It shows people you can call or text who help children.',
  'Nothing in this app is a secret from the grown-ups who keep you safe. If someone asks you to keep a secret that makes you feel bad, you do not have to.',
];

/// /kids/grownups — for the child. Short words, big text.
class KidsGrownupsScreen extends StatelessWidget {
  const KidsGrownupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: <Widget>[
        const ScenicBackground.pattern(),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'What grown-ups can see', showSettings: false),
              const SizedBox(height: 8),
              Text('What can grown-ups see?',
                  style: AppText.titleMedium.copyWith(fontSize: 22)),
              const SizedBox(height: 10),
              GlassCard(
                strong: true,
                key: const Key('grownups-see'),
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  for (final String l in kGrownupsCanSee)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(l, style: AppText.body.copyWith(fontSize: 17, height: 1.5)),
                    ),
                ]),
              ),
              const SizedBox(height: 18),
              Text('If something is wrong',
                  style: AppText.titleMedium.copyWith(fontSize: 22)),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  for (final String l in kGrownupsAdvice)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(l, style: AppText.body.copyWith(fontSize: 17, height: 1.5)),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              for (final String l in supportReviewLabels('support.kids-grownups-page', 'support.kids-grownups-page'))
                Text(l, style: AppText.caption.copyWith(color: AppColors.gold)),
            ],
          ),
        ),
      ]),
    );
  }
}

/// /kids/ask — Ask Wasia from Kids Corner, not only at the end of the
/// letters lesson. Same box, same on-device answers, same safety replies.
class KidsAskWasiaScreen extends ConsumerWidget {
  const KidsAskWasiaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(children: <Widget>[
        const ScenicBackground.pattern(),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Ask Wasia', showSettings: false),
              const SizedBox(height: 8),
              GlassCard(
                strong: true,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text('ASK WASIA', style: AppText.eyebrow),
                  const SizedBox(height: 6),
                  const WasiaAiCaption(),
                  const WasiaAskBox(),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
