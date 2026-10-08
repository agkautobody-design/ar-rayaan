import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/hijri_date.dart';
import '../domain/sunnah_fasting.dart';

/// Islamic Calendar — today's Hijri date hero, month grid, and the year's
/// upcoming observances. Tabular civil calculation, fully offline.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final HijriDate hijri = HijriDate.fromGregorian(today);
    final List<(Observance, HijriDate)> upcoming = Observances.upcoming(
      today,
    ).take(6).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Islamic Calendar'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _TodayCard(today: today, hijri: hijri),
                  const SizedBox(height: 16),
                  _MonthCard(hijri: hijri),
                  const SizedBox(height: 16),
                  _FastingMonthCard(hijri: hijri),
                  const SizedBox(height: 16),
                  _ObservancesCard(upcoming: upcoming),
                  const SizedBox(height: 16),
                  Text(
                    'DATES FOLLOW THE OFFICIAL UMM AL-QURA CALENDAR · CONFIRM BY LOCAL MOON SIGHTING',
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
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.today, required this.hijri});

  final DateTime today;
  final HijriDate hijri;

  static const List<String> _gregMonths = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            hijri.monthNameAr,
            style: AppText.arabicLarge.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 6),
          Text(
            '${hijri.day} ${hijri.monthNameEn} ${hijri.year}',
            style: AppText.displayMedium.copyWith(color: AppColors.sand),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${today.day} ${_gregMonths[today.month - 1]} ${today.year}',
            style: AppText.bodyMuted,
          ),
          const _TodayFastingBadge(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.hijri});

  final HijriDate hijri;

  static const List<String> _weekdays = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    final int days = hijri.daysInMonth;
    final int offset = hijri.firstWeekday; // 0 = Monday
    final int cells = offset + days;
    final int rows = (cells / 7).ceil();

    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            '${hijri.monthNameEn} ${hijri.year} · ${hijri.monthNameAr}',
            style: AppText.label.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final String w in _weekdays)
                SizedBox(
                  width: 32,
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(
                      color: AppColors.sand.withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (int row = 0; row < rows; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int col = 0; col < 7; col++)
                    _DayCell(
                      day: row * 7 + col - offset + 1,
                      valid:
                          row * 7 + col >= offset &&
                          row * 7 + col < offset + days,
                      isToday: row * 7 + col - offset + 1 == hijri.day,
                      markers:
                          row * 7 + col >= offset &&
                              row * 7 + col < offset + days
                          ? SunnahFasting.forDate(
                              HijriDate(
                                hijri.year,
                                hijri.month,
                                row * 7 + col - offset + 1,
                              ),
                            )
                          : const <FastingMarker>[],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.valid,
    required this.isToday,
    required this.markers,
  });

  final int day;
  final bool valid;
  final bool isToday;
  final List<FastingMarker> markers;

  @override
  Widget build(BuildContext context) {
    final bool recommended = markers.any(
      (FastingMarker m) => m.kind == FastingKind.recommended,
    );
    final bool forbidden = markers.any(
      (FastingMarker m) => m.kind == FastingKind.forbidden,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: valid && markers.isNotEmpty
          ? () => showFastingKnowledgeSheet(context, markers)
          : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: isToday
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.4),
                color: AppColors.gold.withValues(alpha: 0.12),
              )
            : null,
        child: valid
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: AppText.caption.copyWith(
                      color: isToday
                          ? AppColors.gold
                          : AppColors.sand.withValues(alpha: 0.8),
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 1),
                  if (forbidden)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.destructive,
                      ),
                    )
                  else if (recommended)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                    )
                  else
                    const SizedBox(height: 5),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// One-tap knowledge card for any fasting marker — the "why" with its
