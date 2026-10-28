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
import '../application/support_settings.dart';
import '../data/pack_repository.dart';
import '../domain/safe_replies.dart' show LeavingQuestion;
import '../domain/support_pack.dart';
import 'privacy_shield.dart';
import 'support_widgets.dart';

/// One support pathway: a pack, a help-line scope and plain words about it.
class SupportPathway {
  const SupportPathway(this.id, this.title, this.blurb, this.pack, this.scope, {this.urgent = false});

  final String id;
  final String title;
  final String blurb;
  final String pack;
  final String scope;

  /// A pathway where someone may be in danger now: the quick-exit button is
  /// shown first.
  final bool urgent;
}

const List<SupportPathway> kSupportPathways = <SupportPathway>[
  SupportPathway('domestic-abuse', 'Someone at home hurts or frightens me',
      'Safety first. You can leave this page at once.', 'domestic_abuse', 'domestic-abuse', urgent: true),
  SupportPathway('child-abuse', 'A child is being hurt or is afraid',
      'For a child, or for an adult worried about one.', 'child_abuse', 'child', urgent: true),
  SupportPathway('sexual-violence', 'Sexual violence',
      'What happened is not your fault.', 'sexual_violence', 'sexual-violence', urgent: true),
  SupportPathway('elder-abuse', 'An older person is being hurt or neglected',
      'For an older person, or someone who cares about one.', 'elder_abuse', 'elder', urgent: true),
  SupportPathway('alcohol', 'Alcohol', 'Cutting down, stopping, or a slip.', 'alcohol', 'addiction'),
  SupportPathway('drugs', 'Drugs and medicines', 'Safety information and who can help.', 'drugs', 'addiction'),
  SupportPathway('gambling', 'Gambling', 'Money, shame and a way forward.', 'gambling', 'gambling'),
  SupportPathway('porn', 'Pornography and compulsive habits',
      'Without shame, and without detail.', 'porn_compulsive', 'compulsive'),
  SupportPathway('smoking', 'Smoking and vaping', 'Wanting to quit, and how.', 'smoking_vaping', 'smoking'),
  SupportPathway('family', 'Someone close to me is struggling',
      'For the person who is worn out by loving them.', 'family_of_struggling', 'addiction-family'),
  SupportPathway('student', 'School and learning',
      'Hard days, bullying, worry and learning differences.', 'student_problems', 'child'),
];

/// How Hadi opens when the person comes from a support page: it knows which
/// page, says so in a line, and does not start with the general greeting.
/// Fixed words, never sent anywhere. CLINICIAN / SAFEGUARDING REVIEW NEEDED.
String hadiOpenerFor(SupportPathway? p) {
  if (p == null) {
    return 'I am here. You came from the Support pages. Tell me as much or as '
        'little as you like, and we can go at your pace.';
  }
  if (p.urgent) {
    return 'I can see you came from the page “${p.title}”. First: are you '
        'safe right now? If not, call your local emergency number, and use '
        '“Exit now” if someone may see this screen. If you are safe, tell me '
        'what is happening, as much or as little as you like. I will not '
        'push for details.';
  }
  return 'I can see you came from the page “${p.title}”. I am here to listen '
      'and to point you to people who can help; I am not a doctor or a '
      'counsellor. Where would you like to start?';
}

SupportPathway? pathwayById(String id) {
  for (final SupportPathway p in kSupportPathways) {
    if (p.id == id) return p;
  }
  return null;
}

