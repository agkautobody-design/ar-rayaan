import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../domain/zakat_calculation.dart';
import '../domain/zakat_engine.dart';

/// Guided Zakat Calculator — enter everything (cash, gold by karat, jewelry,
/// stocks, retirement, crypto, business, mortgage) and Ar-Rayaan computes
/// the obligation live. Madhab-aware; scholarly positions labeled, never
/// ruled on. Live metal prices are a convenience — manual entry always works.
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final Map<String, TextEditingController> _c = {
    for (final k in [
      'cash', 'savings', 'owed', 'receivables',
      'goldValue', 'silverValue', 'goldGrams', 'silverGrams',
      'jewelryGrams',
      'stocksTrader', 'stocksLong', 'customRatio', 'crypto',
      'retirement', 'penalty',
      'bizCash', 'bizInventory', 'bizReceivables', 'rental', 'resale',
      'debts', 'mortgage', 'bills',
      'goldPrice', 'silverPrice',
    ])
      k: TextEditingController(),
  };

  Madhab _madhab = Madhab.hanafi;
  bool _silverNisab = true;
  int _goldKarat = 24;
  int _jewelryKarat = 22;
  StockIntent _stockIntent = StockIntent.longTerm;
  LongTermMethod _ltMethod = LongTermMethod.nzf30;
  RetirementPosition _retPos = RetirementPosition.annualNetAccessible;
  bool _fetchingPrices = false;
  String? _priceNote;

  double _v(String key) => ZakatCalculation.parseAmount(_c[key]!.text);

  @override
  void initState() {
    super.initState();
    _c['penalty']!.text = '30';
    for (final c in _c.values) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  GuidedZakatInput get _input => GuidedZakatInput(
        madhab: _madhab,
        cashAndBank: _v('cash'),
        savings: _v('savings'),
        moneyOwedToYou: _v('owed'),
        expectedReceivables: _v('receivables'),
        goldValue: _v('goldValue'),
        silverValue: _v('silverValue'),
        goldGrams: _v('goldGrams'),
        goldKarat: _goldKarat,
        silverGrams: _v('silverGrams'),
        wornJewelryGoldGrams: _v('jewelryGrams'),
        wornJewelryKarat: _jewelryKarat,
        stockIntent: _stockIntent,
        stockTraderValue: _v('stocksTrader'),
        stockLongTermValue: _v('stocksLong'),
        longTermMethod: _ltMethod,
        customRatio: _v('customRatio') > 0 ? _v('customRatio') / 100 : 0.25,
        cryptoValue: _v('crypto'),
        retirementBalance: _v('retirement'),
        retirementPenaltyPct: (_v('penalty') / 100).clamp(0.0, 1.0),
        retirementPosition: _retPos,
        businessCash: _v('bizCash'),
        businessInventory: _v('bizInventory'),
        businessReceivables: _v('bizReceivables'),
        rentalIncomeSaved: _v('rental'),
        propertyForResaleValue: _v('resale'),
        debtsDueThisYear: _v('debts'),
        mortgageYearInstallments: _v('mortgage'),
        billsDue: _v('bills'),
        useSilverNisab: _silverNisab,
        goldPricePerGram: _v('goldPrice'),
        silverPricePerGram: _v('silverPrice'),
      );

  Future<void> _fetchLivePrices() async {
    setState(() {
      _fetchingPrices = true;
      _priceNote = null;
    });
    try {
      const double ozToGram = 31.1035;
      final results = await Future.wait([
        http
            .get(Uri.parse('https://api.gold-api.com/price/XAU'))
            .timeout(const Duration(seconds: 8)),
        http
            .get(Uri.parse('https://api.gold-api.com/price/XAG'))
            .timeout(const Duration(seconds: 8)),
      ]);
      final double goldOz =
          (jsonDecode(results[0].body)['price'] as num).toDouble();
      final double silverOz =
          (jsonDecode(results[1].body)['price'] as num).toDouble();
      setState(() {
        _c['goldPrice']!.text = (goldOz / ozToGram).toStringAsFixed(2);
        _c['silverPrice']!.text = (silverOz / ozToGram).toStringAsFixed(2);
        _priceNote = 'Live prices (USD per gram) — gold-api.com';
      });
    } catch (_) {
      setState(() {
        _priceNote = 'Could not reach live prices — enter them manually.';
      });
    } finally {
      if (mounted) setState(() => _fetchingPrices = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final GuidedZakatResult r = ZakatEngine.compute(_input);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Zakat Calculator'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _HeroCard(result: r),
                  const SizedBox(height: 16),
                  _buildNisabCard(),
                  const SizedBox(height: 16),
                  _buildMadhabCard(),
                  const SizedBox(height: 16),
                  _section('CASH & BANK', Icons.account_balance_outlined, [
                    _field('cash', 'Cash & bank balances',
                        Icons.account_balance_wallet_outlined),
                    _field('savings', 'Savings & deposits', Icons.savings_outlined),
                    _field('owed', 'Money owed to you (repayment expected)',
                        Icons.handshake_outlined),
                    _field('receivables', 'Expected receivables (refunds, salary due)',
                        Icons.schedule_outlined),
                  ]),
                  _section('GOLD & SILVER', Icons.diamond_outlined, [
                    _field('goldValue', 'Gold — value (if known)', Icons.circle_outlined),
                    _field('goldGrams', 'Gold — grams', Icons.scale_outlined),
                    _karatRow('Gold karat', _goldKarat,
                        (k) => setState(() => _goldKarat = k)),
                    _field('silverValue', 'Silver — value (if known)', Icons.circle_outlined),
                    _field('silverGrams', 'Silver — grams', Icons.scale_outlined),
                    _note('Bullion, coins and stored jewelry are zakatable in '
                        'every school, at current market value.'),
                  ]),
                  _section('JEWELRY YOU WEAR', Icons.watch_outlined, [
                    _field('jewelryGrams', 'Worn gold jewelry — grams',
                        Icons.diamond_outlined),
                    _karatRow('Jewelry karat', _jewelryKarat,
                        (k) => setState(() => _jewelryKarat = k)),
                    _note(_madhab == Madhab.hanafi
                        ? 'Hanafi: worn gold jewelry is zakatable (Abu Dawud 1563).'
                        : 'Maliki / Shafi\'i / Hanbali: genuinely worn jewelry is '
                            'exempt. Stored jewelry is zakatable in all schools — '
                            'enter it under Gold above.'),
                  ]),
                  _section('INVESTMENTS', Icons.trending_up, [
                    _intentRow(),
                    if (_stockIntent == StockIntent.trader)
                      _field('stocksTrader', 'Trading portfolio — market value',
                          Icons.show_chart)
                    else ...[
                      _field('stocksLong', 'Long-term holdings — market value',
                          Icons.pie_chart_outline),
                      _methodRow(),
                      if (_ltMethod == LongTermMethod.custom)
                        _field('customRatio', 'Zakatable ratio % (from fund report)',
                            Icons.percent),
                    ],
                    _field('crypto', 'Crypto — market value', Icons.currency_bitcoin),
                  ]),
                  _section('RETIREMENT · 401K / RRSP / PENSION',
                      Icons.elderly_outlined, [
                    _field('retirement', 'Vested balance', Icons.account_balance_outlined),
                    _retPosRow(),
                    if (_retPos == RetirementPosition.annualNetAccessible)
                      _field('penalty', 'Taxes + early-withdrawal penalty %',
                          Icons.percent),
                    _note(_retPos == RetirementPosition.annualNetAccessible
                        ? 'FCNA position: zakat yearly on the net accessible '
                            'value (balance − taxes − penalties).'
                        : 'Second position: locked funds are zakatable when you '
                            'gain penalty-free access. Both are respectable — '
                            'pick one and stay consistent.'),
                  ]),
                  _section('BUSINESS & PROPERTY', Icons.storefront_outlined, [
                    _field('bizCash', 'Business cash', Icons.payments_outlined),
                    _field('bizInventory', 'Inventory (goods for sale)',
                        Icons.inventory_2_outlined),
                    _field('bizReceivables', 'Business receivables',
                        Icons.receipt_long_outlined),
                    _field('rental', 'Saved rental income', Icons.home_work_outlined),
                    _field('resale', 'Property held for resale — market value',
                        Icons.real_estate_agent_outlined),
                    _note('Your home, car and tools of trade are never zakatable. '
                        'Rental property itself is exempt — only its saved income.'),
                  ]),
                  _section('DEBTS & MORTGAGE (DEDUCTED)',
                      Icons.remove_circle_outline, [
                    _field('debts', 'Debts due within this year',
                        Icons.money_off_outlined),
                    _field('mortgage', 'Mortgage — this year\'s installments only',
                        Icons.house_outlined),
                    _field('bills', 'Bills due now', Icons.receipt_outlined),
                    _note('Only what falls due within this lunar year is '
                        'deducted — not the full remaining mortgage principal.'),
                  ]),
                  const SizedBox(height: 8),
                  if (r.notes.isNotEmpty) _buildNotesCard(r.notes),
                  const SizedBox(height: 16),
                  Text(
                    'YOUR NUMBERS NEVER LEAVE THIS DEVICE · POSITIONS LABELED, '
                    'NEVER RULED ON — CONSULT YOUR SCHOLAR ON CONTESTED MATTERS',
                    style: AppText.eyebrow.copyWith(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNisabCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NISAB THRESHOLD',
              style: AppText.eyebrow.copyWith(color: AppColors.gold)),
          const SizedBox(height: 10),
          Row(children: [
            _chip('Silver · 612 g (recommended)', _silverNisab,
                () => setState(() => _silverNisab = true)),
            const SizedBox(width: 8),
            _chip('Gold · 87.5 g', !_silverNisab,
                () => setState(() => _silverNisab = false)),
          ]),
          const SizedBox(height: 8),
          _note('Most scholars recommend the silver standard today — the lower '
              'threshold means more of your obligation reaches the poor.'),
          const SizedBox(height: 10),
          _field('goldPrice', 'Gold price per gram', Icons.scale_outlined),
          _field('silverPrice', 'Silver price per gram', Icons.scale_outlined),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _fetchingPrices ? null : _fetchLivePrices,
              icon: _fetchingPrices
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_download_outlined,
                      size: 16, color: AppColors.gold),
              label: Text(
                _fetchingPrices ? 'Fetching…' : 'Use live prices (USD)',
                style: AppText.label.copyWith(color: AppColors.gold),
              ),
            ),
          ),
          if (_priceNote != null)
            Text(_priceNote!,
                style: AppText.bodyMuted.copyWith(fontSize: 11)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMadhabCard() {
    const names = {
      Madhab.hanafi: 'Hanafi',
      Madhab.maliki: 'Maliki',
      Madhab.shafii: 'Shafi\'i',
      Madhab.hanbali: 'Hanbali',
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR SCHOOL (MADHHAB)',
              style: AppText.eyebrow.copyWith(color: AppColors.gold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in Madhab.values)
                _chip(names[m]!, _madhab == m,
                    () => setState(() => _madhab = m), expand: false),
            ],
          ),
          const SizedBox(height: 8),
          _note('This changes how worn jewelry and debts are treated. '
              'Every difference is labeled on screen — nothing is hidden.'),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildNotesCard(List<String> notes) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SCHOLARLY POSITIONS IN PLAY',
              style: AppText.eyebrow.copyWith(color: AppColors.gold)),
          const SizedBox(height: 8),
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('· $n', style: AppText.bodyMuted),
            ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Material(
            type: MaterialType.transparency,
            child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            iconColor: AppColors.gold,
            collapsedIconColor: AppColors.gold.withValues(alpha: 0.6),
            leading: Icon(icon, color: AppColors.gold, size: 20),
            title: Text(title,
                style: AppText.eyebrow.copyWith(color: AppColors.gold)),
            children: [
              const SizedBox(height: 6),
              ...children,
              const SizedBox(height: 4),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _field(String key, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AuthTextField(
        controller: _c[key]!,
        label: label,
        icon: icon,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppText.bodyMuted.copyWith(fontSize: 11)),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {bool expand = true}) {
    final Widget chip = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? AppColors.gold.withValues(alpha: 0.15)
                : AppColors.glassFill,
            border: Border.all(
              color: selected
                  ? AppColors.gold
                  : AppColors.gold.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(
              fontSize: 12,
              color: selected
                  ? AppColors.gold
                  : AppColors.sand.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
    return expand ? Expanded(child: chip) : chip;
  }

  Widget _karatRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: AppText.label.copyWith(color: AppColors.sand)),
          const Spacer(),
          DropdownButton<int>(
            value: value,
            dropdownColor: AppColors.navy,
            underline: const SizedBox.shrink(),
            style: AppText.label.copyWith(color: AppColors.gold),
            items: const [24, 22, 21, 18, 14, 10, 9]
                .map((k) => DropdownMenuItem(value: k, child: Text('${k}k')))
                .toList(),
            onChanged: (k) => k != null ? onChanged(k) : null,
          ),
        ],
      ),
    );
  }

  Widget _intentRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        _chip('I trade actively', _stockIntent == StockIntent.trader,
            () => setState(() => _stockIntent = StockIntent.trader)),
        const SizedBox(width: 8),
        _chip('I hold long-term', _stockIntent == StockIntent.longTerm,
            () => setState(() => _stockIntent = StockIntent.longTerm)),
      ]),
    );
  }

  Widget _methodRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        _chip('NZF 30%', _ltMethod == LongTermMethod.nzf30,
            () => setState(() => _ltMethod = LongTermMethod.nzf30)),
        const SizedBox(width: 8),
        _chip('IFG 25%', _ltMethod == LongTermMethod.ifg25,
            () => setState(() => _ltMethod = LongTermMethod.ifg25)),
        const SizedBox(width: 8),
        _chip('Custom', _ltMethod == LongTermMethod.custom,
            () => setState(() => _ltMethod = LongTermMethod.custom)),
      ]),
    );
  }

  Widget _retPosRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        _chip('Yearly (FCNA)', _retPos == RetirementPosition.annualNetAccessible,
            () => setState(
                () => _retPos = RetirementPosition.annualNetAccessible)),
        const SizedBox(width: 8),
        _chip('When I can access it', _retPos == RetirementPosition.onAccess,
            () => setState(() => _retPos = RetirementPosition.onAccess)),
      ]),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.result});

  final GuidedZakatResult result;

  @override
  Widget build(BuildContext context) {
    final String due = ZakatCalculation.formatAmount(result.zakatDue);
    final String status = !result.nisabKnown
        ? 'Enter metal prices to set your nisab'
        : result.isEligible
            ? 'Your wealth is above nisab — may Allah accept it'
            : 'Below nisab — no zakat due, and your sadaqah is still loved';

    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text('الزَّكَاة',
              style: AppText.arabicLarge.copyWith(color: AppColors.gold)),
          const SizedBox(height: 4),
          Text('PURIFY YOUR WEALTH · 2.5% ABOVE NISAB',
              style: AppText.eyebrow
                  .copyWith(color: AppColors.sand.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          Text(due,
              style: AppText.displayLarge.copyWith(
                color: result.isEligible ? AppColors.gold : AppColors.sand,
              )),
          const SizedBox(height: 4),
          Text('ZAKAT DUE', style: AppText.eyebrow),
          const SizedBox(height: 10),
          Text(status, style: AppText.bodyMuted, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('NET WEALTH',
                  ZakatCalculation.formatAmount(result.netZakatable)),
              _stat('NISAB', ZakatCalculation.formatAmount(result.nisabValue)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(value, style: AppText.label.copyWith(color: AppColors.sand)),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.eyebrow.copyWith(
                  fontSize: 9, color: AppColors.sand.withValues(alpha: 0.45))),
        ],
      );
}
