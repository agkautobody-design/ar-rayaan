import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/notifications/prayer_notification_scheduler.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/not_found_view.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/academy_reminder_providers.dart';
import '../application/family_service.dart';
import '../application/wasia_controller.dart';
import '../domain/academy_reminders.dart';
import '../domain/children_privacy.dart';
import '../domain/letters_meta.dart';
import 'widgets/active_child_banner.dart';
import 'widgets/parent_gate.dart';
import 'widgets/wasia_thread.dart';
import 'wasia_lessons.dart';

/// The Family Wing — parents add children, watch their growth, and speak
/// with Wasia about each child's learning.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  Future<void> _addChild(BuildContext context, WidgetRef ref) async {
    if (!await requireParent(context, ref)) return;
    if (!context.mounted) return;
    final FamilyService fam = ref.read(familyServiceProvider);
    if (!await fam.hasConsent()) {
      final bool agreed = await showChildrenConsent(context);
      if (!agreed) return;
      await fam.recordConsent();
    }
    if (!context.mounted) return;
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0F18),
        title: Text('Add a child', style: AppText.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: name,
              maxLength: 30,
              style: AppText.body,
              decoration: const InputDecoration(
                  hintText: 'First name or nickname'),
            ),
            Text(
              'A nickname is enough. It stays on this device only.',
              style: AppText.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add',
                  style: TextStyle(color: AppColors.goldLight))),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await fam.addChild(name.text);
      ref.invalidate(childrenProvider);
    } else if (ok == true && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Type a first name or a nickname.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the gate rebuilds this screen when a parent unlocks it.
    ref.watch(parentGateProvider);
    if (!ref.read(parentGateProvider.notifier).isOpen()) {
      return const FamilyLockedView();
    }
    final children = ref.watch(childrenProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const ScreenHeader(title: 'The Family Wing', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('PARENTS \u00b7 WATCH THEM GROW', style: AppText.eyebrow),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'Add your children, follow their lessons and exams, and ask Wasia '
              'how to help them. Your children\u2019s names and progress stay '
              'on this device \u2014 they are never sent to our servers or to any '
              'AI service, and you can delete a child at any time.',
              style: AppText.bodyMuted,
            ),
          ),
          // An ordinary button in the page, not a floating one: a floating
          // button sat on top of the Reminders text while scrolling.
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('add-child'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF0A0F18),
                  minimumSize: const Size(0, 52),
                ),
                onPressed: () => _addChild(context, ref),
                icon: const Icon(Icons.child_care_outlined, size: 20),
                label: const Text('Add child'),
              ),
            ),
          ),
          children.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
            ),
            error: (e, _) => GlassCard(
                child: Text('Could not load children.', style: AppText.bodyMuted)),
            data: (list) => Column(children: [
              if (list.isEmpty)
                GlassCard(
                  child: Text(
                    'No children added yet. Tap \u201cAdd child\u201d — then their '
                    'lessons, quiz answers, and exam scores will appear here, '
                    'and Wasia will help you coach them.',
                    style: AppText.bodyMuted,
                  ),
                ),
              for (final c in list) _ChildCard(child: c),
              const _ChildPrivacyCard(),
              const _ReminderCard(),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends ConsumerWidget {
  final Map<String, dynamic> child;
  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider(child['id'] as String));
    final name = child['name'] as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        strong: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                  child: Text(name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(color: AppColors.goldLight)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      style: AppText.titleMedium.copyWith(fontSize: 16)),
                ),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(familyServiceProvider)
                        .setActiveChild(child['id'] as String);
                    if (context.mounted) context.go('/academy/letters');
                  },
                  child: const Text('Switch to learning',
                      style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
                ),
                IconButton(
                  tooltip: 'Delete $name',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.goldLight),
                  onPressed: () => _confirmDelete(context, ref, name),
                ),
              ],
            ),
            const SizedBox(height: 8),
            progress.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (p) {
                final lessons = (p['lessons'] as Map).length;
                final exams = (p['exams'] as Map).values
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();
                // Best single exam as a true percentage (score / total).
                int bestPct = 0;
                for (final e in exams) {
                  final int sc = (e['score'] as num? ?? 0).toInt();
                  final int tot = (e['total'] as num? ?? 0).toInt();
                  if (tot > 0) {
                    final int pct = (sc * 100 / tot).round();
                    if (pct > bestPct) bestPct = pct;
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$lessons / $kLettersLessonCount letters lessons \u00b7 ${exams.length} exam(s) '
                      '${exams.isNotEmpty ? '\u00b7 best $bestPct%' : ''}',
                      style: AppText.bodyMuted,
                    ),
                    if (exams.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final e in (p['exams'] as Map).entries)
                        Builder(builder: (_) {
                          final v = Map<String, dynamic>.from(e.value as Map);
                          return Text(
                            '\u2022 ${v['score']}/${v['total']} \u00b7 ${_examTitle(e.key as String)}',
                            style: AppText.bodyMuted.copyWith(fontSize: 12),
                          );
                        }),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            _OnlineGamesSwitch(
              childId: child['id'] as String,
              childName: name,
            ),
            _ParentWasiaBox(childName: name),
          ],
        ),
      ),
    );
  }

  String _examTitle(String id) => id.replaceAll('-exam', '').toUpperCase();

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String name) async {
    if (!await requireParent(context, ref)) return;
    if (!context.mounted) return;
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0F18),
        title: Text('Delete $name?', style: AppText.titleMedium),
        content: Text(
          'This removes $name and all of their progress from this device '
          'now. It cannot be undone.',
          style: AppText.bodyMuted,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.goldLight))),
        ],
      ),
    );
    if (yes == true) {
      await ref
          .read(familyServiceProvider)
          .deleteChild(child['id'] as String);
      ref.invalidate(childrenProvider);
    }
  }
}

