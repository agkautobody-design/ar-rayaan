import 'package:flutter/material.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/gold_text.dart';
import '../../../app/theme/widgets/icon_tile.dart';

/// WP0 gate — design-system verification page.
///
/// Dev-tool only: proves the locked tokens (colors, typography, glass,
/// gold CTA, icon chips) render correctly before any real screen is built.
/// `/` is handed to Splash in WP1; this page stays at /dev/theme.
class ThemeDemoScreen extends StatelessWidget {
  const ThemeDemoScreen({super.key});

  static const List<(String, Color)> _palette = [
    ('Gold', AppColors.gold),
    ('Gold Light', AppColors.goldLight),
    ('Gold Dark', AppColors.goldDark),
    ('Sand', AppColors.sand),
    ('Deep Blue', AppColors.deepBlue),
    ('Navy', AppColors.navy),
    ('Night', AppColors.night),
    ('Glass', AppColors.glassFill),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.4,
            colors: [Color(0x14D4AF37), AppColors.night],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  Text(
                    'AR-RAYAAN',
                    style: AppText.eyebrow,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  GoldText(
                    l10n.appTitle,
                    style: AppText.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    l10n.journeyToParadise.toUpperCase(),
                    style: AppText.eyebrow.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  const _SectionLabel('Color Palette'),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final (name, color) in _palette)
                          _Swatch(name: name, color: color),
                      ],
                    ),
                  ),

                  const _SectionLabel('Typography'),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Playfair Display', style: AppText.displayMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Where hearts find home — Inter body renders calm and legible at small sizes.',
                          style: AppText.bodyMuted,
                        ),
                        const Divider(height: 28),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            style: AppText.arabicLarge,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Amiri — Arabic · RTL', style: AppText.eyebrow),
                      ],
                    ),
                  ),

                  const _SectionLabel('Glass Cards'),
                  const GlassCard(
                    padding: EdgeInsets.all(16),
                    child: _CardDemo(
                      title: 'Standard glass',
                      subtitle: 'Blur 24 · 1px gold · radius 20 · soft shadow',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const GlassCard(
                    strong: true,
                    padding: EdgeInsets.all(16),
                    child: _CardDemo(
                      title: 'Strong glass',
                      subtitle: 'Navy fill · wider gold glow',
                    ),
                  ),

                  const _SectionLabel('Icon Tiles'),
                  const GlassCard(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconTile(icon: Icons.nights_stay_outlined),
                        IconTile(icon: Icons.menu_book_outlined),
                        IconTile(icon: Icons.wb_sunny_outlined),
                        IconTile(icon: Icons.auto_awesome_outlined),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  GoldButton(
                    label: l10n.continueLabel,
                    trailing: const Icon(Icons.chevron_right),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'WP0 · FOUNDATION GATE — design system verification',
                    style: AppText.eyebrow.copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 24, bottom: 8),
      child: Text(text.toUpperCase(), style: AppText.eyebrow),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CardDemo extends StatelessWidget {
  const _CardDemo({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const IconTile(icon: Icons.auto_awesome),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.titleMedium),
              Text(subtitle, style: AppText.bodyMuted),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.gold),
      ],
    );
  }
}
