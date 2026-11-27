import '../../../app/core/scholar_review.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../hadi/application/hadi_controller.dart';
import '../../support/application/support_settings.dart';
import '../../support/presentation/need_help_screen.dart' show kNeedHelpOpener;
import '../../support/presentation/privacy_shield.dart';
import '../application/sakina_providers.dart';
import '../domain/sakina_content.dart';
import 'widgets/help_line_tile.dart';
import 'widgets/need_help_button.dart';

String _greeting(int daysReturned) {
  final int h = DateTime.now().hour;
  final String part = h < 5
      ? 'Still up?'
      : h < 12
          ? 'Good morning.'
          : h < 18
              ? 'Good afternoon.'
              : 'Good evening.';
  return daysReturned <= 1
      ? 'As-salamu alaikum. $part I’m Sakina.'
      : 'Welcome back. $part I’m glad you’re here.';
}

/// Small, human check-ins Hādi opens with. One is drawn each time Sakina is
/// opened (autoDispose resets on leave), so it never reads like a recording.
const List<String> kHadiCheckIns = <String>[
  'Hey, what’s on your mind today?',
  'How’s life treating you lately?',
  'How are you, really?',
  'Anything sitting heavy on you today?',
  'Tell me one good thing and one hard thing about today.',
  'What’s been taking up space in your head?',
  'How did you sleep? How’s your heart this morning?',
  'Long day? I’m here if you want to unload.',
  'What’s one thing you wish someone asked you today?',
  'How’s the family? How’s work? How are you in all of it?',
  'Quiet moment here. What would you like to say out loud?',
  'Not looking for anything in particular? That’s fine too. How are you?',
];

final AutoDisposeProvider<String> hadiCheckInProvider =
    Provider.autoDispose<String>((Ref ref) =>
        kHadiCheckIns[math.Random().nextInt(kHadiCheckIns.length)]);

/// Everyday starting points: (chip label, first-person sentence Hādi opens
/// with). Phrased as a disclosure so the listening side of Hādi answers.
const List<(String, String)> _everydayTopics = <(String, String)>[
  ('I can’t switch my mind off',
      'I am overthinking everything and I cannot switch my mind off, even at night.'),
  ('I’m stressed and overwhelmed',
      'I am so stressed and overwhelmed and I do not know where to start.'),
  ('I feel low or empty',
      'I feel low and empty and I do not know why.'),
  ('I’m lonely',
      'I feel lonely and I have no one to talk to.'),
  ('I’m angry a lot',
      'I get angry so fast and I hate who I am becoming.'),
  ('I’m exhausted',
      'I am exhausted from work and life and I have nothing left.'),
  ('My family is a lot right now',
      'My family does not understand me and home hurts right now. I need to talk about it.'),
  ('My marriage is hurting',
      'My marriage is hurting me. We keep having the same fight and I do not know how to reach them anymore.'),
  ('Money worries',
      'I am drowning in bills and debt and I cannot see a way through. I need to say it out loud to someone.'),
  ('Whispers and doubts',
      'The whispers and doubts will not leave me alone and I am worn out by them.'),
  ('I feel far from Allah',
      'I feel far from Allah and it hurts. I do not know how to come back.'),
  ('A habit keeps pulling me back',
      'I am struggling with a habit I hate and I feel ashamed. I keep going back to it and I do not want to.'),
  ('I just need to be heard',
      'I just need someone to hear me. I do not want advice yet, I just need to say it to someone who will not judge me.'),
];

