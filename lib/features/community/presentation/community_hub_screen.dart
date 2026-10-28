import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/backend/models.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../application/community_state.dart';
import 'community_widgets.dart';

/// Forums, meet-ups, friends and invites in one place. Reached from the
/// Community tab only when the build has the community backend; the screen
/// also explains itself if someone arrives by a link without it.
class CommunityHubScreen extends ConsumerStatefulWidget {
  const CommunityHubScreen({super.key});

  /// How often the unread count is refreshed while this screen is open.
  /// There is no push in phase 2: the app asks.
  static const Duration pollEvery = Duration(seconds: 60);

  @override
  ConsumerState<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends ConsumerState<CommunityHubScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    if (ref.read(communityEnabledProvider)) {
      _poll = Timer.periodic(CommunityHubScreen.pollEvery, (Timer _) {
        if (mounted) ref.invalidate(notificationsProvider);
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommunityGate(
      title: 'Community',
      needsProfile: false,
      builder: (BuildContext c, MeResponse me) {
        final int unread =
            ref.watch(notificationsProvider).asData?.value.unreadCount ?? 0;
        final List<MeetupReminder> soon =
            ref.watch(meetupRemindersProvider).asData?.value ??
            <MeetupReminder>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Text(
              me.profile == null
                  ? 'Welcome'
                  : 'Salam, ${me.profile!.displayName}',
              style: AppText.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'For adults. Children never see the forums or meet-ups.',
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: 14),
            if (me.profile == null)
              _Tile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Create your profile',
                subtitle: 'Choose the name others will see',
                route: AppRoutes.communityForums,
              ),
            if (soon.isNotEmpty) ...<Widget>[
              for (final MeetupReminder r in soon)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    strong: true,
                    onTap: () => c.open('${AppRoutes.communityMeetup}/${r.meetupId}'),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: <Widget>[
                        const IconTile(icon: Icons.event_available_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Coming up: ${r.title}',
                                style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${formatWhen(r.startsAt)} · ${r.venueName}',
                                style: AppText.bodyMuted.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const _Tile(
              icon: Icons.forum_outlined,
              title: 'Forums',
              subtitle: 'Talk together, and ask a scholar',
              route: AppRoutes.communityForums,
            ),
            const _Tile(
              icon: Icons.event_outlined,
              title: 'Meet-ups',
              subtitle: 'In mosques and public places',
              route: AppRoutes.communityMeetups,
            ),
            const _Tile(
              icon: Icons.people_outline,
              title: 'Friends',
              subtitle: 'Requests and your friends',
              route: AppRoutes.communityFriends,
            ),
            const _Tile(
              icon: Icons.qr_code_2,
              title: 'Invite a friend',
              subtitle: 'A link or code, for a person you know',
              route: AppRoutes.communityInvite,
            ),
            _Tile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              subtitle: unread == 0 ? 'Nothing new' : '$unread new',
              route: AppRoutes.communityNotifications,
              badge: unread,
            ),
            const _Tile(
              icon: Icons.gavel_outlined,
              title: 'Community rules',
              subtitle: 'Our code of conduct',
              route: AppRoutes.communityRules,
            ),
            const _Tile(
              icon: Icons.block_outlined,
              title: 'Blocked people',
              subtitle: 'People you have blocked',
              route: AppRoutes.communityBlocked,
            ),
            const _Tile(
              icon: Icons.mark_email_unread_outlined,
              title: 'Moderation notices',
              subtitle: 'Decisions about you, and appeals',
              route: AppRoutes.communityNotices,
            ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => context.open(route),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            IconTile(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badge',
                  style: AppText.caption.copyWith(
                    color: AppColors.night,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.gold.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
