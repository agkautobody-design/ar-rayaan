import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/router.dart';
import '../../feedback/application/feedback_providers.dart';
import '../../majlis/application/majlis_providers.dart';
import '../../majlis/data/majlis_service.dart';
import '../../majlis/domain/majlis_policy.dart';
import '../../majlis/presentation/majlis_screens.dart'
    show helperRoleLabel;
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
            const ScreenHeader(title: 'Community moderation', close: true),
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
          child: Text('MAJLIS REPORTS', style: AppText.eyebrow),
        ),
        const _MajlisReports(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('VERIFIED HELPERS', style: AppText.eyebrow),
        ),
        const _HelpersPanel(),
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

/// The Majlis report queue — same screen, one stop for the founder. Each
/// report names its room and thread so it can be opened in one tap.

/// Founder tool: grant and revoke verified-helper badges (helper_roles).
/// Helpers answer in the Ask a Scholar / Ask a Professional rooms; the
/// Firestore rules enforce the same list server-side, this is only the
/// management screen.
class _HelpersPanel extends ConsumerStatefulWidget {
  const _HelpersPanel();

  @override
  ConsumerState<_HelpersPanel> createState() => _HelpersPanelState();
}

class _HelpersPanelState extends ConsumerState<_HelpersPanel> {
  static const List<String> _roles = <String>[
    'scholar',
    'doctor',
    'counsellor',
    'professional',
  ];

  final TextEditingController _uid = TextEditingController();
  String _role = 'scholar';
  bool _busy = false;

  @override
  void dispose() {
    _uid.dispose();
    super.dispose();
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _grant() async {
    final String uid = _uid.text.trim();
    if (uid.isEmpty) {
      _say('Paste the person\u2019s sign-in id first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(majlisServiceProvider)!.setHelperRole(uid, _role);
      _uid.clear();
      _say('Badge granted.');
    } catch (_) {
      _say('Could not grant it — check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(String uid) async {
    try {
      await ref.read(majlisServiceProvider)!.removeHelperRole(uid);
      _say('Badge revoked.');
    } catch (_) {
      _say('Could not revoke it — check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final MajlisService? svc = ref.watch(majlisServiceProvider);
    if (svc == null) return const SizedBox.shrink();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'People with a badge can answer in Ask a Scholar (scholars) and '
            'Ask a Professional (doctors, counsellors, professionals). Grant '
            'a badge with the person\u2019s sign-in id — they can find it in '
            'Firebase console → Authentication, or copy it from a report.',
            style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 10),
          StreamBuilder<Map<String, String>>(
            stream: svc.helperRoles(),
            builder: (context, snap) {
              final Map<String, String> roles =
                  snap.data ?? const <String, String>{};
              if (roles.isEmpty) {
                return Text('No verified helpers yet.',
                    style: AppText.bodyMuted.copyWith(fontSize: 12));
              }
              return Column(children: [
                for (final e in roles.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.key,
                                style: AppText.body.copyWith(fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                            Text(helperRoleLabel(e.value),
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 12,
                                    color: AppColors.goldLight)),
                          ],
                        ),
                      ),
                      TextButton(
                        key: Key('helper-revoke-${e.key}'),
                        onPressed: () => _revoke(e.key),
                        child: const Text('Revoke',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ]),
                  ),
              ]);
            },
          ),
          const Divider(height: 20),
          Semantics(
            label: 'Sign-in id of the person to verify',
            child: TextField(
              key: const Key('helper-uid'),
              controller: _uid,
              style: AppText.body,
              decoration: const InputDecoration(
                hintText: 'Sign-in id (uid) of the person to verify',
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: const Key('helper-role'),
            initialValue: _role,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Badge'),
            items: [
              for (final r in _roles)
                DropdownMenuItem<String>(
                    value: r, child: Text(helperRoleLabel(r))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _role = v);
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('helper-grant'),
              onPressed: _busy ? null : _grant,
              icon: const Icon(Icons.verified_outlined, size: 16),
              label: Text(_busy ? 'Granting…' : 'Grant badge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0A0F18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MajlisReports extends ConsumerWidget {
  const _MajlisReports();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MajlisService? majlis = ref.watch(majlisServiceProvider);
    if (majlis == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: majlis.reports(),
      builder: (context, snap) {
        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (docs.isEmpty) {
          return GlassCard(
            child: Text('No Majlis reports waiting.',
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
                      MajlisPolicy.reportLabels[d.data()['reason']] ??
                          '${d.data()['reason'] ?? ''}',
                      style: AppText.body.copyWith(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      '${d.data()['room'] ?? 'courtyard'} · '
                      '${(d.data()['postId'] as String?) != null ? 'a post' : 'a thread'} · '
                      '${_fmtTime(d.data()['createdAt'])}',
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                    if ((d.data()['note'] as String?) != null)
                      Text(d.data()['note'] as String,
                          style: AppText.bodyMuted.copyWith(fontSize: 12)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.open(
                          '${AppRoutes.majlisThread}/${d.data()['threadId']}'
                          '?room=${d.data()['room'] ?? 'courtyard'}',
                        ),
                        child: const Text('Open thread',
                            style: TextStyle(
                                color: AppColors.goldLight, fontSize: 12)),
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
