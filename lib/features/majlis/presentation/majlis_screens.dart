import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../data/majlis_service.dart';

final majlisServiceProvider = Provider<MajlisService>((ref) => MajlisService());

final displayNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('ar.majlis.name') ?? 'Guest of the Courtyard';
});

class MajlisScreen extends ConsumerStatefulWidget {
  const MajlisScreen({super.key});

  @override
  ConsumerState<MajlisScreen> createState() => _MajlisScreenState();
}

class _MajlisScreenState extends ConsumerState<MajlisScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(majlisServiceProvider).seedIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
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
              'Dua requests, questions, announcements. The Adab Engine guards the gate \u2014 '
              'speak as if the Prophet \ufdfa is listening.',
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
                'The Courtyard is waking up (Firebase may still be switching on). '
                'If this persists, confirm Firestore is created and Anonymous sign-in is enabled in the console.',
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
                            style: AppText.bodyMuted.copyWith(fontSize: 11),
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
    final name = await ref.read(displayNameProvider.future);
    await ref.read(majlisServiceProvider).reply(
          threadId: widget.threadId,
          body: body,
          authorName: name,
        );
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
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
                              Text(
                                d.data()['authorName'] as String? ?? '',
                                style: AppText.bodyMuted.copyWith(
                                  fontSize: 11,
                                  color: AppColors.goldLight,
                                ),
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
                    child: TextField(
                      controller: _input,
                      style: AppText.body,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Reply with kindness\u2026',
                        hintStyle: AppText.bodyMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.gold,
                    child: IconButton(
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
    if (_title.text.trim().length < 4 || _body.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ar.majlis.name', _name.text.trim());
    await ref.read(majlisServiceProvider).createThread(
          title: _title.text,
          authorName: _name.text.trim().isEmpty
              ? 'Guest of the Courtyard'
              : _name.text,
          firstPost: _body.text,
        );
    if (mounted) context.go(AppRoutes.majlis);
  }

  @override
  Widget build(BuildContext context) {
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
                TextField(
                  controller: _name,
                  style: AppText.body,
                  decoration: const InputDecoration(
                    hintText: 'Your display name (kept on this device)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _title,
                  style: AppText.body,
                  decoration: const InputDecoration(hintText: 'Thread title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _body,
                  style: AppText.body,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Your opening post\u2026',
                  ),
                ),
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