/// Sakina — the soul of the app (crisis shell, Wave A4).
/// Locked look: hero word of mercy → rooms → comfort deck → human help.
/// The constitution: never diagnoses, never lectures, never shames;
/// human help is always on screen.
class SakinaScreen extends ConsumerWidget {
  const SakinaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int daysReturned = ref.watch(daysReturnedProvider);
    final List<ComfortCard> daily = ComfortCards.daily;
    final ComfortCard todaysComfort = daily[
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays %
            daily.length];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Sakina · سكينة'),
            const NativeReviewNote(safety: true, inset: true),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: QuickExitButton(),
            ),
            const ScholarReviewNote(
              reviewKey: 'sakina',
              padding: const EdgeInsets.only(bottom: 8),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // The door: Sakina speaks first, in her own voice.
                  GlassCard(
                    strong: true,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(daysReturned),
                          style: AppText.titleMedium.copyWith(
                            color: AppColors.sand,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ref.watch(hadiCheckInProvider),
                          style: AppText.body.copyWith(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: AppColors.sand,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hard day, slow day, or a day with nothing in '
                          'particular wrong: you can say it here. I listen '
                          'first. Then, if you want help, we work out one '
                          'small thing that makes today easier. No judgment, '
                          'no lecture.',
                          style: AppText.body.copyWith(
                            fontSize: 14.5,
                            height: 1.6,
                            color: AppColors.sand.withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('sakina-talk-hadi'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 52),
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.night,
                            ),
                            onPressed: () async {
                              await ref
                                  .read(hadiControllerProvider.notifier)
                                  .openFromSupport(kNeedHelpOpener);
                              if (context.mounted) context.open(AppRoutes.hadi);
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Talk to Hādi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Everyday starting points: tap one and Hādi opens with it.
                  Text(
                    'WHAT’S ON YOUR MIND?',
                    style: AppText.eyebrow.copyWith(color: AppColors.gold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap whatever is closest. You can change your mind once '
                    'we start talking.',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final (String, String) t in _everydayTopics)
                        ActionChip(
                          key: Key('sakina-topic-${t.$1}'),
                          label: Text(t.$1),
                          onPressed: () => context.open(AppRoutes.hadiAsk(t.$2)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Today's comfort card.
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A WORD FOR TODAY',
                          style: AppText.eyebrow.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '“${todaysComfort.text}”',
                          style: AppText.body.copyWith(
                            fontSize: 14.5,
                            height: 1.7,
                            color: AppColors.sand,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          todaysComfort.source,
                          style: AppText.eyebrow.copyWith(
                            fontSize: 12,
                            color: AppColors.gold.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Small tools. Everything stays on this device.
                  Text(
                    'FOR A HARD MOMENT',
                    style: AppText.eyebrow.copyWith(color: AppColors.gold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      // The du'a for an unquiet heart already lives in
                      // Dhikr & Du'a; this is the way to it from here.
                      ActionChip(
                        key: const Key('sakina-duas'),
                        avatar: const Icon(Icons.favorite_border, size: 16),
                        label: const Text('Duas for worry & peace'),
                        onPressed: () => context.push(
                          '${AppRoutes.storyReader}?id=dua-anxiety',
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.air, size: 16),
                        label: const Text('Steady yourself'),
                        onPressed: () => context.push(AppRoutes.sakinaSteady),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.edit_note, size: 16),
                        label: const Text('How are you today?'),
                        onPressed: () => context.push(AppRoutes.sakinaMood),
                      ),
                      ActionChip(
                        key: const Key('sakina-support-hub'),
                        avatar: const Icon(Icons.volunteer_activism_outlined,
                            size: 16),
                        label: const Text('Support & who to call'),
                        onPressed: () => context.push(AppRoutes.support),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.shield_outlined, size: 16),
                        label: const Text('My safety plan'),
                        onPressed: () => context.push(AppRoutes.sakinaSafety),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // The rooms.
                  Text(
                    'ROOMS FOR THE BIGGER THINGS',
                    style: AppText.eyebrow.copyWith(color: AppColors.gold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Each room has a few honest words, and a way to talk it '
                    'through with Hādi.',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 10),
                  for (final SakinaRoom room in SakinaRooms.all) ...[
                    _RoomCard(room: room),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),

                  // Human help: always one tap away at the bottom, and the
                  // quick exit stays at the top. Not the first thing here.
                  _HelpSection(countryCode: ref.watch(helpCountryProvider)),
                  const SizedBox(height: 12),
                  const Center(child: NeedHelpNowButton()),
                  const SizedBox(height: 16),
                  Text(
                    'SAKINA DOES NOT DIAGNOSE · YOUR CHECK-INS AND VISITS '
                    'NEVER LEAVE THIS DEVICE · YOU ARE LOVED BY THE ONE WHO '
                    'MADE YOU',
                    style: AppText.eyebrow.copyWith(
                      color: AppColors.gold.withValues(alpha: 0.9),
                      fontSize: 12,
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

/// What Hādi opens with when a person taps "Talk this through" in a room.
String _roomOpener(String roomId) => switch (roomId) {
      'quiet-war' =>
        'I am struggling with a habit I hate and I feel ashamed. I keep going back to it and I do not want to.',
      'marriage' =>
        'My marriage is hurting me. We keep having the same fight and I do not know how to reach them anymore.',
      'family' =>
        'My family does not understand me and home hurts right now. I need to talk about it.',
      'loss' => 'I have lost someone I love and the pain does not leave.',
      'son-father-husband' =>
        'I carry everything for everyone and I have nowhere to put it down. I need to say it to someone.',
      'whisper' =>
        'The whispers and doubts will not leave me alone and I am worn out by them.',
      _ => 'I just need someone to hear me.',
    };

/// The support page a room opens, for the rooms that have one.
String? _pathwayFor(String roomId) => switch (roomId) {
      'quiet-war' => AppRoutes.support,
      'marriage' => '${AppRoutes.support}/domestic-abuse',
      _ => null,
    };

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room});

  final SakinaRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? safety = room.safetyLine;
    final List<HelpResource> roomHelp = room.helpKinds.isEmpty
        ? const <HelpResource>[]
        : HelpResources.forCountry(
            ref.watch(helpCountryProvider),
            kinds: room.helpKinds,
          ).take(4).toList();
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          iconColor: AppColors.gold,
          collapsedIconColor: AppColors.gold.withValues(alpha: 0.5),
          title: Row(
            children: [
              Text(room.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: AppText.label.copyWith(color: AppColors.sand),
                    ),
                    Text(
                      room.subtitle,
                      style: AppText.caption.copyWith(
                        color: AppColors.sand.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            // Safety first: before any verse or word of comfort in a room
            // about a hard home, the line about being safe comes first.
            if (safety != null) ...<Widget>[
              Text(
                safety,
                key: Key('room-safety-${room.id}'),
                style: AppText.label.copyWith(
                  color: AppColors.sand,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              room.doorLine,
              style: AppText.body.copyWith(
                fontSize: 13.5,
                height: 1.7,
                color: AppColors.sand.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
            if (room.sources.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Quoted: ${room.sources}',
                style: AppText.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.gold.withValues(alpha: 0.9),
                ),
              ),
            ],
            for (final HelpResource r in roomHelp) ...<Widget>[
              const SizedBox(height: 8),
              HelpLineTile(resource: r),
            ],
            const SizedBox(height: 8),
            if (_pathwayFor(room.id) != null &&
                ref.watch(supportSettingsProvider).showSakina)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: Key('room-pathway-${room.id}'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => context.open(_pathwayFor(room.id)!),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Open the support pages'),
                ),
              ),
            if (room.id == 'marriage')
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('room-tools-marriage'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => context.open(AppRoutes.sakinaMarriage),
                  icon: const Icon(Icons.handshake_outlined, size: 18),
                  label: const Text('Two-way tools for hard seasons'),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: Key('room-talk-${room.id}'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => context.open(
                  AppRoutes.hadiAsk(_roomOpener(room.id)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Talk this through with Hādi'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Guidance in this room is still in clinician and scholar review.',
              style: AppText.caption.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "talk to a human" card: the lines for the person's country first,
/// every other country below, each tappable and copyable.
class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.countryCode});

  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    final List<HelpResource> near = HelpResources.forCountry(countryCode);
    final List<HelpResource> others = <HelpResource>[
      for (final HelpResource r in HelpResources.shown)
        if (!near.contains(r)) r,
    ];
    final bool knowsCountry = near.any(
      (HelpResource r) => r.countries.isNotEmpty,
    );
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.favorite_outline,
                size: 15,
                color: AppColors.gold,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'IF IT’S MORE THAN A ROUGH DAY',
                  style: AppText.eyebrow.copyWith(color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sakina is a companion, not a clinician. These are real people '
            'and services. Some lines answer day and night; others keep set '
            'hours. If you are in danger right now, call your local '
            'emergency number.',
            style: AppText.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          if (!knowsCountry)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'We could not tell which country you are in, so the lines '
                'for every country are listed below.',
                style: AppText.caption.copyWith(
                  color: AppColors.sand.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ),
          for (final HelpResource r in near) ...<Widget>[
            HelpLineTile(resource: r),
            const SizedBox(height: 8),
          ],
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: !knowsCountry,
              iconColor: AppColors.gold,
              collapsedIconColor: AppColors.gold.withValues(alpha: 0.6),
              title: Text(
                knowsCountry ? 'Other countries' : 'All countries',
                style: AppText.caption.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: <Widget>[
                for (final HelpResource r in others) ...<Widget>[
                  HelpLineTile(resource: r),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
