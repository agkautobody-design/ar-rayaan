import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/backend/community_providers.dart';
import '../../../app/core/backend/models.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/community_state.dart';
import 'community_widgets.dart';

/// The words for a notification. The server sends only a short code and ids;
/// the app writes the sentence, so no one's text travels in a notification.
String notificationText(AppNotification n) {
  switch (n.kind) {
    case 'forum_reply':
      return 'Someone replied to your thread.';
    case 'friend_request':
      return 'You have a new friend request.';
    case 'friend_accepted':
      return 'A friend request was accepted.';
    case 'post_approved':
      return 'A moderator approved your post. It is now visible.';
    case 'meetup_approved':
      return 'Your meet-up was approved and is now published.';
    case 'meetup_cancelled':
      return 'A meet-up you signed up for was cancelled.';
    case 'meetup_reminder':
      return 'A meet-up you are going to is coming up.';
    case 'meetup_waitlist_promoted':
      return 'A place opened up. You are now signed up.';
    case 'moderation_action':
      return 'A moderator made a decision about your content. '
          'Open it to read why.';
    case 'appeal_decided':
      return 'Your appeal has been answered.';
    case 'credential_verified':
      return 'Your verification was approved.';
    case 'credential_revoked':
      return 'Your verification was withdrawn.';
    default:
      return 'You have an update.';
  }
}

/// Where tapping a notification goes, or null for none.
String? notificationRoute(AppNotification n) {
  final Object? thread = n.payload['threadId'];
  final Object? meetup = n.payload['meetupId'];
  switch (n.kind) {
    case 'forum_reply':
      return thread is String ? '${AppRoutes.communityThread}/$thread' : null;
    case 'friend_request':
    case 'friend_accepted':
      return AppRoutes.communityFriends;
    case 'meetup_approved':
    case 'meetup_cancelled':
    case 'meetup_reminder':
    case 'meetup_waitlist_promoted':
      return meetup is String ? '${AppRoutes.communityMeetup}/$meetup' : null;
    case 'moderation_action':
    case 'appeal_decided':
      return AppRoutes.communityNotices;
    default:
      return null;
  }
}

/// Notifications, fetched when the screen opens and when you pull to refresh.
/// There are no push notifications in this phase.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityGate(
      title: 'Notifications',
      needsProfile: false,
      actions: <HeaderAction>[
        HeaderAction(
          icon: Icons.done_all,
          tooltip: 'Mark all as read',
          onTap: () async {
            await runAction<void>(
              context,
              () => ref.read(communityApiProvider).markAllNotificationsRead(),
            );
            ref.invalidate(notificationsProvider);
          },
        ),
      ],
      builder: (BuildContext c, MeResponse me) {
        return AsyncBody<NotificationPage>(
          value: ref.watch(notificationsProvider),
          onRetry: () => ref.invalidate(notificationsProvider),
          builder: (BuildContext c, NotificationPage page) {
            if (page.notifications.isEmpty) {
              return const MessageView(
                icon: Icons.notifications_none,
                title: 'Nothing new',
                message: 'Replies, friend requests and meet-up news appear here.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsProvider);
                await ref.read(notificationsProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: <Widget>[
                  for (final AppNotification n in page.notifications)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        strong: n.unread,
                        padding: const EdgeInsets.all(14),
                        onTap: () async {
                          await runAction<void>(
                            context,
                            () => ref
                                .read(communityApiProvider)
                                .markNotificationsRead(ids: <String>[n.id]),
                          );
                          ref.invalidate(notificationsProvider);
                          final String? r = notificationRoute(n);
                          if (r != null && context.mounted) context.open(r);
                        },
                        child: Row(
                          children: <Widget>[
                            if (n.unread)
                              const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(
                                  Icons.circle,
                                  size: 9,
                                  color: AppColors.gold,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    notificationText(n),
                                    style: AppText.body,
                                  ),
                                  Text(
                                    timeAgo(n.createdAt),
                                    style: AppText.bodyMuted.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// What moderators did about you, with the reason, and a way to appeal. This
/// works even while an account is limited.
class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityGate(
      title: 'Moderation Notices',
      needsProfile: false,
      builder: (BuildContext c, MeResponse me) {
        return AsyncBody<ModerationInfo>(
          value: ref.watch(myModerationProvider),
          onRetry: () => ref.invalidate(myModerationProvider),
          builder: (BuildContext c, ModerationInfo info) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: <Widget>[
                Text(
                  info.strikePoints == 0
                      ? 'Your record is clear.'
                      : 'You have ${info.strikePoints} strike '
                            '${info.strikePoints == 1 ? 'point' : 'points'}. '
                            'They expire after a while.',
                  style: AppText.body,
                ),
                if (info.accountStatus != 'active')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Your account is ${info.accountStatus}.',
                      style: AppText.body.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (info.actions.isEmpty)
                  Text(
                    'Nothing to show. Decisions about your posts appear here '
                    'with the reason.',
                    style: AppText.bodyMuted,
                  ),
                for (final ModerationNotice a in info.actions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NoticeCard(notice: a),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _NoticeCard extends ConsumerStatefulWidget {
  const _NoticeCard({required this.notice});

  final ModerationNotice notice;

  @override
  ConsumerState<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends ConsumerState<_NoticeCard> {
  final TextEditingController _statement = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _statement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ModerationNotice a = widget.notice;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${_actionWord(a.action)} · ${timeAgo(a.createdAt)}',
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(a.reason, style: AppText.body),
          if (a.appealStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Appeal: ${a.appealStatus}',
                style: AppText.bodyMuted,
              ),
            )
          else if (a.appealable) ...<Widget>[
            const SizedBox(height: 6),
            if (!_open)
              TextButton(
                onPressed: () => setState(() => _open = true),
                child: const Text('Appeal this decision'),
              )
            else ...<Widget>[
              Semantics(label: 'Tell us what you think we got wrong', child: TextField(
                controller: _statement,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'Tell us what you think we got wrong',
                ),
              )),
              TextButton(
                onPressed: () async {
                  final bool? ok = await runAction<bool>(context, () async {
                    await ref
                        .read(communityApiProvider)
                        .appeal(a.id, _statement.text.trim());
                    return true;
                  }, done: 'Your appeal was sent. A different moderator will read it.');
                  if (ok == true) ref.invalidate(myModerationProvider);
                },
                child: const Text('Send appeal'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

String _actionWord(String action) {
  switch (action) {
    case 'hide':
      return 'Post hidden';
    case 'remove':
      return 'Post removed';
    case 'warn':
      return 'Warning';
    case 'mute':
      return 'Posting paused';
    case 'suspend':
      return 'Account suspended';
    case 'ban':
      return 'Account closed';
    case 'lock_thread':
      return 'Thread closed';
    default:
      return 'Decision';
  }
}
