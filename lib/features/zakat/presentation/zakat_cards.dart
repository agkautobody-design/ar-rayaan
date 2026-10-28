import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/notifications/prayer_notification_scheduler.dart';
import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../calendar/application/hijri_settings.dart';
import '../application/hawl_provider.dart';
import '../application/zakat_history_provider.dart';
import '../application/zakat_reminder_providers.dart';
import '../domain/hawl_tracker.dart';
import '../domain/zakat_al_fitr.dart';
import '../domain/zakat_calculation.dart';
import '../domain/zakat_history.dart';

SharedPreferences? _prefsOrNull(WidgetRef ref) {
  try {
    return ref.read(sharedPreferencesProvider);
  } catch (_) {
    return null; // not initialised (tests): state lives in memory only
  }
}

const List<String> _months = <String>[
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

String _day(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// A reminder switch that asks for notification permission when turned on
/// and says plainly when this device cannot deliver one.
class _ReminderSwitch extends ConsumerWidget {
  const _ReminderSwitch({
    required this.keyName,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String keyName;
  final String label;
  final bool value;
  final Future<bool> Function(bool on) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool supported = ref
        .watch(prayerNotificationSchedulerProvider)
        .supported;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: Key(keyName),
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: value,
          activeThumbColor: AppColors.gold,
          title: Text(
            label,
            style: AppText.label.copyWith(color: AppColors.sand),
          ),
          onChanged: (bool on) async {
            final bool ok = await onChanged(on);
            if (on && !ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    supported
                        ? 'Notifications are off for Ar-Rayaan in your phone '
                              'settings, so this reminder cannot show.'
                        : 'Reminders need the Android or iPhone app; this '
                              'browser cannot wake itself up.',
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

/// Hawl tracker — the day the user's wealth first reached nisab, and when
/// the lunar year completes. Saved on this device only.
class HawlCard extends ConsumerStatefulWidget {
  const HawlCard({super.key});

  @override
  ConsumerState<HawlCard> createState() => _HawlCardState();
}

class _HawlCardState extends ConsumerState<HawlCard> {
  Future<void> _pick(DateTime? current) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: 'The day my wealth first reached nisab',
    );
    if (picked == null || !mounted) return;
    await ref.read(hawlStartProvider.notifier).set(picked);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? start = ref.watch(hawlStartProvider);
    // The year is counted on the Hijri calendar the user chose.
    ref.watch(hijriSettingsProvider);
    final ZakatReminderSettings reminders = ref.watch(zakatReminderProvider);
    final HawlStatus? s = start == null
        ? null
        : HawlTracker.status(start, DateTime.now());
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HAWL · YOUR ZAKAT YEAR',
            style: AppText.eyebrow.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 8),
          if (s == null)
            Text(
              'Zakat falls due once your wealth has stayed at or above nisab '
              'for one lunar year (hawl). Mark the day it first reached '
              'nisab and the app will count the year on the Hijri calendar.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            )
          else ...[
            Text(
              s.isComplete
                  ? 'Your hawl is complete — zakat is due now.'
                  : 'Zakat falls due in ${s.daysLeft} '
                        '${s.daysLeft == 1 ? 'day' : 'days'}.',
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: s.isComplete ? AppColors.goldLight : AppColors.sand,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Started ${s.startHijri.format()} (${_day(s.start)}) '
              '· completes ${s.dueHijri.format()} (${_day(s.dueDate)}). '
              'By the Hijri calendar you chose; a month can begin a day '
              'earlier or later where you live.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Scholars differ on whether the year restarts if you dip below '
            'nisab part-way. This tracker only counts the year; whether a dip '
            'matters is a question for your scholar.',
            style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
          ),
          if (s != null)
            _ReminderSwitch(
              keyName: 'hawl-reminder',
              label: 'Remind me 3 days before and on the day at 9 am',
              value: reminders.hawl,
              onChanged: (bool on) =>
                  ref.read(zakatReminderProvider.notifier).setHawl(on),
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _pick(start),
                icon: const Icon(Icons.event_outlined, size: 16),
                label: Text(s == null ? 'Set the start day' : 'Change day'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldLight,
                ),
              ),
              if (s != null)
                TextButton(
                  onPressed: () => ref.read(hawlStartProvider.notifier).clear(),
                  child: Text(
                    'Clear',
                    style: AppText.bodyMuted.copyWith(color: AppColors.gold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// How the household total is worked out.
enum _FitrMode { announced, staple }

/// Zakat al-Fitr — household head-count times an amount that comes from the
/// user's mosque, charity or scholar. The app supplies no figure of its own
/// (see [ZakatAlFitr]); it only multiplies.
class ZakatAlFitrCard extends ConsumerStatefulWidget {
  const ZakatAlFitrCard({super.key});

  @override
  ConsumerState<ZakatAlFitrCard> createState() => _ZakatAlFitrCardState();
}

class _ZakatAlFitrCardState extends ConsumerState<ZakatAlFitrCard> {
  static const String _peopleKey = 'ar.zakat.fitr.people';
  static const String _amountKey = 'ar.zakat.fitr.amount';
  static const String _modeKey = 'ar.zakat.fitr.mode';
  static const String _kgKey = 'ar.zakat.fitr.kg';
  static const String _priceKey = 'ar.zakat.fitr.price';

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _kg = TextEditingController();
  final TextEditingController _price = TextEditingController();
  int _people = 1;
  _FitrMode _mode = _FitrMode.announced;

  @override
  void initState() {
    super.initState();
    final SharedPreferences? p = _prefsOrNull(ref);
    _people = ZakatAlFitr.clampPeople(p?.getInt(_peopleKey) ?? 1);
    final String? saved = p?.getString(_amountKey);
    if (saved != null) _amount.text = saved;
    _kg.text = p?.getString(_kgKey) ?? '';
    _price.text = p?.getString(_priceKey) ?? '';
    if (p?.getString(_modeKey) == 'staple') _mode = _FitrMode.staple;
    _amount.addListener(() => _onText(_amountKey, _amount));
    _kg.addListener(() => _onText(_kgKey, _kg));
    _price.addListener(() => _onText(_priceKey, _price));
  }

  @override
  void dispose() {
    _amount.dispose();
    _kg.dispose();
    _price.dispose();
    super.dispose();
  }

  void _onText(String key, TextEditingController c) {
    setState(() {});
    // Fire and forget: losing one keystroke's save is harmless.
    _prefsOrNull(ref)?.setString(key, c.text).ignore();
  }

  void _setPeople(int n) {
    final int v = ZakatAlFitr.clampPeople(n);
    setState(() => _people = v);
    _prefsOrNull(ref)?.setInt(_peopleKey, v).ignore();
  }

  void _setMode(_FitrMode m) {
    setState(() => _mode = m);
    _prefsOrNull(
      ref,
    )?.setString(_modeKey, m == _FitrMode.staple ? 'staple' : 'announced').ignore();
  }

  double get _total {
    if (_mode == _FitrMode.announced) {
      return ZakatAlFitr.total(
        people: _people,
        perPerson: ZakatCalculation.parseAmount(_amount.text),
      );
    }
    return ZakatAlFitr.totalFromStaple(
      people: _people,
      kgPerPerson: ZakatCalculation.parseAmount(_kg.text),
      pricePerKg: ZakatCalculation.parseAmount(_price.text),
    );
  }

  Widget _modeChip(String label, _FitrMode m) => ChoiceChip(
    label: Text(label),
    selected: _mode == m,
    onSelected: (_) => _setMode(m),
  );

  @override
  Widget build(BuildContext context) {
    final double total = _total;
    final ZakatReminderSettings reminders = ref.watch(zakatReminderProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ZAKAT AL-FITR · BEFORE THE EID PRAYER',
            style: AppText.eyebrow.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 8),
          Text(
            'Due for every Muslim in the household, young or old: one sa’ '
            'of food (the Prophet ﷺ named dates and barley), paid before '
            'the Eid prayer. A sa’ is a measure of volume that scholars '
            'convert to a weight differently, and the schools differ on '
            'whether its value in money may be given instead, so Ar-Rayaan '
            'sets no amount: use the figure your mosque, charity or scholar '
            'announces this year. ${ZakatAlFitr.source}',
            style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _modeChip('Their figure per person', _FitrMode.announced),
              _modeChip('Staple weight × price', _FitrMode.staple),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('People', style: AppText.label),
              IconButton(
                tooltip: 'One fewer',
                onPressed: () => _setPeople(_people - 1),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppColors.gold,
              ),
              Text('$_people', style: AppText.body),
              IconButton(
                tooltip: 'One more',
                onPressed: () => _setPeople(_people + 1),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              if (_mode == _FitrMode.announced)
                Expanded(
                  child: Semantics(label: 'Per person', child: TextField(
                    key: const Key('fitr-amount'),
                    controller: _amount,
                    style: AppText.body,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(hintText: 'Per person'),
                  )),
                ),
            ],
          ),
          if (_mode == _FitrMode.staple) ...[
            Row(
              children: [
                Expanded(
                  child: Semantics(label: 'kg per person (from them)', child: TextField(
                    key: const Key('fitr-kg'),
                    controller: _kg,
                    style: AppText.body,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'kg per person (from them)',
                    ),
                  )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(label: 'Price per kg', child: TextField(
                    key: const Key('fitr-price'),
                    controller: _price,
                    style: AppText.body,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Price per kg',
                    ),
                  )),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            total > 0
                ? 'Total for $_people: ${ZakatCalculation.formatAmount(total)}'
                : _mode == _FitrMode.announced
                ? 'Enter the per-person amount to see the household total.'
                : 'Enter the weight and the price to see the household total.',
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w600,
              color: total > 0 ? AppColors.goldLight : AppColors.sand,
            ),
          ),
          _ReminderSwitch(
            keyName: 'fitr-reminder',
            label: 'Remind me two days and one day before Eid at 9 am',
            value: reminders.fitr,
            onChanged: (bool on) =>
                ref.read(zakatReminderProvider.notifier).setFitr(on),
          ),
        ],
      ),
    );
  }
}

/// Saved calculations, newest first, with a plain comparison against the
/// one from about a year earlier. Everything stays on this device.
class ZakatHistoryCard extends ConsumerWidget {
  const ZakatHistoryCard({super.key});

  static String _signed(double v) =>
      '${v >= 0 ? '+' : '-'}${ZakatCalculation.formatAmount(v.abs())}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ZakatRecord> records = ref.watch(zakatHistoryProvider);
    if (records.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SAVED CALCULATIONS',
              style: AppText.eyebrow.copyWith(color: AppColors.gold),
            ),
            const SizedBox(height: 8),
            Text(
              'Save a calculation each year to see how your zakat compares. '
              'Only the result is kept (not your balances), on this device.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      );
    }
    final ZakatRecord latest = records.first;
    final ZakatRecord? before = ZakatHistory.comparisonFor(latest, records);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAVED CALCULATIONS',
            style: AppText.eyebrow.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 8),
          if (before != null) ...[
            Text(
              ZakatHistory.isYearApart(latest, before)
                  ? 'Compared with last year (${_day(before.date)})'
                  : 'Compared with your previous save (${_day(before.date)})',
              style: AppText.label.copyWith(color: AppColors.sand),
            ),
            const SizedBox(height: 2),
            Text(
              'Zakat due ${_signed(latest.zakatDue - before.zakatDue)} · '
              'net wealth ${_signed(latest.netZakatable - before.netZakatable)}'
              '${before.nisabBasis != latest.nisabBasis || before.madhab != latest.madhab || before.tolaFigures != latest.tolaFigures ? '\nThe nisab basis or school differs between the two, so the figures are not like for like.' : ''}',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 8),
          ],
          for (final ZakatRecord r in records)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_day(r.date)} · ${r.eligible ? 'due ${ZakatCalculation.formatAmount(r.zakatDue)}' : 'below nisab'}'
                      '${r.currency.isEmpty ? '' : ' ${r.currency}'}'
                      ' · ${r.nisabBasis}',
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete this saved calculation',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        ref.read(zakatHistoryProvider.notifier).remove(r),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.sand.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
