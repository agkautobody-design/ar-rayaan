import 'package:flutter/material.dart';
import '../../share/presentation/share_actions.dart' show copyWithFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/backend/backend_exception.dart';
import '../../../app/core/backend/community_providers.dart';
import '../../../app/core/backend/models.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../application/community_state.dart';
import 'community_widgets.dart';

/// Friends: people you know and chose. There is no messaging in phase 2, and
/// friendships never cross between adults and children.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _handle = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(friendListsProvider);

  Future<void> _ask() async {
    final String h = _handle.text.trim().toLowerCase().replaceFirst('@', '');
    if (h.isEmpty) return;
    setState(() => _busy = true);
    try {
      final bool? ok = await runAction<bool>(context, () async {
        await ref.read(communityApiProvider).requestFriend(h);
        return true;
      }, done: 'Request sent.');
      if (ok == true) {
        _handle.clear();
        _refresh();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunityGate(
      title: 'Friends',
      builder: (BuildContext c, MeResponse me) {
        return AsyncBody<FriendLists>(
          value: ref.watch(friendListsProvider),
          onRetry: _refresh,
          builder: (BuildContext c, FriendLists l) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Semantics(label: 'A friend’s exact handle', child: TextField(
                      controller: _handle,
                      decoration: const InputDecoration(
                        hintText: 'A friend’s exact handle',
                      ),
                      onSubmitted: (String _) => _ask(),
                    )),
                  ),
                  const SizedBox(width: 8),
                  GoldButton(
                    label: 'Ask',
                    expand: false,
                    onPressed: _busy ? null : _ask,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'People can only be found by their exact handle, and only if '
                'they chose that. There are no private messages.',
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
              if (l.incoming.isNotEmpty) ...<Widget>[
                const _Heading('Requests for you'),
                for (final FriendEntry f in l.incoming)
                  _PersonRow(
                    name: f.displayName,
                    actions: <Widget>[
                      TextButton(
                        onPressed: () async {
                          await runAction<void>(
                            context,
                            () => ref
                                .read(communityApiProvider)
                                .acceptRequest(f.friendshipId),
                            done: 'You are now friends.',
                          );
                          _refresh();
                        },
                        child: const Text('Accept'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await runAction<void>(
                            context,
                            () => ref
                                .read(communityApiProvider)
                                .declineRequest(f.friendshipId),
                          );
                          _refresh();
                        },
                        child: const Text('Decline'),
                      ),
                    ],
                  ),
              ],
              if (l.outgoing.isNotEmpty) ...<Widget>[
                const _Heading('Waiting for an answer'),
                for (final FriendEntry f in l.outgoing)
                  _PersonRow(
                    name: f.displayName,
                    actions: <Widget>[
                      TextButton(
                        onPressed: () async {
                          await runAction<void>(
                            context,
                            () => ref
                                .read(communityApiProvider)
                                .removeFriend(f.friendshipId),
                          );
                          _refresh();
                        },
                        child: const Text('Withdraw'),
                      ),
                    ],
                  ),
              ],
              const _Heading('Your friends'),
              if (l.friends.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No friends yet. Ask someone by handle, or invite them '
                    'with a link.',
                    style: AppText.bodyMuted,
                  ),
                ),
              for (final FriendEntry f in l.friends)
                _PersonRow(
                  name: f.displayName,
                  actions: <Widget>[
                    PopupMenuButton<String>(
                      tooltip: 'More options for ${f.displayName}',
                      icon: const Icon(Icons.more_vert, color: AppColors.sand),
                      onSelected: (String v) async {
                        if (v == 'remove') {
                          await runAction<void>(
                            context,
                            () => ref
                                .read(communityApiProvider)
                                .removeFriend(f.friendshipId),
                            done: 'Removed.',
                          );
                        } else {
                          await runAction<void>(
                            context,
                            () => ref
                                .read(communityApiProvider)
                                .block(f.profileId),
                            done: 'Blocked.',
                          );
                          ref.invalidate(blockedProvider);
                        }
                        _refresh();
                      },
                      itemBuilder: (BuildContext c) =>
                          const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'remove',
                              child: Text('Remove friend'),
                            ),
                            PopupMenuItem<String>(
                              value: 'block',
                              child: Text('Block'),
                            ),
                          ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Semantics(
        header: true,
        child: Text(text.toUpperCase(), style: AppText.eyebrow),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.name, required this.actions});

  final String name;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                name,
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// Make an invite link or code, or use one someone gave you. A code works
/// once by default and expires in three days.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final TextEditingController _code = TextEditingController();
  InviteCreated? _created;
  InvitePreview? _preview;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final InviteCreated? c = await runAction<InviteCreated>(
        context,
        () => ref.read(communityApiProvider).createInvite(),
      );
      if (c != null) {
        setState(() => _created = c);
        ref.invalidate(myInvitesProvider);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    final InvitePreview? p = await runAction<InvitePreview>(
      context,
      () => ref
          .read(communityApiProvider)
          .previewInvite(_code.text.trim().toUpperCase()),
    );
    if (mounted) setState(() => _preview = p);
  }

  Future<void> _redeem() async {
    final RedeemResult? r = await runAction<RedeemResult>(
      context,
      () => ref
          .read(communityApiProvider)
          .redeemInvite(_code.text.trim().toUpperCase()),
    );
    if (r == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You are now friends with ${r.friendDisplayName}.')),
    );
    _code.clear();
    setState(() => _preview = null);
    ref.invalidate(friendListsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return CommunityGate(
      title: 'Invite a Friend',
      builder: (BuildContext c, MeResponse me) {
        final AsyncValue<List<InviteSummary>> invites = ref.watch(
          myInvitesProvider,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Text(
              'Send a link to someone you know. It works once and stops '
              'working after three days.',
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: 12),
            GoldButton(
              label: 'Make an invite',
              onPressed: _busy ? null : _create,
            ),
            if (_created != null) ...<Widget>[
              const SizedBox(height: 12),
              GlassCard(
                strong: true,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Your code', style: AppText.label),
                    SelectableText(
                      _created!.code,
                      style: AppText.titleMedium.copyWith(letterSpacing: 3),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _created!.link,
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => copyWithFeedback(
                        context,
                        _created!.link,
                        message: 'Link copied.',
                      ),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy link'),
                    ),
                    Text(
                      'This code is shown only once.',
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('Have a code?', style: AppText.titleMedium),
            const SizedBox(height: 8),
            Semantics(label: 'Enter the code', child: TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'Enter the code'),
            )),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _check, child: const Text('Check it')),
            if (_preview != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _preview!.familyInvite
                    ? 'This is a family invite.'
                    : 'An invite from ${_preview!.inviterDisplayName ?? 'a member'}.',
                style: AppText.body,
              ),
              const SizedBox(height: 8),
              GoldButton(label: 'Become friends', onPressed: _redeem),
            ],
            const SizedBox(height: 24),
            Text('Your invites', style: AppText.titleMedium),
            const SizedBox(height: 8),
            AsyncBody<List<InviteSummary>>(
              value: invites,
              onRetry: () => ref.invalidate(myInvitesProvider),
              builder: (BuildContext c, List<InviteSummary> list) {
                if (list.isEmpty) {
                  return Text('None yet.', style: AppText.bodyMuted);
                }
                return Column(
                  children: <Widget>[
                    for (final InviteSummary i in list)
                      _PersonRow(
                        name:
                            '${i.uses} of ${i.maxUses} used'
                            '${i.active ? '' : ' · ended'}',
                        actions: <Widget>[
                          if (i.active)
                            TextButton(
                              onPressed: () async {
                                await runAction<void>(
                                  context,
                                  () => ref
                                      .read(communityApiProvider)
                                      .revokeInvite(i.id),
                                  done: 'Invite cancelled.',
                                );
                                ref.invalidate(myInvitesProvider);
                              },
                              child: const Text('Cancel'),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// People you have blocked. Blocking is mutual and quiet: neither of you sees
/// the other's posts or meet-ups, and they are not told.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityGate(
      title: 'Blocked People',
      builder: (BuildContext c, MeResponse me) {
        return AsyncBody<List<BlockedProfile>>(
          value: ref.watch(blockedProvider),
          onRetry: () => ref.invalidate(blockedProvider),
          builder: (BuildContext c, List<BlockedProfile> list) {
            if (list.isEmpty) {
              return const MessageView(
                icon: Icons.block_outlined,
                title: 'No one is blocked',
                message:
                    'You can block anyone from their post, a meet-up or your '
                    'friends list.',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: <Widget>[
                for (final BlockedProfile b in list)
                  _PersonRow(
                    name: b.displayName,
                    actions: <Widget>[
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(communityApiProvider)
                                .unblock(b.profileId);
                          } on BackendException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          }
                          ref.invalidate(blockedProvider);
                        },
                        child: const Text('Unblock'),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
