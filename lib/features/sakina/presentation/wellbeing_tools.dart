import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import '../../share/presentation/share_actions.dart' show copyWithFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/providers.dart';
import '../../../app/core/scholar_review.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../hadi/grounding/corpus.dart';
import '../../hadi/grounding/passage.dart';
import '../../support/presentation/privacy_shield.dart';
import '../application/wellbeing_store.dart';
import 'widgets/need_help_button.dart';

// The three tools (SteadyScreen, MoodCheckInScreen, SafetyPlanScreen) are
// real routes under /sakina/, so the browser Back button and the in-app
// arrow both return to Sakina.

class _ToolScaffold extends StatelessWidget {
  const _ToolScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.sakina),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: AppText.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: QuickExitButton(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  const ScholarReviewNote(
                    reviewKey: 'sakina.wellbeing-tools',
                    detail:
                        'A clinician has not reviewed this tool. It does not replace one.',
                    padding: EdgeInsets.only(bottom: 10),
                  ),
                  ...children,
                  const SizedBox(height: 16),
                  const Center(child: NeedHelpNowButton()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mood check-in ────────────────────────────────────────────────────

class MoodCheckInScreen extends ConsumerStatefulWidget {
  const MoodCheckInScreen({super.key});

  @override
  ConsumerState<MoodCheckInScreen> createState() => _MoodCheckInScreenState();
}

class _MoodCheckInScreenState extends ConsumerState<MoodCheckInScreen> {
  int _window = 7;

  MoodStore get _store => MoodStore(ref.read(sharedPreferencesProvider));

  @override
  Widget build(BuildContext context) {
    final List<MoodEntry> entries = _store.lastDays(_window);
    return _ToolScaffold(
      title: 'How are you today?',
      children: <Widget>[
        Text(
          'One tap, only for you. It is not a score and not a tally, and it '
          'stays on this device.',
          style: AppText.caption.copyWith(height: 1.5),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final Mood m in Mood.values)
              ActionChip(
                label: Text(m.label),
                onPressed: () async {
                  await _store.record(m);
                  if (!mounted) return;
                  setState(() {});
                  if (m == Mood.heavy || m == Mood.low) {
                    await showNeedHelpSheet(
                      context,
                      intro: 'Thank you for saying so. If it is more than a '
                          'passing day, talking to a person can help. These '
                          'lines are free.',
                    );
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            ChoiceChip(
              label: const Text('Last 7 days'),
              selected: _window == 7,
              onSelected: (_) => setState(() => _window = 7),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Last 30 days'),
              selected: _window == 30,
              onSelected: (_) => setState(() => _window = 30),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: entries.isEmpty
              ? Text('Nothing yet.', style: AppText.caption)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final MoodEntry e in entries.reversed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          '${e.day}   ${e.mood.label}',
                          style: AppText.caption.copyWith(color: AppColors.sand),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            TextButton.icon(
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: const Text('Copy my check-ins'),
              onPressed: () => copyWithFeedback(
                context,
                _store.exportText(),
                message: 'Copied.',
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete all'),
              onPressed: () async {
                final bool? ok = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text('Delete all check-ins?'),
                    content: const Text('This cannot be undone.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Keep'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await _store.clear();
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ── Steady yourself: breathing + grounding ───────────────────────────

class SteadyScreen extends ConsumerStatefulWidget {
  const SteadyScreen({super.key});

  @override
  ConsumerState<SteadyScreen> createState() => _SteadyScreenState();
}

class _SteadyScreenState extends ConsumerState<SteadyScreen> {
  static const int _inSeconds = 4;
  static const int _outSeconds = 6;
  Timer? _timer;
  bool _running = false;
  int _tick = 0;

  static const List<String> _grounding = <String>[
    'Name 5 things you can see.',
    'Name 4 things you can feel or touch.',
    'Name 3 things you can hear.',
    'Name 2 things you can smell.',
    'Name 1 thing you can taste, or one slow breath you can feel.',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _breathingIn => (_tick % (_inSeconds + _outSeconds)) < _inSeconds;

  int get _left {
    final int t = _tick % (_inSeconds + _outSeconds);
    return t < _inSeconds ? _inSeconds - t : _inSeconds + _outSeconds - t;
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() {
      _running = true;
      _tick = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() => _tick++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Passage? ayah = ref.watch(hadiCorpusProvider).valueOrNull?.resolve('q:13:28');
    return _ToolScaffold(
      title: 'Steady yourself',
      children: <Widget>[
        Text(
          'A slow breath tells the body it is safe enough to settle. '
          'In for 4, out for 6. This is a calming exercise, not a treatment.',
          style: AppText.caption.copyWith(height: 1.5),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Text(
                !_running
                    ? 'Ready when you are'
                    : (_breathingIn ? 'Breathe in' : 'Breathe out slowly'),
                style: AppText.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _running ? '$_left' : '4 in · 6 out',
                style: AppText.titleMedium.copyWith(color: AppColors.gold),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _toggle,
                child: Text(_running ? 'Stop' : 'Start'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('5-4-3-2-1', style: AppText.eyebrow.copyWith(color: AppColors.gold)),
        const SizedBox(height: 6),
        for (final String g in _grounding)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(g, style: AppText.body.copyWith(height: 1.5)),
          ),
        if (ayah != null) ...<Widget>[
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ayah.reference.toUpperCase(),
                  style: AppText.eyebrow.copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: 6),
                if (ayah.arabic != null)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      ayah.arabic!,
                      style: AppText.body.copyWith(fontSize: 20, height: 1.8),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(ayah.english, style: AppText.body.copyWith(height: 1.6)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Safety plan ──────────────────────────────────────────────────────

class SafetyPlanScreen extends ConsumerStatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  ConsumerState<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends ConsumerState<SafetyPlanScreen> {
  late final SafetyPlanStore _store;
  late final Map<String, TextEditingController> _c;

  static const List<(String, String, String)> _fields = <(String, String, String)>[
    ('warningSigns', '1. Signs that a hard moment is starting',
        'Thoughts, feelings or situations that tell me it is coming'),
    ('copingSteps', '2. Things I can do on my own',
        'Wudu, a walk, a du’a, breathing, a shower'),
    ('distractionPeople', '3. People and places that help me think of something else',
        'A friend’s house, the masjid, a cafe'),
    ('peopleToAsk', '4. People I can ask for help',
        'Names and numbers of people I trust'),
    ('professionals', '5. Professionals and lines I can contact',
        'My doctor, a counsellor, the help line for my country'),
    ('safeSpace', '6. Making my space safer',
        'Anything I can put out of reach, or ask someone to hold'),
    ('reasons', '7. What I am living for', 'People, hopes, things I love'),
  ];

  @override
  void initState() {
    super.initState();
    _store = SafetyPlanStore(ref.read(sharedPreferencesProvider));
    final Map<String, String> m = _store.load().toMap();
    _c = <String, TextEditingController>{
      for (final (String, String, String) f in _fields)
        f.$1: TextEditingController(text: m[f.$1] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final TextEditingController c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  SafetyPlan _current() => SafetyPlan.fromMap(<String, dynamic>{
        for (final MapEntry<String, TextEditingController> e in _c.entries)
          e.key: e.value.text,
      });

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: 'My safety plan',
      children: <Widget>[
        Text(
          'A plan you write now, while you are calm, to use on a hard day. It '
          'follows a well-known safety-planning order. It stays on this '
          'device and nobody can read it. This tool has not yet been '
          'reviewed by a clinician, and it does not replace one.',
          style: AppText.caption.copyWith(height: 1.5),
        ),
        const SizedBox(height: 12),
        for (final (String, String, String) f in _fields) ...<Widget>[
          Text(f.$2, style: AppText.label.copyWith(color: AppColors.sand)),
          const SizedBox(height: 4),
          TextField(
            controller: _c[f.$1],
            minLines: 2,
            maxLines: 6,
            style: AppText.body,
            decoration: InputDecoration(
              hintText: f.$3,
              hintStyle: AppText.caption,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          children: <Widget>[
            FilledButton(
              onPressed: () async {
                final ScaffoldMessengerState m = ScaffoldMessenger.of(context);
                await _store.save(_current());
                m.showSnackBar(
                  const SnackBar(content: Text('Saved on this device.')),
                );
              },
              child: const Text('Save'),
            ),
            OutlinedButton(
              onPressed: () => copyWithFeedback(
                context,
                _current().exportText(),
                message: 'Copied.',
              ),
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () async {
                final bool? ok = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text('Delete my safety plan?'),
                    content: const Text('This cannot be undone.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Keep'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await _store.clear();
                  for (final TextEditingController c in _c.values) {
                    c.clear();
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ],
    );
  }
}
