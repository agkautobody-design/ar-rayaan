import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../prayer/application/prayer_providers.dart';
import '../../prayer/domain/prayer_times.dart';

class RamadanDay {
  final int day; final String theme, arabic, text, source;
  const RamadanDay({required this.day, required this.theme, required this.arabic,
      required this.text, required this.source});
  factory RamadanDay.fromJson(Map<String, dynamic> j) => RamadanDay(
      day: (j['day'] as num).toInt(), theme: j['theme'], arabic: j['arabic'],
      text: j['text'], source: j['source']);
}

final ramadanDaysProvider = FutureProvider<List<RamadanDay>>((ref) async {
  final raw = await rootBundle.loadString('assets/finance/ramadan.json');
  final d = json.decode(raw) as Map<String, dynamic>;
  return (d['days'] as List<dynamic>)
      .map((e) => RamadanDay.fromJson(e as Map<String, dynamic>)).toList();
});

final ramadanStart = DateTime(2027, 2, 17);

/// RAMADAN MODE — the complete season, both layers the founder demanded:
/// WORSHIP (fasting log with three honest states, 30-juz khatam tracker,
/// taraweeh notes, live suhoor/iftar countdowns from real prayer times)
/// and HOUSEHOLD (sadaqah tracker, iftar table planner, zakat al-fitr
/// reminder). Nothing cheapened: the season is the app's heartbeat.
class RamadanScreen extends ConsumerStatefulWidget {
  const RamadanScreen({super.key});
  @override
  ConsumerState<RamadanScreen> createState() => _RamadanState();
}

