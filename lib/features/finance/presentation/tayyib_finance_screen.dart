import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';

/// TAYYIB FINANCE - the wealth wing. Purification, giving, and earning.
/// Zakat links to the live engine; the stock screener teaches the AAOIFI
/// screens with worked math (live market data arrives with a free API key).
class TayyibFinanceScreen extends StatefulWidget {
  const TayyibFinanceScreen({super.key});

  @override
  State<TayyibFinanceScreen> createState() => _TayyibState();
}

class _TayyibState extends State<TayyibFinanceScreen> {
  final _haram = TextEditingController();
  final _debt = TextEditingController();
  final _mcap = TextEditingController();
  final _interest = TextEditingController();
  final _revenue = TextEditingController();
  List<String>? _verdict;

  void _screen() {
    double p(String s) => double.tryParse(s.replaceAll(',', '').trim()) ?? 0;
    final haram = p(_haram.text), debt = p(_debt.text), mcap = p(_mcap.text),
        interest = p(_interest.text), revenue = p(_revenue.text);
    final out = <String>[];
    if (revenue > 0 && haram / revenue > 0.05) {
      out.add('Business activity: haram revenue ${(haram / revenue * 100).round()}% exceeds the 5% ceiling');
    } else if (revenue > 0) {
      out.add('Business activity: within the 5% tolerance (${(haram / revenue * 100).round()}%) - purify that portion by giving it away');
    }
    if (mcap > 0 && debt / mcap > 0.30) {
      out.add('Leverage: debt is ${(debt / mcap * 100).round()}% of market cap - above the ~30% screen');
    } else if (mcap > 0) {
      out.add('Leverage: ${(debt / mcap * 100).round()}% of market cap - passes the screen');
    }
    if (revenue > 0 && interest / revenue > 0.05) {
      out.add('Interest income: ${(interest / revenue * 100).round()}% of revenue - above the 5% screen');
    } else if (revenue > 0) {
      out.add('Interest income: ${(interest / revenue * 100).round()}% - within tolerance, purify it');
    }
    if (out.isEmpty) out.add('Enter the company\u2019s figures to run the three screens.');
    setState(() => _verdict = out);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Tayyib Finance', close: true),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text('WEALTH THAT STANDS CLEAN', style: AppText.eyebrow),
              ),
              GlassCard(
                onTap: () => context.go(AppRoutes.zakat),
                child: Row(children: [
                  const Icon(Icons.calculate_outlined, color: AppColors.goldLight, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Zakat Calculator', style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('Live gold nisab \u00b7 hawl tracking \u00b7 all four schools', style: AppText.bodyMuted.copyWith(fontSize: 11.5)),
                  ])),
                  const Icon(Icons.chevron_right, color: AppColors.gold),
                ]),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SADAQAH \u2014 THE UNSEEN INVESTMENT', style: AppText.eyebrow),
                  const SizedBox(height: 8),
                  Text(
                    'Zakat is the obligatory 2.5% of stored wealth; sadaqah is the voluntary river that never stops giving. '
                    'The Prophet \ufdfa said: \u201cCharity does not decrease wealth\u201d (Muslim 2588). '
                    'The best sadaqah is the ongoing kind \u2014 a well, a tree, knowledge that keeps teaching \u2014 '
                    'for it outlives the hand that gave it.',
                    style: AppText.bodyMuted.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Text('Sadaqah jariyah: water \u00b7 trees \u00b7 teaching \u00b7 a copy of the Qur\u2019an \u00b7 easing a hardship',
                      style: AppText.body.copyWith(fontSize: 12.5, color: AppColors.goldLight)),
                ]),
              ),
              const SizedBox(height: 12),
              GlassCard(
                strong: true,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('HALAL STOCK SCREENER', style: AppText.eyebrow),
                  const SizedBox(height: 4),
                  Text('The three screens widely used (AAOIFI-style): business activity under 5% haram revenue; debt under ~30% of market cap; interest income under 5% of revenue. Anything in the tolerated margin is purified \u2014 given away.',
                      style: AppText.bodyMuted.copyWith(height: 1.55, fontSize: 12)),
                  const SizedBox(height: 10),
                  for (final f in [
                    ('Haram revenue (annual, \$)', _haram),
                    ('Total revenue (annual, \$)', _revenue),
                    ('Total debt (\$)', _debt),
                    ('Market cap (\$)', _mcap),
                    ('Interest income (\$)', _interest),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: f.$2,
                        keyboardType: TextInputType.number,
                        style: AppText.body,
                        decoration: InputDecoration(
                          hintText: f.$1,
                          hintStyle: AppText.bodyMuted.copyWith(fontSize: 12),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _screen,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: const Color(0xFF0A0F18)),
                      child: const Text('Run the screens'),
                    ),
                  ),
                  if (_verdict != null) ...[
                    const SizedBox(height: 10),
                    for (final v in _verdict!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('\u2022 $v', style: AppText.bodyMuted.copyWith(height: 1.5, fontSize: 12)),
                      ),
                  ],
                  const SizedBox(height: 6),
                  Text('Educational tool \u2014 for real portfolios, consult a qualified Sharia advisor. Live market screening arrives with a free data key.',
                      style: AppText.bodyMuted.copyWith(fontSize: 10)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
