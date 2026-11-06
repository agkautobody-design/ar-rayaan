import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../hadi/application/hadi_controller.dart';
import '../../sakina/presentation/widgets/need_help_button.dart';
import 'privacy_shield.dart';

/// How Hādi opens when the person comes from the "I need help" page. Fixed
/// words, never sent anywhere; the message is marked sensitive and is never
/// written to the device. CLINICIAN / SCHOLAR REVIEW NEEDED.
const String kNeedHelpOpener =
    'As-salamu alaikum wa rahmatullah. I am here, and I am listening — all '
    'of it, at your pace. Nothing you say here is saved or sent anywhere; '
    'it stays between you and this page. You will get no judgment from me '
    'and no lecture: the Prophet \uFDFA met people in their worst moments '
    'with mercy first, and that is the way here. Tell me what is weighing '
    'on you, or simply how today feels — as much or as little as you like. '
    'And when you want it, I can share what Islam gives us for healing: a '
    'du\u2019a, a verse, one small step for tonight. Where would you like '
    'to begin?';

/// A starting sentence the person can tap instead of finding their own
/// words. Each opens Hādi with the sentence already sent, phrased as a
/// disclosure ("I feel…") so the listening side of Hādi answers, not the
/// ruling shelf.
class _StartingPoint {
  const _StartingPoint(this.slug, this.title, this.blurb, this.sentence);

  final String slug;
  final String title;
  final String blurb;
  final String sentence;
}

const List<_StartingPoint> _startingPoints = <_StartingPoint>[
  _StartingPoint(
    'heard',
    'I just need to be heard',
    'No advice, no fixing — just say it.',
    'I just need someone to hear me. I do not want advice yet, I just need '
        'to say it to someone who will not judge me.',
  ),
  _StartingPoint(
    'far-from-allah',
    'I feel far from Allah',
    'Distant, numb, or ashamed to come back.',
    'I feel far from Allah and it hurts. I do not know how to come back.',
  ),
  _StartingPoint(
    'habit',
    'A habit I hate keeps pulling me back',
    'Without shame. Slips are part of the road.',
    'I am struggling with a habit I hate and I feel ashamed. I keep going '
        'back to it and I do not want to.',
  ),
  _StartingPoint(
    'heavy',
    'I feel anxious or heavy most days',
    'Tired of carrying it alone.',
    'I feel anxious and heavy most days, and I am tired of carrying it '
        'alone.',
  ),
  _StartingPoint(
    'home',
    'Things at home are hurting me',
    'Family, marriage, or the people closest.',
    'Things at home are hurting me and I do not know what to do.',
  ),
  _StartingPoint(
    'lost-someone',
    'I have lost someone',
    'Grief has its own pace here.',
    'I have lost someone I love and the pain does not leave.',
  ),
];

/// /i-need-help — a page built around being heard. Not a phone number: the
/// door opens straight into a conversation with Hādi, who listens first and
/// answers with the healing of Islam. The help lines exist here too, one
/// quiet line at the bottom, for the person in danger right now.
class NeedHelpScreen extends ConsumerWidget {
  const NeedHelpScreen({super.key});

  Future<void> _talkToHadi(BuildContext context, WidgetRef ref) async {
    await ref
        .read(hadiControllerProvider.notifier)
        .openFromSupport(kNeedHelpOpener);
    if (context.mounted) context.open(AppRoutes.hadi);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(children: <Widget>[
        const ScenicBackground.pattern(),
        SafeArea(
          child: Column(children: <Widget>[
            const ScreenHeader(title: 'I Need Help', showSettings: false),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: QuickExitButton(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('YOU DO NOT HAVE TO CARRY IT ALONE',
                            style: AppText.eyebrow
                                .copyWith(color: AppColors.gold)),
                        const SizedBox(height: 8),
                        Text(
                          'Whatever weighs on you — you do not have to '
                          'explain it to a person before you are ready. Hādi '
                          'is here to hear you: no judgment, no lecture, and '
                          'nothing saved or sent. When you want it, he '
                          'answers with the healing of Islam — the Qur\u2019an, '
                          'du\u2019a, and the mercy the Prophet \uFDFA showed '
                          'people in their hardest moments.',
                          style: AppText.body.copyWith(height: 1.55),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            key: const Key('need-help-talk'),
                            onPressed: () => _talkToHadi(context, ref),
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 18),
                            label: const Text('Talk to Hādi — he will listen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: const Color(0xFF0A0F18),
                              minimumSize: const Size(48, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('OR START FROM WHAT IS CLOSEST',
                      style: AppText.eyebrow.copyWith(color: AppColors.gold)),
                  const SizedBox(height: 8),
                  for (final _StartingPoint p in _startingPoints)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        key: Key('need-help-chip-${p.slug}'),
                        onTap: () =>
                            context.open(AppRoutes.hadiAsk(p.sentence)),
                        semanticsLabel: '${p.title}. ${p.blurb}',
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(p.title,
                                    style:
                                        AppText.body.copyWith(fontSize: 15)),
                                Text(p.blurb,
                                    style: AppText.bodyMuted
                                        .copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    child: TextButton.icon(
                      key: const Key('need-help-lines'),
                      onPressed: () => showNeedHelpSheet(context),
                      icon: const Icon(Icons.phone_outlined,
                          size: 14, color: AppColors.goldLight),
                      label: const Text(
                          'In danger right now? Help lines near you'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.goldLight,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  Align(
                    child: TextButton(
                      key: const Key('need-help-more'),
                      onPressed: () => context.open(AppRoutes.support),
                      child: const Text('More support pages',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...supportReviewLabels('support.need-help', 'support.need-help')
                      .map((String l) => Text(l, style: AppText.caption)),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
