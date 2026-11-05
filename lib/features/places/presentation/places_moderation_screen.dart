import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../feedback/application/feedback_providers.dart';
import '../application/places_providers.dart';
import '../data/community_places_service.dart';
import '../domain/community_place.dart';

/// Founder-only moderation for community places and events: the newest
/// submissions, the report queue, hide / remove, and the block list.
///
/// Access is decided by Firestore itself — the screen asks for the person's
/// founder document and the rules refuse every write for anyone else. There
/// is deliberately no link to this screen inside the app; the founder opens
/// it by its address.
class PlacesModerationScreen extends ConsumerWidget {
  const PlacesModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> founder = ref.watch(isFounderProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(children: [
            const ScreenHeader(title: 'Community map moderation', close: true),
            Expanded(
              child: founder.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (_, __) => const _NoAccess(),
                data: (bool isFounder) =>
                    isFounder ? const _ModerationBody() : const _NoAccess(),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        child: Text(
          'This page is for the founder. If that is you, sign in with the '
          'account that has a founder document in Firestore.',
          style: AppText.bodyMuted.copyWith(height: 1.45),
        ),
      ),
    );
  }
}

class _ModerationBody extends ConsumerWidget {
  const _ModerationBody();

  Future<void> _run(BuildContext context, Future<void> Function() what,
      String done) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await what();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('That did not work — check your connection.')));
    }
  }

  Future<bool> _confirm(BuildContext context, String what) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(what),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, do it'),
          ),
        ],
      ),
    );
    return yes == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CommunityPlacesService? svc =
        ref.watch(communityPlacesServiceProvider);
    if (svc == null) return const _NoAccess();
    final AsyncValue<List<CommunityPlace>> places =
        ref.watch(communityPlacesProvider);
    final AsyncValue<List<CommunityEvent>> events =
        ref.watch(communityEventsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('REPORTS', style: AppText.eyebrow),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: svc.reports(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? const [];
            if (docs.isEmpty) {
              return GlassCard(
                child: Text('No reports waiting.',
                    style: AppText.bodyMuted.copyWith(fontSize: 12)),
              );
            }
            return Column(children: [
              for (final d in docs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${d.data()['name'] ?? ''} — '
                          '${PlacesPolicy.reportReasons[d.data()['reason']] ?? d.data()['reason'] ?? ''}',
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        if ((d.data()['note'] as String?) != null)
                          Text(d.data()['note'] as String,
                              style:
                                  AppText.bodyMuted.copyWith(fontSize: 12)),
                        Text(
                          'on ${d.data()['targetType']} · '
                          '${_fmtTime(d.data()['createdAt'])}',
                          style: AppText.bodyMuted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ]);
          },
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('PLACES (newest first)', style: AppText.eyebrow),
        ),
        places.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (_, __) => GlassCard(
            child: Text('Could not load places.',
                style: AppText.bodyMuted.copyWith(fontSize: 12)),
          ),
          data: (list) {
            if (list.isEmpty) {
              return GlassCard(
                child: Text('Nothing submitted yet.',
                    style: AppText.bodyMuted.copyWith(fontSize: 12)),
              );
            }
            return Column(children: [
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(p.name,
                                style: AppText.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                          if (p.hidden)
                            Text('HIDDEN',
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 12, color: AppColors.goldLight)),
                        ]),
                        Text(
                          '${p.type == CommunityPlaceType.halalFood ? 'halal food' : 'masjid'} · '
                          '${p.confirms} confirmed · ${p.flags} flagged · '
                          '${PlacesPolicy.visible(p) ? 'showing' : 'not showing'}',
                          style: AppText.bodyMuted.copyWith(fontSize: 12),
                        ),
                        Text('by ${p.uid}',
                            style: AppText.bodyMuted.copyWith(fontSize: 12)),
                        Wrap(spacing: 4, children: [
                          TextButton(
                            onPressed: () => _run(
                                context,
                                () => svc.setPlaceHidden(p.id, !p.hidden),
                                p.hidden ? 'Showing again.' : 'Hidden.'),
                            child: Text(p.hidden ? 'Unhide' : 'Hide',
                                style: const TextStyle(
                                    color: AppColors.goldLight, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (await _confirm(context, 'Remove "${p.name}"?')) {
                                if (!context.mounted) return;
                                await _run(context, () => svc.deletePlace(p.id),
                                    'Removed.');
                              }
                            },
                            child: const Text('Remove',
                                style: TextStyle(
                                    color: AppColors.goldLight, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (await _confirm(
                                  context, 'Block this account from adding?')) {
                                if (!context.mounted) return;
                                await _run(context, () => svc.blockUser(p.uid),
                                    'Account blocked.');
                              }
                            },
                            child: const Text('Block author',
                                style: TextStyle(
                                    color: AppColors.goldLight, fontSize: 12)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
            ]);
          },
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('EVENTS', style: AppText.eyebrow),
        ),
        events.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (_, __) => GlassCard(
            child: Text('Could not load events.',
                style: AppText.bodyMuted.copyWith(fontSize: 12)),
          ),
          data: (list) {
            if (list.isEmpty) {
              return GlassCard(
                child: Text('No upcoming events.',
                    style: AppText.bodyMuted.copyWith(fontSize: 12)),
              );
            }
            return Column(children: [
              for (final e in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            style: AppText.body.copyWith(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(
                          '${e.where} · ${DateFormat('EEE d MMM, HH:mm').format(e.startsAt)}'
                          '${e.hidden ? ' · HIDDEN' : ''}',
                          style: AppText.bodyMuted.copyWith(fontSize: 12),
                        ),
                        Wrap(spacing: 4, children: [
                          TextButton(
                            onPressed: () => _run(
                                context,
                                () => svc.setEventHidden(e.id, !e.hidden),
                                e.hidden ? 'Showing again.' : 'Hidden.'),
                            child: Text(e.hidden ? 'Unhide' : 'Hide',
                                style: const TextStyle(
                                    color: AppColors.goldLight, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (await _confirm(
                                  context, 'Remove "${e.title}"?')) {
                                if (!context.mounted) return;
                                await _run(context, () => svc.deleteEvent(e.id),
                                    'Removed.');
                              }
                            },
                            child: const Text('Remove',
                                style: TextStyle(
                                    color: AppColors.goldLight, fontSize: 12)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
            ]);
          },
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('BLOCKED ACCOUNTS', style: AppText.eyebrow),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: svc.blocked(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? const [];
            if (docs.isEmpty) {
              return GlassCard(
                child: Text('Nobody is blocked.',
                    style: AppText.bodyMuted.copyWith(fontSize: 12)),
              );
            }
            return Column(children: [
              for (final d in docs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Row(children: [
                      Expanded(
                        child: Text(d.id,
                            style: AppText.bodyMuted.copyWith(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: () => _run(context,
                            () => svc.unblockUser(d.id), 'Unblocked.'),
                        child: const Text('Unblock',
                            style: TextStyle(
                                color: AppColors.goldLight, fontSize: 12)),
                      ),
                    ]),
                  ),
                ),
            ]);
          },
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('FEEDBACK', style: AppText.eyebrow),
        ),
        const _FeedbackList(),
      ],
    );
  }
}

/// Newest beta feedback, founders only.
class _FeedbackList extends ConsumerWidget {
  const _FeedbackList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(feedbackServiceProvider);
    if (svc == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.feedback(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return GlassCard(
            child: Text('No feedback yet.',
                style: AppText.bodyMuted.copyWith(fontSize: 12)),
          );
        }
        return Column(children: [
          for (final d in docs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.data()['body'] as String? ?? '',
                        style: AppText.body.copyWith(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((d.data()['email'] as String?) != null)
                          d.data()['email'] as String,
                        '${d.data()['platform'] ?? '?'} · '
                            'v${d.data()['appVersion'] ?? '?'}',
                        _fmtTime(d.data()['createdAt']),
                        if ((d.data()['errors'] as List?)?.isNotEmpty == true)
                          '${(d.data()['errors'] as List).length} error notes',
                      ].join(' · '),
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                    if ((d.data()['errors'] as List?)?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          (d.data()['errors'] as List).last.toString(),
                          style: AppText.bodyMuted.copyWith(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ]);
      },
    );
  }
}

String _fmtTime(Object? ts) {
  if (ts is Timestamp) {
    return DateFormat('d MMM, HH:mm').format(ts.toDate());
  }
  return 'just now';
}