/// /support — the list of pathways.
class SupportHubScreen extends ConsumerWidget {
  const SupportHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(children: <Widget>[
        const ScenicBackground.pattern(),
        SafeArea(
          child: Column(children: <Widget>[
            const ScreenHeader(title: 'Support', showSettings: false),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: QuickExitButton()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  Text(
                    'Nothing you read here is saved. These pages are not a doctor, a '
                    'counsellor or a scholar. They point to people who are.',
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  for (final SupportPathway p in kSupportPathways)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: () => context.open('${AppRoutes.support}/${p.id}'),
                        semanticsLabel: '${p.title}. ${p.blurb}',
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(p.title, style: AppText.body.copyWith(fontSize: 15)),
                                Text(p.blurb, style: AppText.bodyMuted.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18),
                        ]),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      key: const Key('support-hub-teachers'),
                      onTap: () => context.open(AppRoutes.teacherGuidance),
                      semanticsLabel: 'For teachers and mentors. What to do when a '
                          'student seems to be struggling or tells you something worrying.',
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('For teachers and mentors',
                                  style: AppText.body.copyWith(fontSize: 15)),
                              Text(
                                  'What to do when a student seems to be struggling or tells you something worrying.',
                                  style: AppText.bodyMuted.copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ]),
                    ),
                  ),
                  ...supportReviewLabels('support.pathways', 'support.pathways')
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

/// /support/<id> — one pathway, read from its pack.
class SupportPathwayScreen extends ConsumerWidget {
  const SupportPathwayScreen({required this.id, super.key});

  final String id;

  List<SupportSnippet> _of(SupportPack p, String kind, String lang, {int max = 8}) {
    final List<SupportSnippet> out = <SupportSnippet>[
      for (final SupportSnippet s in p.snippets)
        if (s.kind == kind &&
            s.matchesAge(p.audience == 'wasia' ? '9-12' : 'adult') &&
            (SupportPackRepository.allowDraft || s.shippable) &&
            s.text.isNotEmpty)
          s,
    ];
    return out.length > max ? out.sublist(0, max) : out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SupportPathway? path = pathwayById(id);
    final String lang = resolveSupportLanguage(
        ref.watch(supportSettingsProvider).language,
        Localizations.localeOf(context).languageCode);
    final SupportPack? pack = path == null ? null : SupportPackRepository.byName(path.pack);
    final bool expired = pack != null && pack.expiredAt(DateTime.now());

    Widget section(String title, List<SupportSnippet> snips, {bool fixed = false}) {
      if (snips.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
          child: Text(title, style: AppText.eyebrow),
        ),
        for (final SupportSnippet s in snips)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(s.textIn(lang), style: AppText.body.copyWith(fontSize: 14, height: 1.5)),
                if (s.sources.isNotEmpty) SupportProvenanceButton(ids: <String>[s.id]),
              ]),
            ),
          ),
      ]);
    }

    return Scaffold(
      body: Stack(children: <Widget>[
        const ScenicBackground.pattern(),
        SafeArea(
          child: Column(children: <Widget>[
            ScreenHeader(title: path?.title ?? 'Support', showSettings: false),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: QuickExitButton()),
            Expanded(
              child: path == null
                  ? Center(child: Text('That page is not here.', style: AppText.bodyMuted))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: <Widget>[
                        // Before any wording: if you are in danger, this
                        // comes first and is the same on every pathway about
                        // safety.
                        if (path.id == 'domestic-abuse')
                          GlassCard(
                            key: const Key('pathway-emergency-row'),
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'If you are in danger right now, call your local '
                              'emergency number. If it is not safe to talk, '
                              'leave this screen with “Exit now” above. You '
                              'do not have to decide anything tonight.',
                              style: AppText.body.copyWith(fontSize: 14),
                            ),
                          ),
                        if (pack == null || expired)
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'The wording for this page is not available right now. '
                              'The help lines below are still here.',
                              style: AppText.body.copyWith(fontSize: 14),
                            ),
                          )
                        else ...<Widget>[
                          section('START HERE', _of(pack, 'orient', lang, max: 2)),
                          section('IF IT IS URGENT', <SupportSnippet>[
                            ..._of(pack, 'safety', lang, max: 3),
                          ]),
                          section('GOOD TO KNOW', _of(pack, 'explain', lang)),
                          section('A SMALL STEP', _of(pack, 'plan-step', lang, max: 4)),
                          section('FOR FAMILY AND FRIENDS', _of(pack, 'family', lang, max: 3)),
                          section('PEOPLE TO TURN TO', _of(pack, 'referral', lang, max: 4)),
                          section('FAITH', _of(pack, 'islamic', lang, max: 4)),
                        ],
                        if (path.id == 'domestic-abuse') ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                            child: Text('THINKING ABOUT LEAVING, KHULA OR DIVORCE',
                                style: AppText.eyebrow),
                          ),
                          GlassCard(
                            key: const Key('pathway-leaving-section'),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(LeavingQuestion.pathwaySection,
                                style: AppText.body.copyWith(fontSize: 14, height: 1.5)),
                          ),
                        ],
                        SupportHelpLines(scope: path.scope),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('support-talk-to-hadi'),
                          onPressed: () async {
                            await ref
                                .read(hadiControllerProvider.notifier)
                                .openFromSupport(hadiOpenerFor(path));
                            if (context.mounted) context.open(AppRoutes.hadi);
                          },
                          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Talk it through with Hadi'),
                        ),
                        const SizedBox(height: 12),
                        for (final String l in supportReviewLabels('support.pathways', 'support.pathways'))
                          Text(l, key: const Key('pathway-review'), style: AppText.caption.copyWith(color: AppColors.gold)),
                        if (pack != null)
                          Text('Wording version ${pack.version}', style: AppText.caption),
                      ],
                    ),
            ),
          ]),
        ),
      ]),
    );
  }
}
