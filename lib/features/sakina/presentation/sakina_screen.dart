import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/sakina_providers.dart';
import '../domain/sakina_content.dart';

/// Sakina — the soul of the app (crisis shell, Wave A4).
/// Locked look: hero word of mercy → rooms → comfort deck → human help.
/// The constitution: never diagnoses, never lectures, never shames;
/// human help is always on screen.
class SakinaScreen extends ConsumerWidget {
  const SakinaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int daysReturned = ref.watch(daysReturnedProvider);
    final ComfortCard todaysComfort = ComfortCards.deck[
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays %
            ComfortCards.deck.length];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Sakina · سكينة'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // The door — the founder's covenant to every hurting user.
                  GlassCard(
                    strong: true,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text(
                          'This space was built by a founder who has stood '
                          'where you are standing — and is still walking the '
                          'road. No judgment lives here. Only the door back.',
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
                            fontSize: 9,
                            color: AppColors.gold.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
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
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_outline,
                              size: 15,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TALK TO A HUMAN — ANYTIME',
                              style: AppText.eyebrow.copyWith(
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sakina is a companion, not a clinician. Real people '
                          'are ready to listen right now:',
                          style: AppText.caption.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 10),
                        for (final HelpResource r in HelpResources.all) ...[
                          _HelpRow(resource: r),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SAKINA DOES NOT DIAGNOSE · YOUR CHECK-INS AND VISITS '
                    'NEVER LEAVE THIS DEVICE · YOU ARE LOVED BY THE ONE WHO '
                    'MADE YOU',
                    style: AppText.eyebrow.copyWith(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      fontSize: 8.5,
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

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});

  final SakinaRoom room;

  @override
  Widget build(BuildContext context) {
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
                        color: AppColors.sand.withValues(alpha: 0.6),
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'FULL PATHWAY · IN CLINICIAN + SCHOLAR REVIEW',
                style: AppText.eyebrow.copyWith(
                  fontSize: 8,
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.resource});

  final HelpResource resource;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        final RegExp digits = RegExp(r'[\d-]{7,}');
        final Match? m = digits.firstMatch(resource.contact);
        if (m != null) {
          launchUrl(Uri.parse('tel:${m.group(0)}'));
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${resource.name} · ${resource.region}',
                  style: AppText.caption.copyWith(
                    color: AppColors.sand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  resource.detail,
                  style: AppText.caption.copyWith(
                    color: AppColors.sand.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  resource.contact,
                  style: AppText.caption.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
