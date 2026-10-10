import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';

class PaperCo {
  final String sym, name, sector, blurb;
  final double price, rev, debt, mcap, interest, haram;
  const PaperCo({required this.sym, required this.name, required this.sector,
      required this.blurb, required this.price, required this.rev,
      required this.debt, required this.mcap, required this.interest,
      required this.haram});
  factory PaperCo.fromJson(Map<String, dynamic> j) => PaperCo(
      sym: j['sym'], name: j['name'], sector: j['sector'], blurb: j['blurb'],
      price: (j['price'] as num).toDouble(), rev: (j['rev'] as num).toDouble(),
      debt: (j['debt'] as num).toDouble(), mcap: (j['mcap'] as num).toDouble(),
      interest: (j['interest'] as num).toDouble(),
      haram: (j['haram'] as num).toDouble());
  /// Deterministic daily drift so today's market is consistent, seeded by
  /// date+symbol. Fundamentals stay fixed; the weather changes.
  double get todayPrice {
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final rnd = Random('$day\$sym'.hashCode);
    final drift = (rnd.nextDouble() - 0.48) * 0.06;
    return double.parse((price * (1 + drift)).toStringAsFixed(2));
  }
}

final paperMarketProvider = FutureProvider<List<PaperCo>>((ref) async {
  final raw = await rootBundle.loadString('assets/finance/paper_market.json');
  final d = json.decode(raw) as Map<String, dynamic>;
  return (d['companies'] as List<dynamic>)
      .map((e) => PaperCo.fromJson(e as Map<String, dynamic>)).toList();
});

/// THE TRADING FLOOR — the practice half of Rayaan Stocks. $100,000 of paper
/// money, twelve companies with real fundamentals to screen, buy/sell with
/// real order math, a portfolio with P&L, an Islamic budget (sadaqah first),
/// a Hajj-fund savings tracker, and Rayaan — the teacher — one question away.
class TradingFloorScreen extends ConsumerStatefulWidget {
  const TradingFloorScreen({super.key});
  @override
  ConsumerState<TradingFloorScreen> createState() => _FloorState();
}

class _FloorState extends ConsumerState<TradingFloorScreen> {
  int _tab = 0;
  double _cash = 100000;
  Map<String, int> _holdings = {};
  List<String> _trades = [];

