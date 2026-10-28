import '../../../app/core/scholar_review.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../prayer/application/prayer_providers.dart';
import '../../zakat/domain/zakat_calculation.dart';
import '../../zakat/presentation/zakat_cards.dart';
import '../domain/ramadan_season.dart';
import '../../../app/theme/widgets/focus_ring.dart';

class RamadanDay {
  final int day; final String theme, arabic, text, source;

  /// Latin-letter reading of [arabic] and where it came from (JSON `translit`
  /// and `translitSource`). Null when the day has none.
  final String? translit, translitSource;
  const RamadanDay({required this.day, required this.theme, required this.arabic,
      required this.text, required this.source, this.translit, this.translitSource});
  factory RamadanDay.fromJson(Map<String, dynamic> j) => RamadanDay(
      day: (j['day'] as num).toInt(), theme: j['theme'] as String, arabic: j['arabic'] as String,
      text: j['text'] as String, source: j['source'] as String,
      translit: j['translit'] as String?, translitSource: j['translitSource'] as String?);
}

final ramadanDaysProvider = FutureProvider<List<RamadanDay>>((ref) async {
  final raw = await rootBundle.loadString('assets/finance/ramadan.json');
  final d = json.decode(raw) as Map<String, dynamic>;
  return (d['days'] as List<dynamic>)
      .map((e) => RamadanDay.fromJson(e as Map<String, dynamic>)).toList();
});

/// RAMADAN MODE — the complete season, both layers the founder demanded:
/// WORSHIP (fasting log with three honest states, 30-juz khatam tracker,
/// taraweeh notes, live suhoor/iftar countdowns from real prayer times)
/// and HOUSEHOLD (sadaqah tracker, iftar table planner, zakat al-fitr
/// calculator). Nothing cheapened: the season is the app's heartbeat.
///
/// Everything the user records is saved per Ramadan (keyed by Hijri year),
/// and the text fields keep their own controllers, so the 30-second clock
/// tick never wipes what is being typed.
class RamadanScreen extends ConsumerStatefulWidget {
  const RamadanScreen({super.key});
  @override
  ConsumerState<RamadanScreen> createState() => _RamadanState();
}

class _RamadanState extends ConsumerState<RamadanScreen> {
  /// The Ramadan being tracked, fixed for the life of the screen.
  late final RamadanSeason _season = RamadanSeason.forDate(DateTime.now());

  int _tab = 0;
  Map<int, int> _fast = {};            // day -> 0 none, 1 fasted, 2 excused, 3 makeup-due
  Set<int> _juz = {};                  // completed juz
  List<String> _sadaqah = [];          // "$amount|note|date"
  List<String> _table = [];            // iftar table guests/dishes
  Timer? _tick;
  Timer? _taraweehSave;

