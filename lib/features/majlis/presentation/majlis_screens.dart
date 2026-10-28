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
import '../../../app/theme/widgets/screen_header.dart';
import '../data/majlis_service.dart';
import '../domain/majlis_policy.dart';
import '../../../app/theme/widgets/named_sheet.dart';

final majlisServiceProvider = Provider<MajlisService>((ref) => MajlisService());

final displayNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('ar.majlis.name') ?? 'Guest of the Courtyard';
});

/// What the Courtyard shows while it is gated.
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

class MajlisScreen extends ConsumerStatefulWidget {
  const MajlisScreen({super.key});

  @override
  ConsumerState<MajlisScreen> createState() => _MajlisScreenState();
}

class _MajlisScreenState extends ConsumerState<MajlisScreen> {
  // Seeding the room is a founder task (the rules deny client room writes),
  // so the screen never attempts it.
  @override
  Widget build(BuildContext context) {
    // Gated: an open forum with no moderation, block or delete tools must not
    // be reachable (not even by a typed link) until the registry says live.
    final bool open =
        ref.watch(moduleRegistryProvider).valueOrNull?.isLive('majlis') ?? false;
    if (!open) return const MajlisClosed();
    final threads = ref.watch(_threadsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF0A0F18),
        onPressed: () => context.go(AppRoutes.majlisNew),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('New thread'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        children: [
          const ScreenHeader(title: 'Majlis', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('THE COURTYARD \u00b7 OPEN FORUM', style: AppText.eyebrow),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Dua requests, questions, announcements. Posts are not reviewed '
              'before they appear \u2014 please speak as if the Prophet \ufdfa '
              'is listening, and use Report on anything harmful. Nothing here '
              'is a fatwa: for a ruling, ask a qualified scholar. If you or '
              'someone else is in danger, contact local emergency services.',
              style: AppText.bodyMuted,
            ),
          ),
          threads.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
            error: (e, _) => GlassCard(
              child: Text(
                'The Courtyard could not be reached. Check your connection and '
                'try again in a moment.',
                style: AppText.bodyMuted,
              ),
            ),
            data: (snap) => Column(
              children: [
                for (final d in snap.docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      onTap: () => context.go(
                        '${AppRoutes.majlisThread}/${d.id}',
                        extra: d.data()['title'] as String? ?? '',
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.data()['title'] as String? ?? '',
                            style: AppText.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d.data()['authorName'] as String? ?? ''} \u00b7 '
                            '${d.data()['replyCount'] ?? 1} post(s)',
                            style: AppText.bodyMuted.copyWith(fontSize: 12),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _ReportButton(
                              threadId: d.id,
                              what: 'thread',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (snap.docs.isEmpty)
                  GlassCard(
                    child: Text('No threads yet \u2014 start the first one.',
                        style: AppText.bodyMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _threadsProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return ref.watch(majlisServiceProvider).threads();
});

class ThreadScreen extends ConsumerStatefulWidget {
  final String threadId;
  final String title;
  const ThreadScreen({super.key, required this.threadId, required this.title});

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty) return;
    try {
      final name = await ref.read(displayNameProvider.future);
      await ref.read(majlisServiceProvider).reply(
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
    final posts = ref.watch(_postsProvider(widget.threadId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: widget.title, close: true),
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
                                  _ReportButton(
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
                    child: Semantics(label: 'Reply with kindness (public, shown with your name)\u2026', child: TextField(
                      controller: _input,
                      style: AppText.body,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Reply with kindness (public, shown with your name)\u2026',
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

final _postsProvider = StreamProvider.family<QuerySnapshot<Map<String, dynamic>>,
    String>((ref, threadId) {
  return ref.watch(majlisServiceProvider).posts(threadId);
});

class NewThreadScreen extends ConsumerStatefulWidget {
  const NewThreadScreen({super.key});

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
    setState(() => _busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ar.majlis.name', name);
      await ref.read(majlisServiceProvider).createThread(
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const ScreenHeader(title: 'New Thread', close: true),
          const SizedBox(height: 8),
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
                Semantics(label: 'Your opening post\u2026', child: TextField(
                  controller: _body,
                  style: AppText.body,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Your opening post\u2026',
                  ),
                )),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: Text(_busy ? 'Opening\u2026' : 'Open the thread'),
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
  const _ReportButton({required this.threadId, this.postId, required this.what});

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
              child: Text('Report this $what \u2014 why?'),
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
      await ref.read(majlisServiceProvider).report(
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