/// Parents speak with Wasia here. She is never given the child's name or
/// progress (see `children_privacy.dart`); a parent's own question may go to
/// the AI service only while the parent check is open.
class _ParentWasiaBox extends ConsumerStatefulWidget {
  final String childName;
  const _ParentWasiaBox({required this.childName});

  @override
  ConsumerState<_ParentWasiaBox> createState() => _ParentWasiaBoxState();
}

class _ParentWasiaBoxState extends ConsumerState<_ParentWasiaBox> {
  final _input = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(wasiaControllerProvider).isLoading;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ASK WASIA ABOUT ${widget.childName.toUpperCase()}',
          style: AppText.eyebrow.copyWith(fontSize: 12)),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _input,
            style: AppText.body.copyWith(fontSize: 13),
            decoration: const InputDecoration(
                hintText: 'How is my child doing? What should we practice?',
                helperText: 'Please do not type your child\u2019s name.'),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: AppColors.gold,
          radius: 20,
          child: IconButton(tooltip: 'Send to Wasia',
            icon: busy
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Color(0xFF0A0F18)))
                : const Icon(Icons.send, size: 16, color: Color(0xFF0A0F18)),
            onPressed: busy
                ? null
                : () async {
                    final q = _input.text.trim();
                    if (q.isEmpty) return;
                    final bool verified =
                        ref.read(parentGateProvider.notifier).isOpen();
                    await ref.read(wasiaControllerProvider.notifier).ask(q,
                        persona: WasiaPersona.parent,
                        parentVerified: verified);
                    // Keep the words when Wasia could not answer, so a retry
                    // is one tap; otherwise start the next question clean.
                    if (!mounted) return;
                    if (ref.read(wasiaControllerProvider).notice == null) {
                      _input.clear();
                    }
                  },
          ),
        ),
      ]),
      const SizedBox(height: 8),
      const WasiaThread(),
    ]);
  }
}