/// source on screen, per the app's authenticity constitution.
void showFastingKnowledgeSheet(
  BuildContext context,
  List<FastingMarker> markers,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.navy,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < markers.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: markers[i].kind == FastingKind.forbidden
                          ? AppColors.destructive
                          : AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      markers[i].titleEn,
                      style: AppText.label.copyWith(color: AppColors.sand),
                    ),
                  ),
                  Text(
                    markers[i].titleAr,
                    style: AppText.caption.copyWith(
                      fontFamily: AppFonts.arabic,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                markers[i].why,
                style: AppText.body.copyWith(
                  color: AppColors.sand.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                markers[i].source,
                style: AppText.eyebrow.copyWith(
                  color: AppColors.gold.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _TodayFastingBadge extends StatelessWidget {
  const _TodayFastingBadge();

  @override
  Widget build(BuildContext context) {
    final List<FastingMarker> markers = SunnahFasting.forDate(
      HijriDate.fromGregorian(DateTime.now()),
    );
    if (markers.isEmpty) return const SizedBox.shrink();
    final FastingMarker first = markers.first;
    final bool forbidden = first.kind == FastingKind.forbidden;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showFastingKnowledgeSheet(context, markers),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: forbidden
                  ? AppColors.destructive.withValues(alpha: 0.5)
                  : AppColors.gold.withValues(alpha: 0.5),
            ),
            color: forbidden
                ? AppColors.destructive.withValues(alpha: 0.08)
                : AppColors.gold.withValues(alpha: 0.08),
          ),
          child: Text(
            forbidden
                ? 'No fasting today — ${first.titleEn}'
                : 'Sunnah to fast today — tap to learn why',
            style: AppText.caption.copyWith(
              color: forbidden ? AppColors.destructive : AppColors.gold,
            ),
          ),
        ),
      ),
    );
  }
}

class _FastingMonthCard extends StatelessWidget {
  const _FastingMonthCard({required this.hijri});

  final HijriDate hijri;

  @override
  Widget build(BuildContext context) {
    final List<(HijriDate, List<FastingMarker>)> days =
        SunnahFasting.recommendedInMonth(hijri.year, hijri.month);
    if (days.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'SUNNAH FASTING · ${hijri.monthNameEn.toUpperCase()}',
            style: AppText.eyebrow.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap any day for its story and source.',
            style: AppText.caption,
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < days.length; i++) ...[
            if (i > 0)
              Divider(height: 14, color: AppColors.gold.withValues(alpha: 0.1)),
            InkWell(
              onTap: () =>
                  showFastingKnowledgeSheet(context, days[i].$2),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${days[i].$1.day}',
                        style: AppText.label.copyWith(color: AppColors.gold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        days[i].$2
                            .where(
                              (FastingMarker m) =>
                                  m.kind == FastingKind.recommended,
                            )
                            .map((FastingMarker m) => m.titleEn)
                            .join(' · '),
                        style: AppText.body.copyWith(
                          color: AppColors.sand.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ObservancesCard extends StatelessWidget {
  const _ObservancesCard({required this.upcoming});

  final List<(Observance, HijriDate)> upcoming;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int todayJd = HijriDate.gregorianToJd(now.year, now.month, now.day);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'UPCOMING OBSERVANCES',
            style: AppText.eyebrow.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < upcoming.length; i++) ...[
            if (i > 0)
              Divider(height: 16, color: AppColors.gold.withValues(alpha: 0.1)),
            _ObservanceRow(
              observance: upcoming[i].$1,
              date: upcoming[i].$2,
              daysAway:
                  HijriDate.hijriToJd(
                    upcoming[i].$2.year,
                    upcoming[i].$2.month,
                    upcoming[i].$2.day,
                  ) -
                  todayJd,
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ObservanceRow extends StatelessWidget {
  const _ObservanceRow({
    required this.observance,
    required this.date,
    required this.daysAway,
  });

  final Observance observance;
  final HijriDate date;
  final int daysAway;

  @override
  Widget build(BuildContext context) {
    final DateTime g = date.toGregorian();
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String when = daysAway == 0
        ? 'Today'
        : daysAway == 1
        ? 'Tomorrow'
        : 'in $daysAway days';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                observance.nameEn,
                style: AppText.body.copyWith(
                  color: AppColors.sand.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${date.format()} · ${g.day} ${months[g.month - 1]} ${g.year} · $when',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            observance.nameAr,
            style: AppText.caption.copyWith(
              fontFamily: AppFonts.arabic,
              color: AppColors.gold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