  final _qty = TextEditingController();
  final _income = TextEditingController();
  final _sadaqahPct = TextEditingController(text: '5');
  final _goalName = TextEditingController(text: 'Hajj fund');
  final _goalTarget = TextEditingController(text: '15000');
  final _goalSaved = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _cash = p.getDouble('ar.rayaan.cash') ?? 100000;
      final h = p.getString('ar.rayaan.holdings');
      if (h != null && h.isNotEmpty) {
        _holdings = (json.decode(h) as Map).map((k, v) => MapEntry(k as String, (v as num).toInt()));
      }
      _trades = (p.getStringList('ar.rayaan.trades') ?? []).toList();
      _goalSaved.text = (p.getDouble('ar.rayaan.goal') ?? 0).toStringAsFixed(0);
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('ar.rayaan.cash', _cash);
    await p.setString('ar.rayaan.holdings', json.encode(_holdings));
    await p.setStringList('ar.rayaan.trades', _trades);
    await p.setDouble('ar.rayaan.goal', double.tryParse(_goalSaved.text) ?? 0);
  }

  double _portfolioValue(List<PaperCo> market) {
    var v = 0.0;
    _holdings.forEach((sym, qty) {
      final co = market.where((c) => c.sym == sym).firstOrNull;
      if (co != null) v += co.todayPrice * qty;
    });
    return v;
  }

  Future<void> _trade(PaperCo co, bool buy) async {
    final qty = int.tryParse(_qty.text) ?? 0;
    if (qty <= 0) return;
    final cost = co.todayPrice * qty;
    if (buy && cost > _cash) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Not enough paper cash — this floor never allows debt, '
              'by design. Leverage is riba\'s door.'),
          backgroundColor: Color(0xFF0A0F18)));
      return;
    }
    if (!buy && (_holdings[co.sym] ?? 0) < qty) return;
    setState(() {
      if (buy) {
        _cash -= cost;
        _holdings[co.sym] = (_holdings[co.sym] ?? 0) + qty;
        _trades.insert(0, 'BUY  \$qty ${co.sym} @ \$${co.todayPrice}');
      } else {
        _cash += cost;
        final left = (_holdings[co.sym] ?? 0) - qty;
        if (left == 0) { _holdings.remove(co.sym); } else { _holdings[co.sym] = left; }
        _trades.insert(0, 'SELL \$qty ${co.sym} @ \$${co.todayPrice}');
      }
    });
    _qty.clear();
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(paperMarketProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(children: [
            ScreenHeader(title: 'Rayaan Stocks — The School', close: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                for (final (i, t) in [('Learn', 0), ('Floor', 1), ('Budget', 2), ('Savings', 3)].indexed)
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
            ),
            const SizedBox(height: 8),
            Expanded(child: market.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => Center(child: Text('Could not load the floor.', style: AppText.bodyMuted)),
              data: (mkt) {
                if (_tab == 0) {
                  return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
                    Padding(padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text('THE COURSE', style: AppText.eyebrow)),
                    GlassCard(
                      onTap: () => context.go('/finance/rayaan'),
                      child: Row(children: [
                        const Icon(Icons.school_outlined, color: AppColors.goldLight, size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('The 9-lesson course', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                          Text('What stocks are, the three screens, purification, crypto\'s line, the trader\'s craft',
                              style: AppText.bodyMuted.copyWith(fontSize: 11)),
                        ])),
                        const Icon(Icons.chevron_right, color: AppColors.gold),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(child: Text(
                        'On this floor you trade with \$100,000 of paper money — no real wealth moves. The companies are fictional; their fundamentals are real ratios from the real market\'s playbook. Twelve companies, eight pass the halal screens, four do not. Nobody tells you which. The screen is your homework — Lesson 3 is your tool.',
                        style: AppText.bodyMuted.copyWith(height: 1.6))),
                  ]);
                }
                if (_tab == 1) return _floor(mkt);
                if (_tab == 2) return _budget();
                return _savings();
              },
            )),
          ]),
        ),
      ),
    );
  }

  Widget _floor(List<PaperCo> mkt) {
    final holdingsValue = _portfolioValue(mkt);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
      GlassCard(strong: true, child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PAPER PORTFOLIO', style: AppText.eyebrow),
          Text('\$${(_cash + holdingsValue).toStringAsFixed(2)}',
              style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 28, color: AppColors.goldLight)),
          Text('cash \$${_cash.toStringAsFixed(0)} \u00b7 holdings \$${holdingsValue.toStringAsFixed(0)}',
              style: AppText.bodyMuted.copyWith(fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(holdingsValue + _cash >= 100000 ? '+' : '',
              style: TextStyle(color: holdingsValue + _cash >= 100000 ? AppColors.goldLight : Colors.orangeAccent, fontSize: 12)),
          Text('\$${(holdingsValue + _cash - 100000).toStringAsFixed(2)}',
              style: TextStyle(color: holdingsValue + _cash >= 100000 ? AppColors.goldLight : Colors.orangeAccent,
                  fontSize: 16, fontWeight: FontWeight.w700)),
          Text('vs \$100,000 start', style: AppText.bodyMuted.copyWith(fontSize: 9.5)),
        ]),
      ])),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(
          controller: _qty, keyboardType: TextInputType.number, style: AppText.body,
          decoration: const InputDecoration(hintText: 'Qty'),
        )),
      ]),
      const SizedBox(height: 8),
      Text('TODAY\'S MARKET — screen each one (Lesson 3) before you buy', style: AppText.eyebrow),
      const SizedBox(height: 6),
      for (final co in mkt)
        Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Text(co.sym, style: TextStyle(
                    color: AppColors.goldLight, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(co.name, style: AppText.body.copyWith(
                  fontWeight: FontWeight.w700, fontSize: 13))),
              Text('\$${co.todayPrice}', style: TextStyle(
                  color: AppColors.goldLight, fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text('${co.sector} \u00b7 rev \$${co.rev}M \u00b7 debt \$${co.debt}M \u00b7 mcap \$${co.mcap}M \u00b7 interest \$${co.interest}M',
                style: AppText.bodyMuted.copyWith(fontSize: 10.5)),
            Text(co.blurb, style: AppText.bodyMuted.copyWith(fontSize: 10.5)),
            Row(children: [
              TextButton(onPressed: () => _trade(co, true),
                  child: const Text('Buy', style: TextStyle(color: AppColors.goldLight, fontSize: 12))),
              TextButton(onPressed: () => _trade(co, false),
                  child: const Text('Sell', style: TextStyle(color: AppColors.sand, fontSize: 12))),
              if ((_holdings[co.sym] ?? 0) > 0)
                Text('holding: ${_holdings[co.sym]}', style: AppText.bodyMuted.copyWith(fontSize: 10.5)),
            ]),
          ]),
        )),
      if (_trades.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text('TRADE LOG', style: AppText.eyebrow),
        for (final t in _trades.take(8))
          Text(t, style: AppText.bodyMuted.copyWith(fontSize: 11)),
      ],
    ]);
  }

  Widget _budget() {
    final income = double.tryParse(_income.text.replaceAll(',', '')) ?? 0;
    final sadaqahPct = double.tryParse(_sadaqahPct.text) ?? 5;
    final sadaqah = income * sadaqahPct / 100;
    final rest = income - sadaqah;
    final needs = rest * 0.50, wants = rest * 0.30, savings = rest * 0.20;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
      Text('THE ISLAMIC BUDGET — sadaqah first, then 50 / 30 / 20', style: AppText.eyebrow),
      const SizedBox(height: 8),
      GlassCard(child: Column(children: [
        TextField(controller: _income, keyboardType: TextInputType.number,
            style: AppText.body, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Monthly household income (\$)')),
        const SizedBox(height: 8),
        TextField(controller: _sadaqahPct, keyboardType: TextInputType.number,
            style: AppText.body, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Sadaqah % (start at 2.5 — the zakat rate — and grow')),
      ])),
      const SizedBox(height: 10),
      if (income > 0) ...[
        _budgetRow('SADAQAH FIRST', sadaqah, 'given before anything else — it purifies what remains'),
        _budgetRow('NEEDS (50%)', needs, 'rent, food, transport, healthcare — halal sources only'),
        _budgetRow('WANTS (30%)', wants, 'ease and enjoyment — without israf, without waste'),
        _budgetRow('SAVINGS (20%)', savings, 'provision and protection — savings is not miserliness'),
        const SizedBox(height: 8),
        GlassCard(child: Text(
            '\u201cO you who believe, do not waste.\u201d (6:141, meaning) — the budget\'s fifth column is invisible: every dollar cut from waste returns to sadaqah or savings. Zakat is computed in the Tayyib engine when your savings pass the nisab for a lunar year.',
            style: AppText.bodyMuted.copyWith(height: 1.6, fontSize: 12))),
      ] else
        GlassCard(child: Text('Enter your monthly income to see the plan. The framework: sadaqah first — then needs 50%, wants 30%, savings 20% of the remainder. Earned from halal sources; no riba anywhere inside it.',
            style: AppText.bodyMuted.copyWith(height: 1.6))),
    ]);
  }

  Widget _budgetRow(String label, double amount, String note) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GlassCard(child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.eyebrow.copyWith(fontSize: 10)),
        Text('\$${amount.toStringAsFixed(0)} / month',
            style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
        Text(note, style: AppText.bodyMuted.copyWith(fontSize: 10.5)),
      ])),
    ])),
  );

  Widget _savings() {
    final target = double.tryParse(_goalTarget.text.replaceAll(',', '')) ?? 0;
    final saved = double.tryParse(_goalSaved.text.replaceAll(',', '')) ?? 0;
    final pct = target > 0 ? (saved / target * 100).clamp(0, 100) : 0;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
      Text('SAVINGS — provision with intention', style: AppText.eyebrow),
      const SizedBox(height: 8),
      GlassCard(child: Column(children: [
        TextField(controller: _goalName, style: AppText.body,
            decoration: const InputDecoration(hintText: 'Goal (Hajj fund is the classic)')),
        const SizedBox(height: 8),
        TextField(controller: _goalTarget, keyboardType: TextInputType.number,
            style: AppText.body, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Target (\$)')),
        const SizedBox(height: 8),
        TextField(controller: _goalSaved, keyboardType: TextInputType.number,
            style: AppText.body, onChanged: (_) { setState(() {}); _save(); },
            decoration: const InputDecoration(hintText: 'Saved so far (\$)')),
      ])),
      const SizedBox(height: 10),
      GlassCard(strong: true, child: Column(children: [
        Text('${_goalName.text.isEmpty ? 'Your goal' : _goalName.text} — ${pct.toStringAsFixed(0)}%',
            style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100, minHeight: 10,
            backgroundColor: AppColors.sand.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
          )),
        const SizedBox(height: 6),
        Text('\$${saved.toStringAsFixed(0)} of \$${target.toStringAsFixed(0)} \u00b7 \$${(target - saved).toStringAsFixed(0)} to go',
            style: AppText.bodyMuted.copyWith(fontSize: 11.5)),
      ])),
      const SizedBox(height: 8),
      GlassCard(child: Text(
          '\u201cSaving for a righteous intention is worship.\u201d The Prophet ﷺ guided a man who wanted to give everything away: keep some for your family\'s provision — that too is sadaqah (Bukhari 535). A Hajj fund saved over years, protected from waste, is a riyadah of the nafs — and when it finally carries you to Makkah, every dollar in it has a story.',
          style: AppText.bodyMuted.copyWith(height: 1.65, fontSize: 12.5))),
    ]);
  }
}