/// The exam hall: unit exams, calm and unhurried, recorded to the child.
class ExamScreen extends ConsumerStatefulWidget {
  final String examId;
  const ExamScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  int _i = 0;
  int _score = 0;
  int? _picked;
  bool _done = false;
  // Whether this result was stored for an active child. Without one the
  // exam still runs, but the result screen must not claim it was recorded.
  bool _recorded = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(lettersCurriculumProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: data.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Column(children: [
          const ScreenHeader(title: 'Exam', close: true),
          Expanded(
            child: NeedsInternetView(
              what: 'The exam',
              onRetry: () => ref.invalidate(lettersCurriculumProvider),
            ),
          ),
        ]),
        data: (d) {
          final exam = (d['exams'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .firstWhere((e) => e['id'] == widget.examId,
                  orElse: () => const {});
          if (exam.isEmpty) {
            return const NotFoundView(
              message: 'That exam is not here.',
              title: 'Exam',
            );
          }
          final qs = (exam['questions'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (_done) {
            final pass = _score >= (exam['pass'] as num? ?? 7).toInt();
            return _result(pass, _score, qs.length);
          }
          final q = qs[_i];
          final options = (q['options'] as List<dynamic>).cast<String>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              ScreenHeader(title: exam['title'] as String? ?? 'Exam', close: true),
              const ActiveChildBanner(),
              Text('QUESTION ${_i + 1} OF ${qs.length} \u00b7 SCORE $_score',
                  style: AppText.eyebrow),
              const SizedBox(height: 12),
              GlassCard(
                child: Text(q['q'] as String,
                    style: AppText.body.copyWith(fontSize: 16, height: 1.5)),
              ),
              const SizedBox(height: 14),
              for (var o = 0; o < options.length; o++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    semanticsLabel: 'Answer ${o + 1}: ${options[o]}',
                    onTap: _picked == null ? () => setState(() => _picked = o) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(options[o],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Amiri', fontSize: 30,
                              color: Color(0xFFEAD9A8))),
                    ),
                  ),
                ),
              if (_picked != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    (_picked == (q['answer'] as num).toInt()
                        ? 'Correct, ma sha Allah! '
                        : 'Not quite — ') + (q['why'] as String? ?? ''),
                    style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.5),
                  ),
                ),
              const SizedBox(height: 12),
              if (_picked != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final wasCorrect =
                          _picked == (q['answer'] as num).toInt();
                      if (wasCorrect) _score++;
                      if (_i + 1 >= qs.length) {
                        final child =
                            await ref.read(familyServiceProvider).activeChildId();
                        if (child != null) {
                          await ref.read(familyServiceProvider).recordExam(
                                child, widget.examId,
                                score: _score, total: qs.length,
                              );
                          ref.invalidate(progressProvider);
                        }
                        setState(() {
                          _recorded = child != null;
                          _done = true;
                        });
                      } else {
                        setState(() {
                          _picked = null;
                          _i++;
                        });
                      }
                    },
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 13, color: AppColors.gold),
                    label: Text(
                        _i + 1 >= qs.length ? 'See result' : 'Next',
                        style: AppText.bodyMuted),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _result(bool pass, int score, int total) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('EXAM COMPLETE', style: AppText.eyebrow),
            const SizedBox(height: 10),
            Text('$score / $total',
                style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 46,
                    color: AppColors.goldLight)),
            const SizedBox(height: 8),
            Text(
              (pass
                      ? 'Passed, alhamdulillah! '
                      : 'Not yet — no sadness. Wasia says: rest, review the letters, and retake it when you are ready. Growth is patient. ') +
                  (_recorded
                      ? (pass
                          ? 'Wasia has recorded this in your child\u2019s growth (the best attempt is kept).'
                          : 'Your best attempt so far is kept in your child\u2019s growth.')
                      : 'No child is active, so this result was not saved — add a child in the Family Wing to keep a record.'),
              textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(height: 1.55),
            ),
            const SizedBox(height: 18),
            if (!pass)
              TextButton(
                onPressed: () => setState(() {
                  _i = 0;
                  _score = 0;
                  _picked = null;
                  _done = false;
                  _recorded = false;
                }),
                child: const Text('Retake the exam',
                    style: TextStyle(color: AppColors.goldLight)),
              ),
            TextButton(
              onPressed: () => context.go('/academy/letters'),
              child: const Text('Back to the School',
                  style: TextStyle(color: AppColors.goldLight)),
            ),
          ],
        ),
      ),
    );
  }
}