  // Hoisted so a rebuild (the 30 s clock tick, any setState) never replaces
  // them and never wipes half-typed text or the cursor position.
  final TextEditingController _taraweehCtrl = TextEditingController();
  final TextEditingController _sadaqahCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _tableCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    if (_taraweehSave?.isActive ?? false) {
      _taraweehSave!.cancel();
      unawaited(_saveTaraweeh());
    }
    _taraweehCtrl.dispose();
    _sadaqahCtrl.dispose();
    _noteCtrl.dispose();
    _tableCtrl.dispose();
    super.dispose();
  }

  /// Season-scoped read. The first release saved unscoped keys while it was
  /// hard-wired to Ramadan 1448, so those old values are read for 1448 only
  /// (and never deleted).
  T? _read<T>(SharedPreferences p, String name, T? Function(String key) get) {
    final T? scoped = get(_season.key(name));
    if (scoped != null) return scoped;
    if (_season.hijriYear == 1448) return get('ar.ramadan.$name');
    return null;
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final f = _read<String>(p, 'fast', p.getString);
      if (f != null) {
        try {
          _fast = (json.decode(f) as Map).map((k, v) =>
              MapEntry(int.parse('$k'), (v as num).toInt()));
        } catch (_) {
          _fast = {};
        }
      }
      _juz = (_read<List<String>>(p, 'juz', p.getStringList) ?? [])
          .map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
      _taraweehCtrl.text = _read<String>(p, 'taraweeh', p.getString) ?? '';
      _sadaqah = (_read<List<String>>(p, 'sadaqah', p.getStringList) ?? []).toList();
      _table = (_read<List<String>>(p, 'table', p.getStringList) ?? []).toList();
    });
  }

  Future<void> _saveFast() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_season.key('fast'),
        json.encode(_fast.map((k, v) => MapEntry('$k', v))));
  }

  Future<void> _saveJuz() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_season.key('juz'), _juz.map((e) => '$e').toList());
  }

  Future<void> _saveTaraweeh() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_season.key('taraweeh'), _taraweehCtrl.text);
  }

  Future<void> _saveSadaqah() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_season.key('sadaqah'), _sadaqah);
  }

  Future<void> _saveTable() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_season.key('table'), _table);
  }

  void _onTaraweehChanged(String _) {
    _taraweehSave?.cancel();
    _taraweehSave = Timer(const Duration(milliseconds: 600), () {
      unawaited(_saveTaraweeh());
    });
  }

  bool get _inRamadan => _season.contains(DateTime.now());

  int get _ramadanDay => _season.dayOf(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(ramadanDaysProvider);
    final times = ref.watch(prayerTimesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(children: [
            const ScreenHeader(title: 'Ramadan Mode', close: true),
            const ScholarReviewNote(
              reviewKey: 'dua.ramadan',
              padding: const EdgeInsets.only(bottom: 8),
            ),
            Expanded(child: days.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => Center(child: Text('Could not load Ramadan.', style: AppText.bodyMuted)),
              data: (list) {
                final day = _ramadanDay;
                final today = _inRamadan && day >= 1 && day <= list.length
                    ? list[day - 1] : null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // SEASON HEADER + LIVE COUNTDOWNS
                    GlassCard(strong: true, child: Column(children: [
                      Text(_inRamadan
                              ? 'RAMADAN ${_season.hijriYear} · DAY $day OF ${_season.length}'
                              : 'UNTIL RAMADAN ${_season.hijriYear}', style: AppText.eyebrow),
                      const SizedBox(height: 6),
                      Text(_inRamadan ? 'Ramadan Mubarak' : _countdownText(),
                          style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 24,
                              color: AppColors.goldLight)),
                      if (!_inRamadan && _season.daysUntilStart(DateTime.now()) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            key: const Key('ramadan-expected-date'),
                            _expectedText(),
                            textAlign: TextAlign.center,
                            style: AppText.bodyMuted,
                          ),
                        ),
                      if (today != null) ...[
                        const SizedBox(height: 8),
                        Text('Today\'s theme: ${today.theme}', style: AppText.bodyMuted),
                        if (today.arabic.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(today.arabic,
                              key: const Key('ramadan-today-arabic'),
                              textAlign: TextAlign.center,
                              textDirection: ui.TextDirection.rtl,
                              style: AppText.arabic.copyWith(
                                  fontSize: 22, height: 1.9, color: AppColors.sand)),
                        ],
                        if (today.translit != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Text(today.translit!,
                                key: const Key('ramadan-today-translit'),
                                textAlign: TextAlign.center,
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 13, height: 1.5, fontStyle: FontStyle.italic)),
                          ),
                        if (today.translit != null && today.translitSource != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('Transliteration: ${today.translitSource!}',
                                key: const Key('ramadan-today-translit-source'),
                                textAlign: TextAlign.center,
                                style: AppText.bodyMuted.copyWith(fontSize: 12)),
                          ),
                        Text(today.text, textAlign: TextAlign.center,
                            style: AppText.body.copyWith(height: 1.5, fontSize: 13)),
                        Text(today.source, textAlign: TextAlign.center,
                            style: AppText.bodyMuted.copyWith(fontSize: 12)),
                      ],
                      if (!ref.watch(prayerLocationProvider).isSet)
                        if (_inRamadan)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Set your location in Prayer Times to see suhoor and iftar countdowns.',
                              textAlign: TextAlign.center,
                              style: AppText.bodyMuted.copyWith(fontSize: 12),
                            ),
                          )
                        else
                          const SizedBox.shrink()
                      else
                      times.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (t) {
                          if (!_inRamadan) return const SizedBox.shrink();
                          final w = t.wallClock(DateTime.now());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                              _countdownChip(
                                  w.isBefore(t.fajr) ? 'SUHOOR ENDS IN' : 'NEXT SUHOOR ENDS IN',
                                  _fmt(_untilNext(t.fajr, w))),
                              _countdownChip(
                                  w.isBefore(t.maghrib) ? 'IFTAR IN' : 'NEXT IFTAR IN',
                                  _fmt(_untilNext(t.maghrib, w))),
                            ]),
                          );
                        },
                      ),
                    ])),
                    const SizedBox(height: 10),
                    // TABS
                    Row(children: [
                      for (final (_, t) in [('Worship', 0), ('Household', 1)].indexed)
                        Expanded(child: FocusableTap(
                          onTap: () => setState(() => _tab = t.$2),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            constraints: const BoxConstraints(minHeight: 44),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _tab == t.$2
                                  ? AppColors.gold : AppColors.sand.withValues(alpha: 0.2)),
                            ),
                            child: Text(t.$1, textAlign: TextAlign.center,
                                style: AppText.body.copyWith(fontSize: 12.5,
                                    color: _tab == t.$2 ? AppColors.goldLight : AppColors.sand)),
                          ),
                        )),
                    ]),
                    const SizedBox(height: 10),
                    if (_tab == 0) _worship() else _household(),
                  ],
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  /// Time until the next occurrence of [target] (a wall-clock time today in
  /// the schedule's zone): today's if still ahead, otherwise tomorrow's.
  Duration _untilNext(DateTime target, DateTime wallNow) {
    var d = target.difference(wallNow);
    if (d.isNegative) d = d + const Duration(hours: 24);
    return d;
  }

  String _fmt(Duration d) =>
      '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';

  String _countdownText() {
    final d = _season.daysUntilStart(DateTime.now());
    return d > 0 ? '$d days' : 'Any day now';
  }

  /// The calendar date the countdown is counting to, in plain words.
  String _expectedText() =>
      'Expected around ${DateFormat('EEEE d MMMM y').format(_season.start)}. '
      'The new moon decides the exact day.';

  Widget _countdownChip(String label, String time) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
    ),
    child: Column(children: [
      Text(label, style: AppText.eyebrow.copyWith(fontSize: 12)),
      Text(time, style: AppText.body.copyWith(
          fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.goldLight)),
    ]),
  );

  /// How a fasting day is named, for the screen reader and the symbol.
  static String fastStateName(int state) => switch (state) {
        1 => 'fasted',
        2 => 'excused',
        3 => 'to make up',
        _ => 'not marked',
      };

  /// One day of the fasting log: 44 px square, the state is spoken and drawn
  /// as a symbol (never by colour alone), reachable and operable by keyboard.
  Widget _fastCell(int d) {
    final int st = _fast[d] ?? 0;
    final IconData? mark = switch (st) {
      1 => Icons.check,
      2 => Icons.remove,
      3 => Icons.replay,
      _ => null,
    };
    return Semantics(
      button: true,
      label: 'Day $d, ${fastStateName(st)}',
      hint: 'Tap to change',
      excludeSemantics: true,
      onTap: () => _cycleFast(d),
      child: FocusableTap(
        key: Key('fast-day-$d'),
        borderRadius: 10,
        onTap: () => _cycleFast(d),
        child: Container(
          width: 44, height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: st == 1 ? AppColors.gold.withValues(alpha: 0.35)
                : st == 2 ? AppColors.sand.withValues(alpha: 0.25)
                : st == 3 ? AppColors.sand.withValues(alpha: 0.12)
                : const Color(0x1405090F),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$d', style: TextStyle(
                fontSize: 12,
                color: AppColors.sand)),
            SizedBox(
              height: 14,
              child: mark == null
                  ? null
                  : Icon(mark, size: 12,
                      color: AppColors.goldLight),
            ),
          ]),
        ),
      ),
    );
  }

  void _cycleFast(int d) => setState(() {
        _fast[d] = ((_fast[d] ?? 0) + 1) % 4;
        unawaited(_saveFast());
      });

  /// One juz of the khatam tracker.
  Widget _juzCell(int j) {
    final bool done = _juz.contains(j);
    void toggle() => setState(() {
          done ? _juz.remove(j) : _juz.add(j);
          unawaited(_saveJuz());
        });
    return Semantics(
      button: true,
      selected: done,
      label: 'Juz $j, ${done ? 'completed' : 'not completed'}',
      excludeSemantics: true,
      onTap: toggle,
      child: FocusableTap(
        key: Key('juz-$j'),
        borderRadius: 10,
        onTap: toggle,
        child: Container(
          width: 44, height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: done ? AppColors.gold.withValues(alpha: 0.4) : const Color(0x1405090F),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$j', style: TextStyle(fontSize: 12,
                color: done ? AppColors.goldLight : AppColors.sand)),
            SizedBox(
              height: 14,
              child: done
                  ? const Icon(Icons.check, size: 12, color: AppColors.goldLight)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }

  /// Asks before a saved entry is removed (it cannot be undone).
  Future<bool> _confirmRemove(String what) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        semanticLabel: 'Remove this entry?',
        backgroundColor: const Color(0xFF0A0F18),
        title: Text('Remove this entry?', style: AppText.titleMedium),
        content: Text(what, style: AppText.bodyMuted),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// The small "remove" control on a saved line: 44 px, labelled.
  Widget _removeButton(String label, Future<void> Function() onConfirmed) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: () => unawaited(onConfirmed()),
      child: FocusableTap(
        onTap: () => unawaited(onConfirmed()),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.close, size: 18, color: AppColors.sand),
        ),
      ),
    );
  }

  // ---------------- WORSHIP LAYER ----------------
  Widget _worship() {
    final fasted = _fast.values.where((v) => v == 1).length;
    final excused = _fast.values.where((v) => v == 2).length;
    final makeup = _fast.values.where((v) => v == 3).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FASTING LOG · $fasted fasted · $excused excused · $makeup to make up',
          style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: Wrap(spacing: 4, runSpacing: 4, children: [
        for (var d = 1; d <= _season.length; d++) _fastCell(d),
      ])),
      Text('Tap a day to change it: not marked → fasted → excused → to make up. '
          'A fast not kept for a valid reason is made up on other days '
          '(Qur’an 2:184). Each day also shows its state as a symbol and in '
          'words for a screen reader.', style: AppText.bodyMuted.copyWith(fontSize: 12)),
      const SizedBox(height: 12),
      Text('QUR’AN KHATAM · ${_juz.length}/30 ajza', style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: Wrap(spacing: 4, runSpacing: 4, children: [
        for (var j = 1; j <= 30; j++) _juzCell(j),
      ])),
      const SizedBox(height: 12),
      Text('TARAWEEH NOTES', style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: Semantics(label: 'Which surahs tonight · the imam’s recitation · a verse that stopped you…', child: TextField(
        key: const Key('taraweeh-notes'),
        maxLines: 4, style: AppText.body,
        controller: _taraweehCtrl,
        onChanged: _onTaraweehChanged,
        decoration: const InputDecoration(
            hintText: 'Which surahs tonight · the imam’s recitation · a verse that stopped you…'),
      ))),
    ]);
  }

  // ---------------- HOUSEHOLD LAYER ----------------
  void _recordSadaqah() {
    final amt = ZakatCalculation.parseAmount(_sadaqahCtrl.text);
    if (amt <= 0) return;
    final shown = amt == amt.roundToDouble() ? amt.toStringAsFixed(0) : amt.toStringAsFixed(2);
    // '|' separates the stored fields, so it cannot appear inside the note.
    final note = _noteCtrl.text.trim().replaceAll('|', '/');
    setState(() {
      _sadaqah.insert(0, '$shown|$note|${DateTime.now().toIso8601String().substring(0, 10)}');
    });
    unawaited(_saveSadaqah());
    _sadaqahCtrl.clear();
    _noteCtrl.clear();
  }

  static List<String> _fields(String entry) {
    final parts = entry.split('|');
    return [for (var i = 0; i < 3; i++) i < parts.length ? parts[i] : ''];
  }

  Widget _household() {
    final total = _sadaqah.fold<double>(0, (a, e) =>
        a + (double.tryParse(_fields(e)[0]) ?? 0));
    final totalShown = total == total.roundToDouble()
        ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SADAQAH TRACKER · $totalShown given this season',
          style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: Column(children: [
        Row(children: [
          Expanded(child: Semantics(label: 'Amount', child: TextField(controller: _sadaqahCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Amount')))),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Semantics(label: 'For whom / what cause', child: TextField(controller: _noteCtrl,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'For whom / what cause')))),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _recordSadaqah,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0A0F18)),
            child: const Text('Record sadaqah'),
          )),
        for (final e in _sadaqah.take(10))
          Padding(padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Text(_fields(e)[0], style: AppText.body.copyWith(
                  color: AppColors.goldLight, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                  [_fields(e)[1], _fields(e)[2]].where((s) => s.isNotEmpty).join(' · '),
                  style: AppText.bodyMuted.copyWith(fontSize: 12))),
              _removeButton('Remove this sadaqah entry', () async {
                if (!await _confirmRemove(
                    'This sadaqah entry will be removed from your list.')) {
                  return;
                }
                if (!mounted) return;
                setState(() => _sadaqah.remove(e));
                unawaited(_saveSadaqah());
              }),
            ])),
      ])),
      const SizedBox(height: 12),
      Text('IFTAR TABLE · who\'s breaking fast with you', style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: Column(children: [
        Row(children: [
          Expanded(child: Semantics(label: 'A guest, a dish, a date to remember…', child: TextField(controller: _tableCtrl, style: AppText.body,
              decoration: const InputDecoration(hintText: 'A guest, a dish, a date to remember…')))),
          IconButton(tooltip: 'Add to the iftar table', icon: const Icon(Icons.add, color: AppColors.gold),
              onPressed: () {
                if (_tableCtrl.text.trim().isEmpty) return;
                setState(() => _table.insert(0, _tableCtrl.text.trim()));
                unawaited(_saveTable());
                _tableCtrl.clear();
              }),
        ]),
        for (final t in _table)
          Padding(padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Expanded(child: Text(t, style: AppText.body.copyWith(fontSize: 13))),
              _removeButton('Remove from the iftar table', () async {
                if (!await _confirmRemove(
                    '“$t” will be removed from the iftar table.')) {
                  return;
                }
                if (!mounted) return;
                setState(() => _table.remove(t));
                unawaited(_saveTable());
              }),
            ])),
        if (_table.isEmpty)
          Text('The Prophet ﷺ said: whoever feeds a fasting person has a reward like theirs (Tirmidhi 807, sahih per Darussalam). Plan the table — the reward is booked by the intention.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5)),
      ])),
      const SizedBox(height: 12),
      const ZakatAlFitrCard(),
    ]);
  }
}