class _RamadanState extends ConsumerState<RamadanScreen> {
  int _tab = 0;
  Map<int, int> _fast = {};            // day -> 0 none, 1 fasted, 2 excused, 3 makeup-due
  Set<int> _juz = {};                  // completed juz
  String _taraweeh = '';
  List<String> _sadaqah = [];          // "$amount|note|date"
  List<String> _table = [];            // iftar table guests/dishes
  Timer? _tick;

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
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      final f = p.getString('ar.ramadan.fast');
      if (f != null) _fast = (json.decode(f) as Map).map((k, v) => MapEntry((k as num).toInt(), (v as num).toInt()));
      _juz = (p.getStringList('ar.ramadan.juz') ?? []).map((e) => int.parse(e)).toSet();
      _taraweeh = p.getString('ar.ramadan.taraweeh') ?? '';
      _sadaqah = (p.getStringList('ar.ramadan.sadaqah') ?? []).toList();
      _table = (p.getStringList('ar.ramadan.table') ?? []).toList();
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ar.ramadan.fast', json.encode(_fast));
    await p.setStringList('ar.ramadan.juz', _juz.map((e) => '$e').toList());
    await p.setString('ar.ramadan.taraweeh', _taraweeh);
    await p.setStringList('ar.ramadan.sadaqah', _sadaqah);
    await p.setStringList('ar.ramadan.table', _table);
  }

  bool get _inRamadan {
    final now = DateTime.now();
    return now.isAfter(ramadanStart) && now.isBefore(ramadanStart.add(const Duration(days: 30)));
  }

  int get _ramadanDay => DateTime.now().difference(ramadanStart).inDays + 1;

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
            Expanded(child: days.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => Center(child: Text('Could not load Ramadan.', style: AppText.bodyMuted)),
              data: (list) {
                final today = _inRamadan && _ramadanDay <= 30 ? list[_ramadanDay - 1] : null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // SEASON HEADER + LIVE COUNTDOWNS
                    GlassCard(strong: true, child: Column(children: [
                      Text(_inRamadan ? 'RAMADAN 1448 \u00b7 DAY $_ramadanDay OF 30'
                              : 'UNTIL RAMADAN 1448', style: AppText.eyebrow),
                      const SizedBox(height: 6),
                      Text(_inRamadan ? 'Ramadan Mubarak' : _countdownText(),
                          style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 24,
                              color: AppColors.goldLight)),
                      if (today != null) ...[
                        const SizedBox(height: 8),
                        Text('Today\'s theme: ${today.theme}', style: AppText.bodyMuted),
                        Text(today.text, textAlign: TextAlign.center,
                            style: AppText.body.copyWith(height: 1.5, fontSize: 13)),
                        Text(today.source, style: AppText.bodyMuted.copyWith(fontSize: 9.5)),
                      ],
                      times.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (t) {
                          if (!_inRamadan) return const SizedBox.shrink();
                          final now = DateTime.now();
                          final suhoor = _fmt(_until(t.fajr, now));
                          final iftar = _fmt(_until(t.maghrib, now));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                              _countdownChip('SUHOOR ENDS', suhoor),
                              _countdownChip('IFTAR', iftar),
                            ]),
                          );
                        },
                      ),
                    ])),
                    const SizedBox(height: 10),
                    // TABS
                    Row(children: [
                      for (final (i, t) in [('Worship', 0), ('Household', 1)].indexed)
                        Expanded(child: GestureDetector(
                          onTap: () => setState(() => _tab = t.$2),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
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
                    if (_tab == 0) _worship(list) else _household(),
                  ],
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  Duration _until(DateTime t, DateTime now) {
    var d = t.difference(now);
    if (d.isNegative) d = d + const Duration(hours: 24);
    return d;
  }

  String _fmt(Duration d) =>
      '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';

  String _countdownText() {
    final d = ramadanStart.difference(DateTime.now()).inDays;
    return d > 0 ? '\$d days \u00b7 crescent-willing' : 'Any day now';
  }

  Widget _countdownChip(String label, String time) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
    ),
    child: Column(children: [
      Text(label, style: AppText.eyebrow.copyWith(fontSize: 8.5)),
      Text(time, style: AppText.body.copyWith(
          fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.goldLight)),
    ]),
  );

  // ---------------- WORSHIP LAYER ----------------
  Widget _worship(List<RamadanDay> list) {
    final fasted = _fast.values.where((v) => v == 1).length;
    final excused = _fast.values.where((v) => v == 2).length;
    final makeup = _fast.values.where((v) => v == 3).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FASTING LOG \u00b7 $fasted fasted \u00b7 $excused excused \u00b7 $makeup makeup-due',
          style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: Wrap(spacing: 4, runSpacing: 4, children: [
        for (var d = 1; d <= 30; d++)
          GestureDetector(
            onTap: () => setState(() {
              _fast[d] = ((_fast[d] ?? 0) + 1) % 4;
              _save();
            }),
            child: Container(
              width: 34, height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _fast[d] == 1 ? AppColors.gold.withValues(alpha: 0.35)
                    : _fast[d] == 2 ? AppColors.sand.withValues(alpha: 0.25)
                    : _fast[d] == 3 ? Colors.orange.withValues(alpha: 0.25)
                    : const Color(0x1405090F),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
              ),
              child: Text('$d', style: TextStyle(
                  fontSize: 10.5,
                  color: _fast[d] == 3 ? Colors.orangeAccent : AppColors.sand)),
            ),
          ),
      ])),
      Text('tap cycles: none \u2192 fasted \u2192 excused \u2192 makeup-due \u00b7 the Gentle Ledger — '
          'missed fasts are debts to Allah, and He loves they be paid', style: AppText.bodyMuted.copyWith(fontSize: 9.5)),
      const SizedBox(height: 12),
      Text('QUR\u2019AN KHATAM \u00b7 ${_juz.length}/30 ajza', style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: Wrap(spacing: 4, runSpacing: 4, children: [
        for (var j = 1; j <= 30; j++)
          GestureDetector(
            onTap: () => setState(() {
              _juz.contains(j) ? _juz.remove(j) : _juz.add(j);
              _save();
            }),
            child: Container(
              width: 34, height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _juz.contains(j) ? AppColors.gold.withValues(alpha: 0.4) : const Color(0x1405090F),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
              ),
              child: Text('$j', style: TextStyle(fontSize: 10.5,
                  color: _juz.contains(j) ? AppColors.goldLight : AppColors.sand)),
            ),
          ),
      ])),
      const SizedBox(height: 12),
      Text('TARAWEEH NOTES', style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: TextField(
        maxLines: 4, style: AppText.body,
        controller: TextEditingController(text: _taraweeh)
          ..selection = TextSelection.collapsed(offset: _taraweeh.length),
        onChanged: (v) { _taraweeh = v; _save(); },
        decoration: const InputDecoration(
            hintText: 'Which surahs tonight \u00b7 the imam\u2019s recitation \u00b7 a verse that stopped you\u2026'),
      )),
    ]);
  }

  // ---------------- HOUSEHOLD LAYER ----------------
  Widget _household() {
    final total = _sadaqah.fold<double>(0, (a, e) =>
        a + (double.tryParse(e.split('|')[0]) ?? 0));
    final sadaqahCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final tableCtrl = TextEditingController();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SADAQAH TRACKER \u00b7 \$${total.toStringAsFixed(0)} given this season',
          style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: Column(children: [
        Row(children: [
          Expanded(child: TextField(controller: sadaqahCtrl,
              keyboardType: TextInputType.number, style: AppText.body,
              decoration: const InputDecoration(hintText: 'Amount (\$)'))),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: TextField(controller: noteCtrl,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'For whom / what cause'))),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(sadaqahCtrl.text);
              if (amt == null || amt <= 0) return;
              setState(() {
                _sadaqah.insert(0, '${amt.toStringAsFixed(0)}|${noteCtrl.text}|${DateTime.now().toIso8601String().substring(0, 10)}');
                _save();
              });
              sadaqahCtrl.clear(); noteCtrl.clear();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0A0F18)),
            child: const Text('Record sadaqah'),
          )),
        for (final e in _sadaqah.take(6))
          Padding(padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Text('\$${e.split('|')[0]}', style: AppText.body.copyWith(
                  color: AppColors.goldLight, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(child: Text('${e.split('|')[1]} \u00b7 ${e.split('|')[2]}',
                  style: AppText.bodyMuted.copyWith(fontSize: 11))),
            ])),
      ])),
      const SizedBox(height: 12),
      Text('IFTAR TABLE \u00b7 who\'s breaking fast with you', style: AppText.eyebrow),
      const SizedBox(height: 6),
      GlassCard(child: Column(children: [
        Row(children: [
          Expanded(child: TextField(controller: tableCtrl, style: AppText.body,
              decoration: const InputDecoration(hintText: 'A guest, a dish, a date to remember\u2026'))),
          IconButton(icon: const Icon(Icons.add, color: AppColors.gold),
              onPressed: () {
                if (tableCtrl.text.trim().isEmpty) return;
                setState(() { _table.insert(0, tableCtrl.text.trim()); _save(); });
                tableCtrl.clear();
              }),
        ]),
        for (final t in _table)
          Padding(padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Expanded(child: Text(t, style: AppText.body.copyWith(fontSize: 13))),
              GestureDetector(onTap: () => setState(() { _table.remove(t); _save(); }),
                  child: const Icon(Icons.close, size: 14, color: AppColors.sand)),
            ])),
        if (_table.isEmpty)
          Text('The Prophet ﷺ said: whoever feeds a fasting person has a reward like theirs (Tirmidhi 807). Plan the table — the reward is booked by the intention.',
              style: AppText.bodyMuted.copyWith(fontSize: 11, height: 1.5)),
      ])),
      const SizedBox(height: 12),
      GlassCard(child: Row(children: [
        const Icon(Icons.card_giftcard_outlined, color: AppColors.goldLight, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text('Zakat al-Fitr: due before the Eid prayer for every member of the household — the zakat engine holds the amount.',
            style: AppText.bodyMuted.copyWith(fontSize: 11.5, height: 1.5))),
      ])),
    ]);
  }
}
