/// Hifz planner screen — pace, projection, today's three lanes.
library;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/hifz_providers.dart';
import '../domain/hifz_planner.dart';
import 'hifz_surah_picker.dart';
import '../domain/hifz_progress.dart';

class HifzPlannerScreen extends ConsumerStatefulWidget {
  const HifzPlannerScreen({this.initialSurah, super.key});

  /// Opens the planner on this surah (from the Qur'an reader's "Memorise
  /// this surah"). Null keeps the saved plan. Out-of-range values are ignored.
  final int? initialSurah;

  @override
  ConsumerState<HifzPlannerScreen> createState() => _HifzPlannerScreenState();
}

class _HifzPlannerScreenState extends ConsumerState<HifzPlannerScreen> {
  /// The plan and the memorised ranges, kept on this device.
  HifzState _hifz = const HifzState();

  // The range being written down: ayat from..to of the target surah.
  int _from = 1;
  int _to = 1;

  /// Lane pieces ticked as done today ("new:78:1-3"). Kept on this device for
  /// the day only; not a count, not a streak.
  Set<String> _laneDone = <String>{};

  String get _laneDoneKey =>
      'ar.academy.hifz.lanes.${hifzDayNumber(DateTime.now())}';

  int get _targetSurah => _hifz.workingSurah;
  int get _dailyAyat => _hifz.dailyNewAyat;

  @override
  void initState() {
    super.initState();
    try {
      _hifz = HifzState.decode(
          ref.read(sharedPreferencesProvider).getString(kHifzPref));
    } catch (_) {
      // No device storage (a bare test harness): the default plan.
    }
    try {
      final SharedPreferences p = ref.read(sharedPreferencesProvider);
      _laneDone = (p.getStringList(_laneDoneKey) ?? const <String>[]).toSet();
      // Yesterday's ticks are dropped so the store does not grow.
      for (final String k in p.getKeys().toList()) {
        if (k.startsWith('ar.academy.hifz.lanes.') && k != _laneDoneKey) {
          p.remove(k);
        }
      }
    } catch (_) {}
    final int? want = widget.initialSurah;
    if (want != null && want >= 1 && want <= 114) {
      _hifz = _hifz.withPlan(surah: want);
      _to = 1;
    }
  }

