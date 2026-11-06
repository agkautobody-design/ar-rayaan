import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/modules/module_status.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/named_sheet.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../places/application/places_providers.dart' show isFounderProvider;
import '../../prayer/application/prayer_providers.dart';
import '../application/majlis_providers.dart';
import '../data/majlis_service.dart';
import '../domain/countries.dart';
import '../domain/majlis_policy.dart';
import '../domain/region.dart';

/// What the Courtyard shows while the module is gated — the founder's kill
/// switch: set majlis back to 'gated' in the module registry and every
/// Majlis screen returns to this notice.
class MajlisClosed extends StatelessWidget {
  const MajlisClosed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const ScreenHeader(title: 'Majlis', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('THE COURTYARD', style: AppText.eyebrow),
          ),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Text(
              'The Courtyard is not open yet. It will open only once there '
              'are moderators, a way to report and block, and a way to delete '
              'your own posts. Until then, nothing can be posted here.',
              style: AppText.body.copyWith(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the build has no community server at all (local mode).
class _MajlisOffline extends StatelessWidget {
  const _MajlisOffline();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const ScreenHeader(title: 'Majlis', close: true),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Text(
              'This build is not connected to the community server, so the '
              'Majlis can not open here.',
              style: AppText.bodyMuted.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// A human name for a room id: the person's own community label when it is
/// theirs, "The Courtyard" for the open room, the raw key otherwise.
String majlisRoomLabel(String room, RegionSetting? mine) {
  if (room == MajlisService.roomId) return 'The Courtyard';
  if (mine != null && mine.isValid && mine.roomKey == room) return mine.label;
  return room;
}

class MajlisScreen extends ConsumerStatefulWidget {
  const MajlisScreen({super.key});

  @override
  ConsumerState<MajlisScreen> createState() => _MajlisScreenState();
}

class _MajlisScreenState extends ConsumerState<MajlisScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final RegionSetting? r = await RegionSetting.load();
      if (mounted) ref.read(regionSettingProvider.notifier).state = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Gated: an open forum with no moderation, block or delete tools must not
    // be reachable (not even by a typed link) until the registry says live.
    final bool open =
        ref.watch(moduleRegistryProvider).valueOrNull?.isLive('majlis') ?? false;
    if (!open) return const MajlisClosed();
    final MajlisService? service = ref.watch(majlisServiceProvider);
    if (service == null) return const _MajlisOffline();

    final String room = ref.watch(currentRoomProvider);
    final RegionSetting? region = ref.watch(regionSettingProvider);
    final bool inCourtyard = room == MajlisService.roomId;
    final threads = ref.watch(_threadsProvider(room));
    final String? myUid = ref.watch(majlisUidProvider);
    final bool founder = ref.watch(isFounderProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF0A0F18),
        onPressed: () => context.go('${AppRoutes.majlisNew}?room=$room'),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('New thread'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        children: [
          const ScreenHeader(title: 'Majlis', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              inCourtyard
                  ? 'THE COURTYARD · OPEN FORUM'
                  : 'MY COMMUNITY · ${region != null && region.roomKey == room ? region.label.toUpperCase() : room.toUpperCase()}',
              style: AppText.eyebrow,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              inCourtyard
                  ? 'Dua requests, questions, announcements — everyone, '
                      'everywhere. Posts are not reviewed before they appear '
                      '— please speak as if the Prophet ﷺ is listening, and '
                      'use Report on anything harmful. Nothing here is a fatwa: '
                      'for a ruling, ask a qualified scholar. If you or someone '
                      'else is in danger, contact local emergency services.'
                  : 'Your community room — talk with people of your own city '
                      'or area: local events, what is happening, questions for '
                      'neighbours. Posts appear at once and are public. For an '
                      'event with a place and time, add it on the Masajid '
                      'screen’s Events tab too, so it shows on the map.',
              style: AppText.bodyMuted,
            ),
          ),
          _RoomSwitcher(room: room, region: region),
          const SizedBox(height: 12),
          threads.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
            error: (e, _) => GlassCard(
              child: Text(
                'This room could not be reached. Check your connection and '
                'try again in a moment.',
                style: AppText.bodyMuted,
              ),
            ),
            data: (snap) => Column(
              children: [
                for (final d in snap.docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ThreadCard(
                      room: room,
                      id: d.id,
                      data: d.data(),
                      myUid: myUid,
                      founder: founder,
                    ),
                  ),
                if (snap.docs.isEmpty)
                  GlassCard(
                    child: Text(
                      inCourtyard
                          ? 'No threads yet — start the first one.'
                          : 'Nothing in ${majlisRoomLabel(room, region)} yet — start the first thread.',
                      style: AppText.bodyMuted,
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

final _threadsProvider = StreamProvider.family<
    QuerySnapshot<Map<String, dynamic>>, String>((ref, room) {
  final MajlisService? svc = ref.watch(majlisServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.threads(room: room);
});

/// One thread in the list. The author of a single-post thread (and the
/// founder anywhere) gets a delete control; everyone gets Report.
class _ThreadCard extends ConsumerWidget {
  const _ThreadCard({
    required this.room,
    required this.id,
    required this.data,
    required this.myUid,
    required this.founder,
  });

  final String room;
  final String id;
  final Map<String, dynamic> data;
  final String? myUid;
  final bool founder;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool yes = await confirmMajlisDelete(context, 'this thread');
    if (!yes || !context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(majlisServiceProvider)!
          .deleteThread(room: room, threadId: id);
      messenger.showSnackBar(const SnackBar(content: Text('Thread removed.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not remove it — check your connection.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = data['title'] as String? ?? '';
    final String author = data['authorName'] as String? ?? '';
    final int replies = (data['replyCount'] as num?)?.toInt() ?? 1;
    final String? uid = data['uid'] as String?;
    final bool canDelete =
        founder || (myUid != null && uid == myUid && replies == 1);
    return GlassCard(
      onTap: () => context.go(
        '${AppRoutes.majlisThread}/$id?room=$room',
        extra: title,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canDelete)
                IconButton(
                  key: Key('thread-delete-$id'),
                  tooltip: 'Remove this thread',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.goldLight),
                  onPressed: () => _delete(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$author · $replies post(s)',
            style: AppText.bodyMuted.copyWith(fontSize: 12),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _ReportButton(room: room, threadId: id, what: 'thread'),
          ),
        ],
      ),
    );
  }
}

/// Courtyard / community switcher with the "set your community" door.
class _RoomSwitcher extends ConsumerWidget {
  const _RoomSwitcher({required this.room, required this.region});

  final String room;
  final RegionSetting? region;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final RegionSetting? r = await showRegionSheet(context);
    if (r == null) return;
    await r.save();
    ref.read(regionSettingProvider.notifier).state = r;
    // Jump straight into the community the person just chose.
    ref.read(majlisRoomChoiceProvider.notifier).state = r.roomKey;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool inCourtyard = room == MajlisService.roomId;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('majlis-room-courtyard'),
            onTap: inCourtyard
                ? null
                : () => ref
                    .read(majlisRoomChoiceProvider.notifier)
                    .state = MajlisService.roomId,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Icon(
                  inCourtyard
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: AppColors.goldLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('The Courtyard — everyone, everywhere',
                      style: AppText.body.copyWith(fontSize: 13)),
                ),
              ]),
            ),
          ),
          if (region != null && region!.isValid)
            InkWell(
              key: const Key('majlis-room-community'),
              onTap: !inCourtyard
                  ? null
                  : () => ref
                      .read(majlisRoomChoiceProvider.notifier)
                      .state = region!.roomKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(
                    !inCourtyard
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 16,
                    color: AppColors.goldLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('My community — ${region!.label}',
                        style: AppText.body.copyWith(fontSize: 13)),
                  ),
                ]),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('majlis-set-region'),
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.location_city, size: 14),
              label: Text(region == null
                  ? 'Set my community'
                  : 'Change community'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.goldLight,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThreadScreen extends ConsumerStatefulWidget {
  final String threadId;
  final String title;
  final String room;
  const ThreadScreen({
    super.key,
    required this.threadId,
    required this.title,
    this.room = MajlisService.roomId,
  });

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reachable straight from a report link, so load the region here too.
    Future.microtask(() async {
      if (ref.read(regionSettingProvider) != null) return;
      final RegionSetting? r = await RegionSetting.load();
      if (mounted && r != null) {
        ref.read(regionSettingProvider.notifier).state = r;
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty) return;
    final MajlisService? svc = ref.read(majlisServiceProvider);
    if (svc == null) return;
    try {
      final name = await ref.read(displayNameProvider.future);
      await svc.reply(
        room: widget.room,
        threadId: widget.threadId,
        body: body,
        authorName: name,
      );
      _input.clear();
    } on MajlisRejected catch (e) {
      _say(e.message);
    } catch (_) {
      _say('Could not post. Check your connection and try again.');
    }
  }

  Future<void> _deletePost(String postId) async {
    final bool yes = await confirmMajlisDelete(context, 'this post');
    if (!yes || !mounted) return;
    try {
      await ref.read(majlisServiceProvider)!.deletePost(
          room: widget.room, threadId: widget.threadId, postId: postId);
      _say('Post removed.');
    } catch (_) {
      _say('Could not remove it — check your connection.');
    }
  }

  Future<void> _deleteThread() async {
    final bool yes = await confirmMajlisDelete(context, 'this whole thread');
    if (!yes || !mounted) return;
    try {
      await ref
          .read(majlisServiceProvider)!
          .deleteThread(room: widget.room, threadId: widget.threadId);
      if (mounted) context.go(AppRoutes.majlis);
    } catch (_) {
      _say('Could not remove it — check your connection.');
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!(ref.watch(moduleRegistryProvider).valueOrNull?.isLive('majlis') ??
        false)) {
      return const MajlisClosed();
    }
    if (ref.watch(majlisServiceProvider) == null) {
      return const _MajlisOffline();
    }
    final posts =
        ref.watch(_postsProvider((room: widget.room, threadId: widget.threadId)));
    final String? myUid = ref.watch(majlisUidProvider);
    final bool founder = ref.watch(isFounderProvider).valueOrNull ?? false;
    final RegionSetting? region = ref.watch(regionSettingProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: widget.title.isEmpty
                  ? 'Majlis thread'
                  : widget.title,
              close: true,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  majlisRoomLabel(widget.room, region).toUpperCase(),
                  style: AppText.eyebrow,
                ),
              ),
            ),
            if (founder)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: TextButton.icon(
                    key: const Key('thread-delete-founder'),
                    onPressed: _deleteThread,
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('Remove thread'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.goldLight,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: posts.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (e, _) => Center(
                  child: Text('Could not load the thread.',
                      style: AppText.bodyMuted),
                ),
                data: (snap) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    for (final d in snap.docs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      d.data()['authorName'] as String? ?? '',
                                      style: AppText.bodyMuted.copyWith(
                                        fontSize: 12,
                                        color: AppColors.goldLight,
                                      ),
                                    ),
                                  ),
                                  if (founder ||
                                      (myUid != null &&
                                          d.data()['uid'] == myUid))
                                    IconButton(
                                      key: Key('post-delete-${d.id}'),
                                      tooltip: 'Remove this post',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.delete_outline,
                                          size: 16,
                                          color: AppColors.goldLight),
                                      onPressed: () => _deletePost(d.id),
                                    ),
                                  _ReportButton(
                                    room: widget.room,
                                    threadId: widget.threadId,
                                    postId: d.id,
                                    what: 'post',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d.data()['body'] as String? ?? '',
                                style: AppText.body.copyWith(height: 1.55),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(label: 'Reply with kindness (public, shown with your name)…', child: TextField(
                      controller: _input,
                      style: AppText.body,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Reply with kindness (public, shown with your name)…',
                        hintStyle: AppText.bodyMuted,
                      ),
                    )),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.gold,
                    child: IconButton(tooltip: 'Send reply',
                      icon: const Icon(Icons.send,
                          size: 18, color: Color(0xFF0A0F18)),
                      onPressed: _send,
                    ),
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

final _postsProvider = StreamProvider.family<
    QuerySnapshot<Map<String, dynamic>>,
    ({String room, String threadId})>((ref, key) {
  final MajlisService? svc = ref.watch(majlisServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.posts(key.threadId, room: key.room);
});

class NewThreadScreen extends ConsumerStatefulWidget {
  final String room;
  const NewThreadScreen({super.key, this.room = MajlisService.roomId});

  @override
  ConsumerState<NewThreadScreen> createState() => _NewThreadScreenState();
}

class _NewThreadScreenState extends ConsumerState<NewThreadScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final name = await ref.read(displayNameProvider.future);
      if (mounted) _name.text = name;
    });
  }

  Future<void> _submit() async {
    final name =
        _name.text.trim().isEmpty ? 'Guest of the Courtyard' : _name.text.trim();
    final problem = MajlisPolicy.validateName(name) ??
        MajlisPolicy.validateTitle(_title.text) ??
        MajlisPolicy.validateBody(_body.text);
    if (problem != null) {
      _say(problem);
      return;
    }
    final MajlisService? svc = ref.read(majlisServiceProvider);
    if (svc == null) return;
    setState(() => _busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ar.majlis.name', name);
      await svc.createThread(
        room: widget.room,
        title: _title.text,
        authorName: name,
        firstPost: _body.text,
      );
      if (mounted) context.go(AppRoutes.majlis);
    } on MajlisRejected catch (e) {
      _say(e.message);
    } catch (_) {
      _say('Could not open the thread. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!(ref.watch(moduleRegistryProvider).valueOrNull?.isLive('majlis') ??
        false)) {
      return const MajlisClosed();
    }
    if (ref.watch(majlisServiceProvider) == null) {
      return const _MajlisOffline();
    }
    final RegionSetting? region = ref.watch(regionSettingProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const ScreenHeader(title: 'New Thread', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'POSTING IN ${majlisRoomLabel(widget.room, region).toUpperCase()}',
              style: AppText.eyebrow,
            ),
          ),
          GlassCard(
            child: Column(
              children: [
                Semantics(label: 'Display name (shown publicly with your posts)', child: TextField(
                  controller: _name,
                  style: AppText.body,
                  decoration: const InputDecoration(
                    hintText: 'Display name (shown publicly with your posts)',
                  ),
                )),
                const SizedBox(height: 10),
                Semantics(label: 'Thread title', child: TextField(
                  controller: _title,
                  style: AppText.body,
                  decoration: const InputDecoration(hintText: 'Thread title'),
                )),
                const SizedBox(height: 10),
                Semantics(label: 'Your opening post…', child: TextField(
                  controller: _body,
                  style: AppText.body,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Your opening post…',
                  ),
                )),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('new-thread-submit'),
                    onPressed: _busy ? null : _submit,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: Text(_busy ? 'Opening…' : 'Open the thread'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF0A0F18),
                    ),
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

/// "Report" control for a thread or a single post. Opens a short reasons
/// sheet and files the report with the moderators' queue.
class _ReportButton extends ConsumerWidget {
  const _ReportButton({
    required this.room,
    required this.threadId,
    this.postId,
    required this.what,
  });

  final String room;
  final String threadId;
  final String? postId;
  final String what;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _open(context, ref),
      icon: const Icon(Icons.flag_outlined, size: 14),
      label: const Text('Report'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.goldLight,
        minimumSize: const Size(48, 32),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final reason = await showNamedSheet<String>(
      label: 'Report',
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Report this $what — why?'),
            ),
            for (final r in MajlisPolicy.reportReasons)
              ListTile(
                title: Text(MajlisPolicy.reportLabels[r] ?? r),
                onTap: () => Navigator.of(ctx).pop(r),
              ),
          ],
        ),
      ),
    );
    if (reason == null) return;
    String message;
    try {
      final MajlisService? svc = ref.read(majlisServiceProvider);
      if (svc == null) throw StateError('offline');
      await svc.report(
        room: room,
        threadId: threadId,
        postId: postId,
        reason: reason,
      );
      message = 'Thank you. Your report was sent to the moderators.';
    } catch (_) {
      message = 'Could not send the report. Please try again.';
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// One confirm dialog for every Majlis delete (thread card, post, thread).
Future<bool> confirmMajlisDelete(BuildContext context, String what) async {
  final bool? yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Remove $what?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  return yes == true;
}

/// Opens the community picker: a fixed country list plus the city / area
/// the person types (prefilled from the prayer location when it has one).
Future<RegionSetting?> showRegionSheet(BuildContext context) {
  return showNamedSheet<RegionSetting>(
    label: 'My community',
    context: context,
    builder: (ctx) => const SafeArea(child: RegionSheet()),
  );
}

/// The country + city/area form. Pure and widget-testable: it pops a
/// [RegionSetting] or nothing.
class RegionSheet extends ConsumerStatefulWidget {
  const RegionSheet({super.key});

  @override
  ConsumerState<RegionSheet> createState() => _RegionSheetState();
}

class _RegionSheetState extends ConsumerState<RegionSheet> {
  final TextEditingController _area = TextEditingController();
  String? _country;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefill from the prayer location when it names a real city.
    try {
      final loc = ref.read(prayerLocationProvider);
      if (loc.isSet && !loc.isGps && loc.city.trim().isNotEmpty) {
        _area.text = loc.city.trim();
      }
      _country = countryCodeForName(loc.country);
    } catch (_) {
      // No location set — the person picks by hand.
    }
    final RegionSetting? existing = ref.read(regionSettingProvider);
    if (existing != null) {
      _country = existing.countryCode;
      if (existing.area.isNotEmpty) _area.text = existing.area;
    }
  }

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  void _save() {
    final String? cc = _country;
    if (cc == null) {
      setState(() => _error = 'Please choose your country.');
      return;
    }
    final String area = _area.text.trim();
    final RegionSetting r = RegionSetting(countryCode: cc, area: area);
    if (!r.isValid) {
      setState(() => _error =
          'Please enter your city or area (letters or numbers, at least 2 characters).');
      return;
    }
    Navigator.of(context).pop(r);
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> countries = kCountries.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your community room is shared with people of the same city or '
            'area — local events, what is happening, help for neighbours.',
            style: AppText.bodyMuted.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: const Key('region-country'),
            initialValue: _country,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Country'),
            items: [
              for (final MapEntry<String, String> e in countries)
                DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
            ],
            onChanged: (String? v) => setState(() => _country = v),
          ),
          const SizedBox(height: 10),
          Semantics(label: 'City, town or province', child: TextField(
            key: const Key('region-area'),
            controller: _area,
            style: AppText.body,
            decoration: const InputDecoration(
              labelText: 'City, town or province',
              hintText: 'e.g. Birmingham, Ontario, Lahore',
            ),
          )),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: AppText.bodyMuted
                      .copyWith(fontSize: 12, color: AppColors.goldLight)),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('region-save'),
              onPressed: _save,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Join this community'),
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