/// What a parent sees until the parent check is passed: no child names, no
/// progress.
class FamilyLockedView extends ConsumerWidget {
  const FamilyLockedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const ScreenHeader(title: 'The Family Wing', close: true),
          GlassCard(
            strong: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FOR PARENTS AND GUARDIANS', style: AppText.eyebrow),
                const SizedBox(height: 8),
                Text(
                  'This area holds your children\u2019s profiles and progress. '
                  'Please answer a quick question to continue.',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => requireParent(context, ref),
                  child: const Text('I am a parent or guardian'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The consent step shown before the first child is added. True = agreed.
Future<bool> showChildrenConsent(BuildContext context) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => const _ConsentDialog(),
  );
  return ok ?? false;
}

class _ConsentDialog extends StatefulWidget {
  const _ConsentDialog();

  @override
  State<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<_ConsentDialog> {
  bool _agree = false;
  bool _showHint = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0F18),
      title: Text(kChildrenPrivacyTitle, style: AppText.titleMedium),
      // The long text scrolls; the tick box and the reason Continue is not
      // ready stay pinned below it, so they can never be clipped away.
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final String b in kChildrenPrivacyBullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '\u2022 $b',
                        style: AppText.bodyMuted.copyWith(height: 1.45),
                      ),
                    ),
                ],
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agree,
            onChanged: (bool? v) => setState(() {
              _agree = v ?? false;
              if (_agree) _showHint = false;
            }),
            title: Text(
              'I am this child\u2019s parent or guardian, and I agree.',
              style: AppText.body,
            ),
          ),
          if (_showHint && !_agree)
            Text(
              'Tick the box above to continue.',
              key: const Key('consent-hint'),
              style: AppText.bodyMuted.copyWith(color: AppColors.goldLight),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        // Always tappable: when the box is not ticked it says why instead of
        // sitting greyed out and silent.
        TextButton(
          onPressed: _agree
              ? () => Navigator.pop(context, true)
              : () => setState(() => _showHint = true),
          child: Text(
            'Continue',
            style: TextStyle(
              color: _agree ? AppColors.goldLight : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Privacy controls at the foot of the Family Wing: the AI switch for
/// children, the full text, and delete-everything.
class _ChildPrivacyCard extends ConsumerStatefulWidget {
  const _ChildPrivacyCard();

  @override
  ConsumerState<_ChildPrivacyCard> createState() => _ChildPrivacyCardState();
}

class _ChildPrivacyCardState extends ConsumerState<_ChildPrivacyCard> {
  bool _ai = false;

  @override
  void initState() {
    super.initState();
    unawaited(WasiaController.childLlmAllowed().then((bool v) {
      if (mounted) setState(() => _ai = v);
    }));
  }

  Future<void> _setAi(bool v) async {
    if (!await requireParent(context, ref)) return;
    await WasiaController.setChildLlmAllowed(v);
    if (mounted) setState(() => _ai = v);
  }

  Future<void> _deleteAll() async {
    if (!await requireParent(context, ref)) return;
    if (!mounted) return;
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0F18),
        title: Text('Delete all children?', style: AppText.titleMedium),
        content: Text(
          'This removes every child and all progress from this device now, '
          'and withdraws your consent. It cannot be undone.',
          style: AppText.bodyMuted,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete everything',
                  style: TextStyle(color: AppColors.goldLight))),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(familyServiceProvider).deleteAllChildren();
      ref.invalidate(childrenProvider);
    }
  }

  void _showPolicy() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0F18),
        title: Text(kChildrenPrivacyTitle, style: AppText.titleMedium),
        content: SingleChildScrollView(
          child: Text(kChildrenPrivacySection.trim(),
              style: AppText.bodyMuted.copyWith(height: 1.5)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRIVACY AND CONTROLS', style: AppText.eyebrow),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _ai,
            onChanged: _setAi,
            title: Text('Ask the AI service for my child',
                style: AppText.body),
            subtitle: Text(
              'Off (the default): Wasia answers a child only from the app\u2019s '
              'own lessons. On: the question the child types goes to the AI '
              'service you chose, with the text of the lesson they are reading '
              'when they ask from a lesson \u2014 never their name or '
              'progress.',
              style: AppText.caption,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton(
                  onPressed: _showPolicy,
                  child: const Text('Read the children\u2019s privacy text',
                      style:
                          TextStyle(color: AppColors.goldLight, fontSize: 12)),
                ),
              ),
              TextButton(
                onPressed: _deleteAll,
                child: const Text('Delete all',
                    style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The guardian's switch for online game tables, per child. Off for every
/// new child; changing it needs the parent check. The room stores no name
/// either way (see `game_rooms_service.dart`).
class _OnlineGamesSwitch extends ConsumerStatefulWidget {
  const _OnlineGamesSwitch({required this.childId, required this.childName});

  final String childId;
  final String childName;

  @override
  ConsumerState<_OnlineGamesSwitch> createState() => _OnlineGamesSwitchState();
}

class _OnlineGamesSwitchState extends ConsumerState<_OnlineGamesSwitch> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref
          .read(familyServiceProvider)
          .onlineGamesAllowed(widget.childId)
          .then((bool v) {
        if (mounted) setState(() => _on = v);
      }),
    );
  }

  Future<void> _set(bool v) async {
    if (!await requireParent(context, ref)) return;
    await ref
        .read(familyServiceProvider)
        .setOnlineGamesAllowed(widget.childId, v);
    if (mounted) setState(() => _on = v);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: Key('online-games-${widget.childId}'),
      contentPadding: EdgeInsets.zero,
      value: _on,
      onChanged: _set,
      title: Text('Online game tables', style: AppText.body),
      subtitle: Text(
        'Off (the default): ${widget.childName} can play Ludo and Shatranj '
        'only on this device. On: ${widget.childName} can create or join a '
        'table with a six-letter code. The table shows only \u201cPlayer 1\u201d '
        'and \u201cPlayer 2\u201d: no name is sent, and there is no chat.',
        style: AppText.caption,
      ),
    );
  }
}

/// Parent-controlled, local-only Academy reminders. Both switches are off by
/// default; turning one on (and changing the time) needs the parent gate.
class _ReminderCard extends ConsumerWidget {
  const _ReminderCard();

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    Future<bool> Function(bool) set,
    bool on,
  ) async {
    if (!await requireParent(context, ref)) return;
    final bool shown = await set(on);
    if (!context.mounted || !on || shown) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notifications are not available here, so this reminder cannot '
          'show yet.',
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    AcademyReminderSettings s,
  ) async {
    if (!await requireParent(context, ref)) return;
    if (!context.mounted) return;
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
    );
    if (t == null) return;
    await ref
        .read(academyReminderProvider.notifier)
        .setTime(t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AcademyReminderSettings s = ref.watch(academyReminderProvider);
    final PrayerNotificationScheduler sched = ref.watch(
      prayerNotificationSchedulerProvider,
    );
    final AcademyReminderController c = ref.read(
      academyReminderProvider.notifier,
    );
    final String time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: s.hour, minute: s.minute),
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REMINDERS', style: AppText.eyebrow),
          const SizedBox(height: 4),
          Text(
            'Off by default. One quiet notification a day at most, on this '
            'device only: nothing is sent anywhere, and it never mentions a '
            'child or counts a streak.',
            style: AppText.caption,
          ),
          SwitchListTile(
            key: const ValueKey<String>('remind-lesson'),
            contentPadding: EdgeInsets.zero,
            value: s.lesson,
            onChanged: (bool v) => _toggle(context, ref, c.setLesson, v),
            title: Text('Daily lesson', style: AppText.body),
          ),
          SwitchListTile(
            key: const ValueKey<String>('remind-reviews'),
            contentPadding: EdgeInsets.zero,
            value: s.reviews,
            onChanged: (bool v) => _toggle(context, ref, c.setReviews, v),
            title: Text('Lessons ready to revisit', style: AppText.body),
            subtitle: Text(
              'Only on days when something is waiting.',
              style: AppText.caption,
            ),
          ),
          if (s.any)
            ListTile(
              key: const ValueKey<String>('remind-time'),
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 12,
              title: Text('Time: $time', style: AppText.body),
              trailing: const Icon(Icons.schedule, size: 20),
              onTap: () => _pickTime(context, ref, s),
            ),
          if (!sched.supported)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Notifications are not available on this device, so '
                'reminders cannot show here.',
                style: AppText.caption,
              ),
            ),
        ],
      ),
    );
  }
}
