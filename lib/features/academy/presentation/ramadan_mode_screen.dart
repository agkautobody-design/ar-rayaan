/// Ramadan Mode — the seasonal hub for the month of fasting: the
/// pillars in brief, the daily rhythm (suhoor to taraweeh), and the
/// doors back to the fasting guide and the duas of the day.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../huda/presentation/huda_screens.dart';

class _RamadanSection {
  const _RamadanSection({required this.title, required this.body});
  final String title;
  final String body;
}

const List<_RamadanSection> kRamadanPillars = <_RamadanSection>[
  _RamadanSection(
    title: 'The Obligation',
    body: 'O you who believe, fasting is prescribed for you as it was prescribed for those before you, that you may attain taqwa (2:183). The month of Ramadan in which the Quran was revealed (2:185). Two verses, one month, one purpose: a training in God-consciousness.',
  ),
  _RamadanSection(
    title: 'Who Fasts, Who Is Excused',
    body: 'The sick and the traveler may break the fast and make it up later (2:184) — and Allah intends for you ease and does not intend for you hardship (2:185). The exemption is the ruling itself showing mercy; using it is not a loophole.',
  ),
  _RamadanSection(
    title: 'The Fast of the Tongue',
    body: 'The Prophet ﭑ said: whoever does not give up false speech and acting upon it, Allah has no need of his leaving food and drink (Bukhari 1903). The stomach\u2019s fast is the easy part; the tongue\u2019s fast is where taqwa is built.',
  ),
];

const List<_RamadanSection> kRamadanRhythm = <_RamadanSection>[
  _RamadanSection(
    title: 'Suhoor — The Blessed Meal',
    body: 'The Prophet ﭑ said: take suhoor, for in suhoor there is blessing (Bukhari 1923). Eat before dawn; the angels seek forgiveness for the one who takes suhoor.',
  ),
  _RamadanSection(
    title: 'Iftar — The Breaking',
    body: 'The Prophet ﭑ broke his fast with dates and water, and said: the fasting person has a dua at the time of breaking that is not rejected (Ibn Majah 1753). Break it with dates if you can; make the dua with intention.',
  ),
  _RamadanSection(
    title: 'Taraweeh — The Night Prayer',
    body: 'The Prophet ﭑ prayed taraweeh in congregation, then prayed it alone for fear it would become obligatory. The standing of Ramadan is where the Quran is heard most — stand for a portion, even short, every night you can.',
  ),
];

class RamadanModeScreen extends ConsumerWidget {
  const RamadanModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guides = ref.watch(guidesProvider);
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Ramadan Mode', close: true),
              Text('رمضان',
                  style: AppText.arabic.copyWith(
                      fontSize: 32, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The month of taqwa — pillars, rhythm, and the doors of the day',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              Text('THE PILLARS', style: AppText.eyebrow),
              const SizedBox(height: 8),
              for (final _RamadanSection s in kRamadanPillars)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(s.title, style: AppText.titleMedium),
                        const SizedBox(height: 6),
                        Text(s.body,
                            style: AppText.body.copyWith(
                                height: 1.65, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Text('THE DAILY RHYTHM', style: AppText.eyebrow),
              const SizedBox(height: 8),
              for (final _RamadanSection s in kRamadanRhythm)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(s.title, style: AppText.titleMedium),
                        const SizedBox(height: 6),
                        Text(s.body,
                            style: AppText.body.copyWith(
                                height: 1.65, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Text('THE DOORS', style: AppText.eyebrow),
              const SizedBox(height: 8),
              guides.when(
                data: (all) {
                  final Guide? fasting = all
                      .where((Guide g) => g.id == 'huda-fasting')
                      .firstOrNull;
                  return Column(
                    children: <Widget>[
                      if (fasting != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.menu_book_outlined,
                                  color: AppColors.gold),
                              title: Text('The Fasting Guide',
                                  style: AppText.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5)),
                              subtitle: Text(
                                  'Who fasts, what breaks it, the exemptions',
                                  style: AppText.bodyMuted
                                      .copyWith(fontSize: 11.5)),
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppColors.gold),
                              onTap: () => context
                                  .push('/guides/read', extra: fasting),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.back_hand_outlined,
                                color: AppColors.gold),
                            title: Text('Duas of the Day',
                                style: AppText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5)),
                            subtitle: Text(
                                'Suhoor, iftar, and the dua of breaking',
                                style: AppText.bodyMuted
                                    .copyWith(fontSize: 11.5)),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.gold),
                            onTap: () => context.go('/academy/hisn'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.access_time,
                                color: AppColors.gold),
                            title: Text('Prayer Times & Iftar Countdown',
                                style: AppText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5)),
                            subtitle: Text('Fajr, Maghrib, and the moments between',
                                style: AppText.bodyMuted
                                    .copyWith(fontSize: 11.5)),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.gold),
                            onTap: () => context.go('/prayer'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
