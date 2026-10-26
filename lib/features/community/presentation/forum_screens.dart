import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/backend/backend_exception.dart';
import '../../../app/core/backend/community_providers.dart';
import '../../../app/core/backend/models.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../application/community_state.dart';
import 'community_actions.dart';
import 'community_widgets.dart';

/// Forum categories. Ask a scholar is a category of its own: members ask,
/// only verified scholars answer, and nothing a member writes is labelled as
/// guidance.
class ForumCategoriesScreen extends ConsumerWidget {
  const ForumCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityGate(
      title: 'Forums',
      builder: (BuildContext c, MeResponse me) {
        final AsyncValue<List<ForumCategory>> cats = ref.watch(
          forumCategoriesProvider,
        );
        return AsyncBody<List<ForumCategory>>(
          value: cats,
          onRetry: () => ref.invalidate(forumCategoriesProvider),
          builder: (BuildContext c, List<ForumCategory> list) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: <Widget>[
              const OpinionNotice(),
              const SizedBox(height: 12),
              for (final ForumCategory cat in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryCard(category: cat),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final ForumCategory category;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.open('${AppRoutes.communityForum}/${category.slug}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  category.title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.gold.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            category.description,
            style: AppText.bodyMuted.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (category.isAskScholar)
                const LabelChip(
                  'Scholars answer',
                  strong: true,
                  icon: Icons.verified_outlined,
                ),
              if (category.strictModeration)
                const LabelChip(
                  'Read by a moderator first',
                  icon: Icons.shield_outlined,
                ),
              if (!category.canStart)
                const LabelChip('Read only', icon: Icons.lock_outline),
            ],
          ),
        ],
      ),
    );
  }
}