  void _set(HifzState next) {
    setState(() {
      _hifz = next;
      final int max = ayatInSurah(next.workingSurah);
      if (_from > max) _from = max;
      if (_to > max) _to = max;
      if (_to < _from) _to = _from;
    });
    try {
      ref.read(sharedPreferencesProvider).setString(kHifzPref, next.encode());
    } catch (_) {}
    ref.read(hifzTickProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final HifzPlan plan = HifzPlan(
      targetSurah: _targetSurah,
      dailyNewAyat: _dailyAyat,
    );
    final int ayat = ayatInSurah(_targetSurah);
    final int left = _hifz.remainingInTarget;
    final DateTime done = plan.projectedCompletion(left, DateTime.now());
    final bool juz = _hifz.juzAmma;
    final HifzDay today = _hifz.dayFor(DateTime.now());

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'Hifz Planner'),
              GlassCard(
                strong: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Your plan', style: AppText.caption),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          key: const Key('hifz-plan-juz'),
                          label: const Text('Juz Amma'),
                          selected: juz,
                          onSelected: (bool _) =>
                              _set(_hifz.withPlan(juzAmma: true)),
                        ),
                        ChoiceChip(
                          key: const Key('hifz-plan-surah'),
                          label: const Text('One surah'),
                          selected: !juz,
                          onSelected: (bool _) =>
                              _set(_hifz.withPlan(juzAmma: false)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Your pace', style: AppText.caption),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: HifzSurahPicker(
                              value: _targetSurah,
                              onChanged: (v) => _set(_hifz.withPlan(surah: v))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _Step(label: 'New ayat/day', value: _dailyAyat,
                              min: 1, max: 20,
                              onChanged: (v) => _set(_hifz.withPlan(daily: v))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      juz
                          ? (left == 0
                              ? 'All ${juzAmmaAyat()} ayat of Juz Amma are on your list. '
                                  'A teacher or checker confirms it; this is your own list.'
                              : 'Juz Amma is surahs $kJuzAmmaFirstSurah to $kJuzAmmaLastSurah, ${juzAmmaAyat()} ayat. '
                                  'You have written down ${_hifz.juzAmmaMemorised} ($left still to do). '
                                  'We start with An-Nas and go back to An-Naba, because the short surahs are the ones you already pray. '
                                  'At $_dailyAyat ayat a day it completes around '
                                  '${done.year}-${done.month.toString().padLeft(2, '0')}-${done.day.toString().padLeft(2, '0')}, '
                                  'if no day is missed. '
                                  'A teacher may set a different pace — this is your compass, not your judge.')
                          : (left == 0
                              ? 'Surah $_targetSurah (${hifzSurahName(_targetSurah)}) has $ayat ayat, and you have marked all of them as memorised. '
                                  'A teacher or checker confirms it; this is your own list.'
                              : 'Surah $_targetSurah (${hifzSurahName(_targetSurah)}) has $ayat ayat'
                                  '${left == ayat ? '' : ' ($left still to do)'}. '
                                  'At $_dailyAyat ayat a day it completes around '
                                  '${done.year}-${done.month.toString().padLeft(2, '0')}-${done.day.toString().padLeft(2, '0')}. '
                                  'A teacher may set a different pace — this is your compass, not your judge.'),
                      key: const Key('hifz-summary'),
                      style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text('Your plan is kept on this device.',
                        style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _memorisedCard(ayat),
              const SizedBox(height: 12),
              _linksCard(),
              const SizedBox(height: 12),
              _lanesCard(today),
              const SizedBox(height: 12),
              GlassCard(
                child: Text(
                  'Revision is the heart of memorization. The Prophet \ufdfa said: “Commit yourselves to the Qur’an, for it escapes from people’s memory faster than a camel from its tether” (Bukhari 5033, paraphrased). Recite today’s blocks to your checker.',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                strong: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Where to begin",
                        style: AppText.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      "Start with what you already pray: Al-Fatihah and the short surahs of Juz Amma "
                      "(Al-Ikhlas, Al-Falaq, An-Nas). What you recite every day is the easiest to keep. "
                      "The Juz Amma plan begins with An-Nas. Choose One surah above to work on any other.",
                      style: AppText.bodyMuted.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Text("[Interpretive: start-where-you-pray method]",
                        style: AppText.bodyMuted.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Ayat 4-6 of Surah 112 (Al-Ikhlas)".
  String _chunkText(AyahChunk c) =>
      'Surah ${c.surah} (${hifzSurahName(c.surah)}), ayat ${c.from == c.to ? '${c.from}' : '${c.from}–${c.to}'}';

  void _toggleLane(String id) {
    setState(() {
      if (!_laneDone.remove(id)) _laneDone.add(id);
    });
    try {
      ref
          .read(sharedPreferencesProvider)
          .setStringList(_laneDoneKey, _laneDone.toList());
    } catch (_) {}
  }

  Widget _laneRow(int n, String name, String text, AyahChunk? open, Key key,
      {String? doneId}) {
    final bool done = doneId != null && _laneDone.contains(doneId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (doneId != null)
            Semantics(
              label: '$name lane, ${done ? 'done today' : 'not done yet'}',
              child: SizedBox(
                width: 40,
                height: 40,
                child: Checkbox(
                  key: Key('hifz-done-$name'),
                  value: done,
                  onChanged: (_) => _toggleLane(doneId),
                ),
              ),
            ),
          Text('$n.  ', style: AppText.body.copyWith(color: AppColors.gold)),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                      text: '$name: ',
                      style: AppText.body.copyWith(color: AppColors.gold)),
                  TextSpan(text: text, style: AppText.body),
                ],
              ),
            ),
          ),
          if (open != null)
            TextButton(
              key: key,
              onPressed: () =>
                  context.open(AppRoutes.surahAt(open.surah, open.from)),
              child: const Text('Open'),
            ),
        ],
      ),
    );
  }

  /// Today's three lanes, worked out from what you have written down.
  Widget _lanesCard(HifzDay day) {
    final AyahChunk? fresh = day.fresh;
    final List<AyahChunk> recent = day.recent;
    final AyahChunk? older = day.older;
    final int shown = recent.length > 4 ? 4 : recent.length;
    return GlassCard(
      key: const Key('hifz-lanes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Today’s three lanes',
              style: AppText.titleMedium.copyWith(color: AppColors.gold)),
          const SizedBox(height: 10),
          _laneRow(
            1,
            'New',
            fresh == null
                ? 'nothing left in this plan. Choose another surah above.'
                : _chunkText(fresh),
            fresh,
            const Key('hifz-open-new'),
            doneId: fresh == null ? null : 'new:${fresh.surah}:${fresh.from}-${fresh.to}',
          ),
          _laneRow(
            2,
            'Recent',
            recent.isEmpty
                ? 'nothing written down in the last $kRecentDays days.'
                : '${recent.take(shown).map(_chunkText).join('; ')}'
                    '${recent.length > shown ? ' and ${recent.length - shown} more' : ''}',
            recent.isEmpty ? null : recent.first,
            const Key('hifz-open-recent'),
            doneId: recent.isEmpty ? null : 'recent:${recent.take(shown).join(',')}',
          ),
          _laneRow(
            3,
            'Older',
            older == null
                ? 'nothing yet. What you write down stays in Recent for $kRecentDays days, then joins the older sections.'
                : _chunkText(older),
            older,
            const Key('hifz-open-older'),
            doneId: older == null ? null : 'older:${older.surah}:${older.from}-${older.to}',
          ),
          const SizedBox(height: 6),
          Text(
            'Worked out from the ranges you wrote down. One older section a day, in turn. '
            '[Interpretive: sabaq, sabqi and manzil as hifz circles teach them; a teacher sets your real pace.]',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  /// Where to read and test yourself, and where your progress shows.
  Widget _linksCard() {
    return GlassCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          OutlinedButton.icon(
            key: const Key('hifz-open-surah'),
            onPressed: () => context.open(AppRoutes.surah(_targetSurah)),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: Text('Read surah $_targetSurah and test yourself'),
          ),
          OutlinedButton.icon(
            key: const Key('hifz-open-journey'),
            onPressed: () => context.open(AppRoutes.journey),
            icon: const Icon(Icons.timeline, size: 18),
            label: const Text('See my progress'),
          ),
        ],
      ),
    );
  }

  /// The ayat of the target surah the learner marks as memorised, as ranges.
  Widget _memorisedCard(int ayat) {
    final List<AyahRange> mine =
        _hifz.memorised[_targetSurah] ?? const <AyahRange>[];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('What you have memorised',
              style: AppText.titleMedium.copyWith(color: AppColors.gold)),
          const SizedBox(height: 4),
          Text(
            'Your own list for Surah $_targetSurah (${hifzSurahName(_targetSurah)}). Write down a range when '
            'you have recited it to your teacher or checker.',
            style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 8),
          if (mine.isEmpty)
            Text('Nothing marked yet.',
                key: const Key('hifz-none'), style: AppText.caption)
          else
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (int i = 0; i < mine.length; i++)
                  InputChip(
                    key: Key('hifz-range-$i'),
                    label: Text('Ayat ${mine[i]}',
                        style: const TextStyle(fontSize: 14)),
                    onDeleted: () => _set(_hifz.removeRange(_targetSurah, i)),
                    deleteButtonTooltipMessage: 'Remove this range',
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _Step(
                    label: 'From ayah',
                    value: _from,
                    min: 1,
                    max: ayat,
                    onChanged: (int v) => setState(() {
                          _from = v;
                          if (_to < _from) _to = _from;
                        })),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Step(
                    label: 'To ayah',
                    value: _to,
                    min: 1,
                    max: ayat,
                    onChanged: (int v) => setState(() {
                          _to = v;
                          if (_from > _to) _from = _to;
                        })),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('hifz-add'),
              onPressed: () =>
                  _set(_hifz.addRange(_targetSurah, _from, _to,
                      day: hifzDayNumber(DateTime.now()))),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Mark as memorised'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppText.caption),
        Row(
          children: <Widget>[
            IconButton(tooltip: 'Less: $label', icon: const Icon(Icons.remove_circle_outline, color: AppColors.gold, size: 20),
                onPressed: value > min ? () => onChanged(value - 1) : null),
            Semantics(label: '$label: $value', excludeSemantics: true, child: Text('$value', style: AppText.body.copyWith(color: AppColors.gold))),
            IconButton(tooltip: 'More: $label', icon: const Icon(Icons.add_circle_outline, color: AppColors.gold, size: 20),
                onPressed: value < max ? () => onChanged(value + 1) : null),
          ],
        ),
      ],
    );
  }
}
