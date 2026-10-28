import '../../../app/core/scholar_review.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../share/application/share_service.dart';
import '../../share/presentation/share_actions.dart';
import '../application/hijri_settings.dart';
import '../domain/hijri_date.dart';
import '../domain/sunnah_fasting.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../../app/theme/widgets/named_sheet.dart';

/// Islamic Calendar: today's Hijri date, a month grid you can page through,
/// a date converter and the year's upcoming observances. Fully offline.
///
/// The calendar basis (Umm al-Qura or tabular) and a whole-day shift are the
/// user's choice (see `hijriSettingsProvider`); the page rebuilds when they
/// change, and every other screen reads the same setting.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  /// Months away from the current Hijri month being shown.
  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final HijriConfig config = ref.watch(hijriSettingsProvider);
    final DateTime today = DateTime.now();
    final HijriDate hijri = HijriDate.fromGregorian(today);
    final int index = hijri.year * 12 + (hijri.month - 1) + _monthOffset;
    final HijriDate shown = HijriDate(index ~/ 12, index % 12 + 1, 1);
    final List<(Observance, HijriDate)> upcoming = Observances.upcoming(today);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Islamic Calendar'),
            const ScholarReviewNote(
              reviewKey: 'calendar',
              padding: const EdgeInsets.only(bottom: 8),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _TodayCard(today: today, hijri: hijri),
                  const SizedBox(height: 8),
                  if (upcoming.isNotEmpty)
                    _NextEventBanner(upcoming: upcoming, today: today),
                  Align(
                    child: TextButton.icon(
                      onPressed: () => _showBasisSheet(context),
                      icon: const Icon(Icons.tune, size: 16),
                      label: Text(
                        'Calculation method: '
                        '${config.basis == HijriBasis.ummAlQura ? 'Umm al-Qura' : 'Tabular'}'
                        '${config.adjustDays == 0 ? '' : ' · ${config.adjustDays > 0 ? '+' : ''}${config.adjustDays} d'}'
                        ' · change',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _ConverterCard(),
                  const SizedBox(height: 16),
                  _MonthCard(
                    shown: shown,
                    today: hijri,
                    onPrev: () => setState(() => _monthOffset--),
                    onNext: () => setState(() => _monthOffset++),
                    onToday: _monthOffset == 0
                        ? null
                        : () => setState(() => _monthOffset = 0),
                  ),
                  const SizedBox(height: 16),
                  _FastingMonthCard(hijri: shown),
                  const SizedBox(height: 16),
                  _ObservancesCard(upcoming: upcoming),
                  const SizedBox(height: 16),
                  Text(
                    config.basis == HijriBasis.ummAlQura
                        ? 'UMM AL-QURA TABLE (HIJRI PACKAGE, 1356-1500 AH) · CONFIRM BY LOCAL MOON SIGHTING'
                        : 'TABULAR (ARITHMETIC) CALENDAR · NOT MOON-SIGHTED · CONFIRM BY LOCAL MOON SIGHTING',
                    style: AppText.eyebrow.copyWith(
                      color: AppColors.gold.withValues(alpha: 0.9),
                      fontSize: 12,
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

  void _showBasisSheet(BuildContext context) {
    showNamedSheet<void>(
      label: 'Hijri date basis',
      context: context,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) => Consumer(
        builder: (BuildContext c, WidgetRef ref, Widget? _) {
          final HijriConfig cfg = ref.watch(hijriSettingsProvider);
          final HijriSettingsController ctl = ref.read(
            hijriSettingsProvider.notifier,
          );
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  'CALENDAR BASIS',
                  style: AppText.eyebrow.copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: 8),
                RadioGroup<HijriBasis>(
                  groupValue: cfg.basis,
                  onChanged: (HijriBasis? v) {
                    if (v != null) ctl.setBasis(v);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<HijriBasis>(
                        value: HijriBasis.ummAlQura,
                        title: Text('Umm al-Qura'),
                        subtitle: Text(
                          'The official calendar of Saudi Arabia, from the '
                          'published table in the hijri package (1356-1500 AH).',
                        ),
                      ),
                      RadioListTile<HijriBasis>(
                        value: HijriBasis.tabular,
                        title: Text('Tabular (arithmetic)'),
                        subtitle: Text(
                          'A fixed 30-year rule that does not observe the '
                          'moon. It can differ from sighting by a day or two.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SHIFT ALL DATES',
                  style: AppText.eyebrow.copyWith(color: AppColors.gold),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'One day earlier',
                      onPressed: cfg.adjustDays > -HijriConfig.maxAdjust
                          ? () => ctl.setAdjustDays(cfg.adjustDays - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${cfg.adjustDays > 0 ? '+' : ''}${cfg.adjustDays} days',
                      style: AppText.label.copyWith(color: AppColors.sand),
                    ),
                    IconButton(
                      tooltip: 'One day later',
                      onPressed: cfg.adjustDays < HijriConfig.maxAdjust
                          ? () => ctl.setAdjustDays(cfg.adjustDays + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                Text(
                  'Use this if your country or community announced a month '
                  'start a day away from the calculated one. A single shift '
                  'is an approximation; it applies to the calendar, Ramadan, '
                  'fasting days and Zakat reminders alike. For the start of '
                  'Ramadan and the two Eids, follow your local announcement '
                  'or ask a scholar.',
                  style: AppText.caption,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _ConvertDirection { toHijri, toGregorian }

/// Gregorian to Hijri and Hijri to Gregorian, using the calendar chosen
/// above (the same [HijriDate.config] every other screen reads).
class _ConverterCard extends StatefulWidget {
  const _ConverterCard();

  @override
  State<_ConverterCard> createState() => _ConverterCardState();
}

class _ConverterCardState extends State<_ConverterCard> {
  _ConvertDirection _dir = _ConvertDirection.toHijri;
  DateTime _picked = DateTime.now();
  late int _hYear;
  late int _hMonth;
  late int _hDay;

  @override
  void initState() {
    super.initState();
    final HijriDate t = HijriDate.fromGregorian(DateTime.now());
    _hYear = t.year
        .clamp(HijriDate.converterMinYear, HijriDate.converterMaxYear)
        .toInt();
    _hMonth = t.month;
    _hDay = t.day;
    _clampDay();
  }

  void _clampDay() {
    final int max = HijriDate.monthLength(_hYear, _hMonth);
    if (_hDay > max) _hDay = max;
  }

  Widget _gregorianToHijri(BuildContext context) {
    final HijriDate h = HijriDate.fromGregorian(_picked);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_picked.day} ${_gregShort(_picked)} ${_picked.year}  =  '
          '${h.day} ${h.monthNameEn} ${h.year} AH',
          style: AppText.body.copyWith(color: AppColors.sand),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () async {
            final DateTime? d = await showDatePicker(
              context: context,
              initialDate: _picked,
              firstDate: DateTime(1937),
              lastDate: DateTime(2076),
            );
            if (d != null) setState(() => _picked = d);
          },
          child: const Text('Pick a Gregorian date'),
        ),
      ],
    );
  }

  Widget _hijriToGregorian() {
    final DateTime? g = HijriDate.gregorianFromHijri(_hYear, _hMonth, _hDay);
    final int days = HijriDate.monthLength(_hYear, _hMonth);
    final TextStyle dropdownStyle = AppText.body.copyWith(
      color: AppColors.sand,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<int>(
              key: const Key('hijri-day'),
              value: _hDay.clamp(1, days).toInt(),
              dropdownColor: AppColors.navy,
              style: dropdownStyle,
              items: [
                for (int d = 1; d <= days; d++)
                  DropdownMenuItem<int>(value: d, child: Text('$d')),
              ],
              onChanged: (int? v) {
                if (v != null) setState(() => _hDay = v);
              },
            ),
            DropdownButton<int>(
              key: const Key('hijri-month'),
              value: _hMonth,
              dropdownColor: AppColors.navy,
              style: dropdownStyle,
              items: [
                for (int m = 1; m <= 12; m++)
                  DropdownMenuItem<int>(
                    value: m,
                    child: Text(HijriDate.monthNamesEn[m - 1]),
                  ),
              ],
              onChanged: (int? v) {
                if (v == null) return;
                setState(() {
                  _hMonth = v;
                  _clampDay();
                });
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Previous Hijri year',
                  onPressed: _hYear > HijriDate.converterMinYear
                      ? () => setState(() {
                          _hYear--;
                          _clampDay();
                        })
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  color: AppColors.gold,
                ),
                Text('$_hYear AH', style: dropdownStyle),
                IconButton(
                  tooltip: 'Next Hijri year',
                  onPressed: _hYear < HijriDate.converterMaxYear
                      ? () => setState(() {
                          _hYear++;
                          _clampDay();
                        })
                      : null,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: AppColors.gold,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          g == null
              ? 'That date does not exist in this calendar.'
              : '$_hDay ${HijriDate.monthNamesEn[_hMonth - 1]} $_hYear AH  =  '
                    '${g.day} ${_gregShort(g)} ${g.year}',
          key: const Key('hijri-result'),
          style: AppText.body.copyWith(color: AppColors.sand),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'DATE CONVERTER',
            style: AppText.eyebrow.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                key: const Key('convert-to-hijri'),
                label: const Text('Gregorian to Hijri'),
                selected: _dir == _ConvertDirection.toHijri,
                onSelected: (_) =>
                    setState(() => _dir = _ConvertDirection.toHijri),
              ),
              ChoiceChip(
                key: const Key('convert-to-gregorian'),
                label: const Text('Hijri to Gregorian'),
                selected: _dir == _ConvertDirection.toGregorian,
                onSelected: (_) =>
                    setState(() => _dir = _ConvertDirection.toGregorian),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_dir == _ConvertDirection.toHijri)
            _gregorianToHijri(context)
          else
            _hijriToGregorian(),
        ],
      ),
    );
  }
}

/// '10 Muharram 1448 AH · 26 Jun 2026' for the day popups.
String _hijriWithGregorian(HijriDate date) {
  final DateTime g = date.toGregorian();
  return '${date.format()} AH \u00b7 ${g.day} ${_gregShort(g)} ${g.year}';
}

/// Short English month name of a Gregorian date ('Oct').
String _gregShort(DateTime g) => _kShortMonths[g.month - 1];

const List<String> _kShortMonths = <String>[
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
  const _MonthCard({
    required this.shown,
    required this.today,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  /// First day of the month being shown.
  final HijriDate shown;

  /// Today's Hijri date, for the highlight.
  final HijriDate today;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  HijriDate get hijri => shown;

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
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${hijri.monthNameEn} ${hijri.year} · ${hijri.monthNameAr}',
                  textAlign: TextAlign.center,
                  style: AppText.label.copyWith(color: AppColors.gold),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (onToday != null)
            TextButton(onPressed: onToday, child: const Text('Back to today')),
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
                      color: AppColors.sand.withValues(alpha: 0.7),
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
                      date: HijriDate(
                        hijri.year,
                        hijri.month,
                        row * 7 + col - offset + 1,
                      ),
                      day: row * 7 + col - offset + 1,
                      valid:
                          row * 7 + col >= offset &&
                          row * 7 + col < offset + days,
                      isToday:
                          hijri.year == today.year &&
                          hijri.month == today.month &&
                          row * 7 + col - offset + 1 == today.day,
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
    required this.date,
    required this.day,
    required this.valid,
    required this.isToday,
    required this.markers,
  });

  final HijriDate date;
  final int day;
  final bool valid;
  final bool isToday;
  final List<FastingMarker> markers;

  @override
  Widget build(BuildContext context) {
    final bool recommended = markers.any(
      (FastingMarker m) => m.kind != FastingKind.forbidden,
    );
    final bool forbidden = markers.any(
      (FastingMarker m) => m.kind == FastingKind.forbidden,
    );

    final String note = forbidden
        ? ', fasting is not allowed on this day'
        : recommended
            ? ', a recommended fasting day'
            : '';
    return Semantics(
      label: valid ? 'Day $day$note' : null,
      button: valid && markers.isNotEmpty,
      excludeSemantics: valid,
      child: FocusableTap(
      behavior: HitTestBehavior.opaque,
      onTap: valid && markers.isNotEmpty
          ? () => showFastingKnowledgeSheet(context, markers, date: date)
          : null,
      child: Container(
        width: 36,
        height: 44,
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
      ),
    );
  }
}

/// One-tap knowledge card for any fasting marker — the "why" with its
/// source on screen, per the app's authenticity constitution.
void showFastingKnowledgeSheet(
  BuildContext context,
  List<FastingMarker> markers, {
  HijriDate? date,
}) {
  showNamedSheet<void>(
    label: 'Fasting days',
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
            if (date != null) ...[
              Text(_hijriWithGregorian(date), style: AppText.caption),
              const SizedBox(height: 12),
            ],
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
                  color: AppColors.gold.withValues(alpha: 0.9),
                  fontSize: 12,
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
    final bool obligatory = first.kind == FastingKind.obligatory;
    final HijriDate todayHijri = HijriDate.fromGregorian(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: FocusRing(borderRadius: 20, child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () =>
            showFastingKnowledgeSheet(context, markers, date: todayHijri),
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
                : obligatory
                ? 'Ramadan — the fast is obligatory today'
                : 'Sunnah to fast today — tap to learn why',
            style: AppText.caption.copyWith(
              color: forbidden ? AppColors.destructive : AppColors.gold,
            ),
          ),
        ),
      )),
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
            FocusRing(borderRadius: 12, child: InkWell(
              onTap: () => showFastingKnowledgeSheet(
                context,
                days[i].$2,
                date: days[i].$1,
              ),
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
            )),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// "in 12 days", "Tomorrow" or "Today" for a whole-day distance.
String _inDays(int daysAway) => daysAway == 0
    ? 'Today'
    : daysAway == 1
    ? 'Tomorrow'
    : 'in $daysAway days';

/// The next observance, and the next Ramadan, at the top of the page so
/// nobody scrolls past the month grid to find them.
class _NextEventBanner extends StatelessWidget {
  const _NextEventBanner({required this.upcoming, required this.today});

  final List<(Observance, HijriDate)> upcoming;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final int todayJd = HijriDate.gregorianToJd(
      today.year,
      today.month,
      today.day,
    );
    String when((Observance, HijriDate) e) {
      final DateTime g = e.$2.toGregorian();
      return '${_inDays(_daysUntil(e.$2, todayJd)).toLowerCase()} '
          '\u00b7 ${g.day} ${_kShortMonths[g.month - 1]} ${g.year}';
    }

    final (Observance, HijriDate) next = upcoming.first;
    (Observance, HijriDate)? ramadan;
    for (final (Observance, HijriDate) e in upcoming) {
      if (e.$1.nameEn == 'Ramadan Begins') ramadan = e;
    }
    final bool ramadanIsNext = ramadan != null && ramadan.$1 == next.$1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        key: const Key('calendar-next-event'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next: ${next.$1.nameEn} ${when(next)}',
              style: AppText.body,
            ),
            if (ramadan != null && !ramadanIsNext) ...[
              const SizedBox(height: 6),
              Text(
                'Ramadan begins ${when(ramadan)}',
                style: AppText.bodyMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ObservancesCard extends StatefulWidget {
  const _ObservancesCard({required this.upcoming});

  final List<(Observance, HijriDate)> upcoming;

  @override
  State<_ObservancesCard> createState() => _ObservancesCardState();
}

class _ObservancesCardState extends State<_ObservancesCard> {
  static const int _initial = 6;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int todayJd = HijriDate.gregorianToJd(now.year, now.month, now.day);
    final List<(Observance, HijriDate)> shown = _all
        ? widget.upcoming
        : widget.upcoming.take(_initial).toList();

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
          for (int i = 0; i < shown.length; i++) ...[
            if (i > 0)
              Divider(height: 16, color: AppColors.gold.withValues(alpha: 0.1)),
            _ObservanceRow(
              observance: shown[i].$1,
              date: shown[i].$2,
              // Same calendar as the Gregorian date printed on the row.
              daysAway: _daysUntil(shown[i].$2, todayJd),
            ),
          ],
          if (widget.upcoming.length > _initial)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('observances-toggle'),
                onPressed: () => setState(() => _all = !_all),
                child: Text(
                  _all
                      ? 'Show fewer'
                      : 'Show all ${widget.upcoming.length}',
                ),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Whole days from today ([todayJd]) to [date], measured on the Gregorian
/// date the row itself prints (Umm al-Qura where in range), never on a
/// second calendar.
int _daysUntil(HijriDate date, int todayJd) {
  final DateTime g = date.toGregorian();
  return HijriDate.gregorianToJd(g.year, g.month, g.day) - todayJd;
}

/// What the day is, how firmly it is established, and its source.
void showObservanceSheet(
  BuildContext context,
  Observance observance,
  HijriDate date,
  String gregorian,
  String when,
) {
  showNamedSheet<void>(
    label: 'About this day',
    context: context,
    backgroundColor: AppColors.navy,
    isScrollControlled: true,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    observance.nameEn,
                    style: AppText.label.copyWith(color: AppColors.sand),
                  ),
                ),
                Text(
                  observance.nameAr,
                  style: AppText.caption.copyWith(
                    fontFamily: AppFonts.arabic,
                    color: AppColors.gold,
                  ),
                ),
                // The public occasion only: its name, date, how firmly it is
                // established and its source. Never a personal reminder.
                ShareButton(
                  doc: ShareDoc.calendarOccasion(
                    name: observance.nameEn,
                    dateLine: '${date.format()} · $gregorian',
                    basis: observance.basis.label,
                    about: observance.about,
                    source: observance.source,
                    reviewKey:
                        'calendar.observance.${observance.month}-${observance.day}',
                  ),
                  subject: observance.nameEn,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${date.format()} · $gregorian · $when',
              style: AppText.caption,
            ),
            const SizedBox(height: 12),
            Text(
              observance.basis.label.toUpperCase(),
              style: AppText.eyebrow.copyWith(color: AppColors.gold),
            ),
            if (observance.about.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                observance.about,
                style: AppText.body.copyWith(
                  color: AppColors.sand.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ],
            if (observance.source.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                observance.source,
                style: AppText.eyebrow.copyWith(
                  color: AppColors.gold.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Dates follow the Umm al-Qura calendar; confirm by local moon '
              'sighting.',
              style: AppText.caption,
            ),
          ],
        ),
      );
    },
  );
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

    final String gregorian = '${g.day} ${months[g.month - 1]} ${g.year}';
    return FocusRing(borderRadius: 12, child: InkWell(
      key: Key('observance-${observance.nameEn}'),
      onTap: () =>
          showObservanceSheet(context, observance, date, gregorian, when),
      child: Row(
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
                '${date.format()} · $gregorian · $when',
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
        Icon(
          Icons.chevron_right,
          size: 16,
          color: AppColors.gold.withValues(alpha: 0.5),
        ),
      ],
      ),
    ));
  }
}