/// The threads in one category: pinned first, then newest activity. There is
/// no "top" or "trending" order, on purpose.
class ForumThreadListScreen extends ConsumerWidget {
  const ForumThreadListScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ForumCategory>> cats = ref.watch(
      forumCategoriesProvider,
    );
    ForumCategory? category;
    for (final ForumCategory c in cats.asData?.value ?? <ForumCategory>[]) {
      if (c.slug == slug) category = c;
    }
    final ForumCategory? cat = category;
    return CommunityGate(
      title: cat?.title ?? 'Forum',
      builder: (BuildContext c, MeResponse me) {
        final AsyncValue<ThreadList> threads = ref.watch(
          forumThreadsProvider(slug),
        );
        return Column(
          children: <Widget>[
            Expanded(
              child: AsyncBody<ThreadList>(
                value: threads,
                onRetry: () => ref.invalidate(forumThreadsProvider(slug)),
                builder: (BuildContext c, ThreadList list) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: <Widget>[
                    if (cat != null && cat.rulesNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            cat.rulesNote,
                            style: AppText.bodyMuted.copyWith(fontSize: 12.5),
                          ),
                        ),
                      ),
                    if (list.threads.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: MessageView(
                          icon: Icons.forum_outlined,
                          title: 'Nothing here yet',
                          message: 'Be the first to start a conversation.',
                        ),
                      ),
                    for (final ForumThread t in list.threads)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ThreadCard(thread: t),
                      ),
                  ],
                ),
              ),
            ),
            if (cat != null && cat.canStart)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: GoldButton(
                  label: cat.isAskScholar
                      ? 'Ask a question'
                      : 'Start a thread',
                  onPressed: () async {
                    if (!await ensureCanWrite(c, ref, me)) return;
                    if (!c.mounted) return;
                    await c.push('${AppRoutes.communityCompose}/$slug');
                    ref.invalidate(forumThreadsProvider(slug));
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ThreadCard extends ConsumerWidget {
  const _ThreadCard({required this.thread});

  final ForumThread thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      onTap: () => context.open('${AppRoutes.communityThread}/${thread.id}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  thread.title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${thread.authorName} · ${thread.postCount} '
                  '${thread.postCount == 1 ? 'post' : 'posts'} · '
                  '${timeAgo(thread.lastPostAt)}',
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
                if (thread.pinned ||
                    thread.locked ||
                    thread.pendingReview ||
                    thread.answered) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      if (thread.pinned)
                        const LabelChip('Pinned', icon: Icons.push_pin_outlined),
                      if (thread.locked)
                        const LabelChip('Closed', icon: Icons.lock_outline),
                      if (thread.pendingReview)
                        const LabelChip(
                          'Waiting for a moderator',
                          icon: Icons.hourglass_empty,
                        ),
                      if (thread.answered)
                        const LabelChip(
                          'Answered by a scholar',
                          strong: true,
                          icon: Icons.verified_outlined,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!thread.mine)
            PopupMenuButton<String>(
              tooltip: 'More options for this thread',
              icon: const Icon(Icons.more_vert, color: AppColors.sand),
              onSelected: (String v) async {
                if (v == 'report') {
                  await showReportSheet(
                    context,
                    target: CommunityTarget.thread,
                    targetId: thread.id,
                    authorProfileId: thread.authorProfileId,
                    authorName: thread.authorName,
                  );
                } else if (v == 'hide') {
                  final bool? ok = await runAction<bool>(
                    context,
                    () async {
                      await ref
                          .read(communityApiProvider)
                          .hideForMe(CommunityTarget.thread, thread.id);
                      return true;
                    },
                    done: 'Hidden. You will not see it again.',
                  );
                  if (ok == true) {
                    ref.invalidate(forumThreadsProvider(thread.categorySlug));
                  }
                }
              },
              itemBuilder: (BuildContext c) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'report', child: Text('Report')),
                PopupMenuItem<String>(
                  value: 'hide',
                  child: Text('Hide for me'),
                ),
              ],
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// One thread with its posts, oldest first. Every post says whose opinion it
/// is; a scholar's answer carries its own label and is only ever from a
/// verified scholar.
class ForumThreadScreen extends ConsumerStatefulWidget {
  const ForumThreadScreen({required this.threadId, super.key});

  final String threadId;

  @override
  ConsumerState<ForumThreadScreen> createState() => _ForumThreadScreenState();
}

class _ForumThreadScreenState extends ConsumerState<ForumThreadScreen> {
  final TextEditingController _reply = TextEditingController();
  bool _sending = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(forumThreadProvider(widget.threadId));

  Future<void> _send(MeResponse me) async {
    final String text = _reply.text.trim();
    if (text.isEmpty) return;
    if (!await ensureCanWrite(context, ref, me)) return;
    setState(() {
      _sending = true;
      _error = null;
      _notice = null;
    });
    try {
      final SubmitResult r = await ref
          .read(communityApiProvider)
          .replyToThread(widget.threadId, text);
      _reply.clear();
      if (mounted) {
        setState(() {
          _notice = r.pendingReview
              ? 'Thank you. A moderator will read this before it appears.'
              : r.showHelp
              ? kHelpNotice
              : null;
        });
      }
      _refresh();
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunityGate(
      title: 'Thread',
      builder: (BuildContext c, MeResponse me) {
        final AsyncValue<ThreadView> view = ref.watch(
          forumThreadProvider(widget.threadId),
        );
        final List<ForumCategory> cats =
            ref.watch(forumCategoriesProvider).asData?.value ??
            <ForumCategory>[];
        return AsyncBody<ThreadView>(
          value: view,
          onRetry: _refresh,
          builder: (BuildContext c, ThreadView v) {
            ForumCategory? cat;
            for (final ForumCategory x in cats) {
              if (x.slug == v.thread.categorySlug) cat = x;
            }
            final bool canReply = cat?.canReply ?? false;
            return Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: <Widget>[
                      Text(v.thread.title, style: AppText.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Started by ${v.thread.authorName}',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      const OpinionNotice(),
                      const SizedBox(height: 12),
                      for (final ForumPost p in v.posts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PostCard(
                            post: p,
                            canWrite: canReply,
                            onChanged: _refresh,
                            me: me,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_notice != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Text(_notice!, style: AppText.body),
                    ),
                  ),
                if (v.thread.locked)
                  const _ComposerNote('This thread is closed.')
                else if (!canReply)
                  _ComposerNote(
                    cat != null && cat.isAskScholar
                        ? 'Only verified scholars answer in Ask a scholar. '
                              'Community members cannot reply here.'
                        : 'You cannot reply in this category.',
                  )
                else
                  _Composer(
                    controller: _reply,
                    sending: _sending,
                    error: _error,
                    onSend: () => _send(me),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Gentle wording shown when a post suggests the writer may be struggling.
/// It is help, never a warning against the writer.
const String kHelpNotice =
    'Thank you for sharing. If you are in danger, or thinking of harming '
    'yourself, please contact your local emergency number now, or speak to '
    'someone you trust. You are not alone.';

class _ComposerNote extends StatelessWidget {
  const _ComposerNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Text(text, style: AppText.bodyMuted, textAlign: TextAlign.center),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    this.error,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                error!,
                style: const TextStyle(color: AppColors.destructive),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    hintText: 'Write a reply (your own opinion)',
                    counterText: '',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Send reply',
                onPressed: sending ? null : onSend,
                icon: const Icon(Icons.send_rounded, color: AppColors.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({
    required this.post,
    required this.canWrite,
    required this.onChanged,
    required this.me,
  });

  final ForumPost post;
  final bool canWrite;
  final VoidCallback onChanged;
  final MeResponse me;

  String get _placeholder {
    switch (post.status) {
      case 'hidden_by_you':
        return 'You hid this.';
      case 'removed':
        return 'This post was removed.';
      default:
        return 'This post is hidden while a moderator looks at it.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (post.isPlaceholder && !post.mine) {
      return GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _placeholder,
                style: AppText.bodyMuted.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            if (post.status == 'hidden_by_you')
              TextButton(
                onPressed: () async {
                  await runAction<void>(
                    context,
                    () => ref
                        .read(communityApiProvider)
                        .showAgain(CommunityTarget.post, post.id),
                  );
                  onChanged();
                },
                child: const Text('Show'),
              ),
          ],
        ),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  post.mine ? '${post.authorName} (you)' : post.authorName,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              _menu(context, ref),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              labelFor(post.label, org: post.scholarOrg),
              Text(
                timeAgo(post.createdAt) +
                    (post.editedAt == null ? '' : ' · edited'),
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(post.body, style: AppText.body),
          ),
          if (post.pendingReview)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Only you can see this until a moderator has read it.',
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
            ),
          const SizedBox(height: 4),
          _helpfulRow(context, ref),
        ],
      ),
    );
  }

  Widget _helpfulRow(BuildContext context, WidgetRef ref) {
    if (post.mine) {
      final int? n = post.helpfulCount;
      if (n == null || n == 0) return const SizedBox(height: 4);
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          n == 1 ? '1 person found this helpful' : '$n people found this helpful',
          style: AppText.bodyMuted.copyWith(fontSize: 12),
        ),
      );
    }
    if (post.status != 'visible') return const SizedBox(height: 4);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () async {
          await runAction<void>(
            context,
            () => ref
                .read(communityApiProvider)
                .setHelpful(post.id, helpful: !post.helpfulByMe),
          );
          onChanged();
        },
        icon: Icon(
          post.helpfulByMe ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: AppColors.gold,
        ),
        label: Text(post.helpfulByMe ? 'Marked helpful' : 'Helpful'),
      ),
    );
  }

  Widget _menu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'More options for this post',
      icon: const Icon(Icons.more_vert, color: AppColors.sand, size: 20),
      onSelected: (String v) async {
        switch (v) {
          case 'report':
            await showReportSheet(
              context,
              target: CommunityTarget.post,
              targetId: post.id,
              authorProfileId: post.authorProfileId,
              authorName: post.authorName,
            );
          case 'hide':
            await runAction<void>(
              context,
              () => ref
                  .read(communityApiProvider)
                  .hideForMe(CommunityTarget.post, post.id),
              done: 'Hidden. You can show it again.',
            );
            onChanged();
          case 'block':
            final String? id = post.authorProfileId;
            if (id == null) return;
            await runAction<void>(
              context,
              () => ref.read(communityApiProvider).block(id),
              done: 'Blocked. You will not see each other.',
            );
            onChanged();
          case 'delete':
            await runAction<void>(
              context,
              () => ref.read(communityApiProvider).deletePost(post.id),
              done: 'Deleted.',
            );
            onChanged();
        }
      },
      itemBuilder: (BuildContext c) => <PopupMenuEntry<String>>[
        if (post.mine)
          const PopupMenuItem<String>(value: 'delete', child: Text('Delete'))
        else ...<PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'report', child: Text('Report')),
          const PopupMenuItem<String>(
            value: 'hide',
            child: Text('Hide for me'),
          ),
          const PopupMenuItem<String>(
            value: 'block',
            child: Text('Block this person'),
          ),
        ],
      ],
    );
  }
}

/// Start a thread. The rules have already been accepted by the time this
/// opens (see [ensureCanWrite]).
class ForumComposeScreen extends ConsumerStatefulWidget {
  const ForumComposeScreen({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<ForumComposeScreen> createState() => _ForumComposeScreenState();
}

class _ForumComposeScreenState extends ConsumerState<ForumComposeScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final SubmitResult r = await ref
          .read(communityApiProvider)
          .startThread(
            slug: widget.slug,
            title: _title.text.trim(),
            body: _body.text.trim(),
          );
      ref.invalidate(forumThreadsProvider(widget.slug));
      if (!mounted) return;
      if (r.pendingReview || r.showHelp) {
        setState(() {
          _done = r.pendingReview
              ? 'Thank you. A moderator will read this before it appears. '
                    'You will see it in the list, marked as waiting.'
              : kHelpNotice;
        });
      } else {
        context.pop();
      }
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ForumCategory? cat = ref
        .watch(forumCategoriesProvider)
        .asData
        ?.value
        .where((ForumCategory c) => c.slug == widget.slug)
        .firstOrNull;
    return CommunityGate(
      title: cat != null && cat.isAskScholar ? 'Ask a scholar' : 'New thread',
      builder: (BuildContext c, MeResponse me) {
        if (_done != null) {
          return MessageView(
            icon: Icons.check_circle_outline,
            title: 'Received',
            message: _done!,
            actionLabel: 'Back to the forum',
            onAction: () => context.pop(),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            if (cat != null && cat.rulesNote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    cat.rulesNote,
                    style: AppText.bodyMuted.copyWith(fontSize: 12.5),
                  ),
                ),
              ),
            const OpinionNotice(),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              maxLength: 140,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            TextField(
              controller: _body,
              minLines: 5,
              maxLines: 12,
              maxLength: 4000,
              decoration: const InputDecoration(
                hintText:
                    'Write here. No photos, links, phone numbers or '
                    'addresses.',
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.destructive),
              ),
            ],
            const SizedBox(height: 12),
            GoldButton(
              label: _busy ? 'Posting...' : 'Post',
              onPressed: _busy ? null : _post,
            ),
          ],
        );
      },
    );
  }
}
