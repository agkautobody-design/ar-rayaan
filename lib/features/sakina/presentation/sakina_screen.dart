import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/sakina_providers.dart';
import '../domain/sakina_content.dart';
import 'widgets/help_line_tile.dart';
import 'widgets/need_help_button.dart';

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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // The door.
                  GlassCard(
                    strong: true,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text(
                          'No judgment lives here. Only the door back.',
                          style: AppText.body.copyWith(
                            fontSize: 14,
                            height: 1.7,
                            color: AppColors.sand.withValues(alpha: 0.95),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                            ),
                            color: AppColors.gold.withValues(alpha: 0.08),
                          ),
                          child: Text(
                            daysReturned <= 1
                                ? 'Day 1 — you came back. That is everything.'
                                : 'Day $daysReturned — every return is a victory.',
                            style: AppText.caption.copyWith(
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(child: NeedHelpNowButton()),
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
                        avatar: const Icon(Icons.shield_outlined, size: 16),
                        label: const Text('My safety plan'),
                        onPressed: () => context.push(AppRoutes.sakinaSafety),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // The rooms.
                  Text(
                    'THE ROOMS',
                    style: AppText.eyebrow.copyWith(color: AppColors.gold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Each opens gently now; full guided pathways arrive after '
                    'clinician and scholar review.',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 10),
                  for (final SakinaRoom room in SakinaRooms.all) ...[
                    _RoomCard(room: room),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),

                  // Human help — always on screen, never buried.
                  _HelpSection(countryCode: ref.watch(deviceCountryProvider)),
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

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room});

  final SakinaRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? safety = room.safetyLine;
    final List<HelpResource> roomHelp = room.helpKinds.isEmpty
        ? const <HelpResource>[]
        : HelpResources.forCountry(
            ref.watch(deviceCountryProvider),
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
            if (safety != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                safety,
                style: AppText.caption.copyWith(
                  color: AppColors.sand.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ],
            for (final HelpResource r in roomHelp) ...<Widget>[
              const SizedBox(height: 8),
              HelpLineTile(resource: r),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'FULL PATHWAY · IN CLINICIAN + SCHOLAR REVIEW',
                style: AppText.eyebrow.copyWith(
                  fontSize: 12,
                  color: AppColors.gold.withValues(alpha: 0.9),
                ),
              ),
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
      for (final HelpResource r in HelpResources.all)
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
              Text(
                'TALK TO A HUMAN',
                style: AppText.eyebrow.copyWith(color: AppColors.gold),
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
