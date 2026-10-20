import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../domain/hawl_tracker.dart';
import '../domain/zakat_al_fitr.dart';
import '../domain/zakat_calculation.dart';

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

/// Hawl tracker — the day the user's wealth first reached nisab, and when
/// the lunar year completes. Saved on this device only.
class HawlCard extends ConsumerStatefulWidget {
  const HawlCard({super.key});

  @override
  ConsumerState<HawlCard> createState() => _HawlCardState();
}

class _HawlCardState extends ConsumerState<HawlCard> {
  static const String _key = 'ar.zakat.hawl.start';
  DateTime? _start;

  @override
  void initState() {
    super.initState();
    final String? raw = _prefsOrNull(ref)?.getString(_key);
    if (raw != null) _start = DateTime.tryParse(raw);
  }

  Future<void> _pick() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: 'The day my wealth first reached nisab',
    );
    if (picked == null || !mounted) return;
    setState(() => _start = picked);
    final String iso =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    await _prefsOrNull(ref)?.setString(_key, iso);
  }

  Future<void> _clear() async {
    setState(() => _start = null);
    await _prefsOrNull(ref)?.remove(_key);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? start = _start;
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
              'Started ${s.startHijri.format()} '
              '(${s.start.day} ${_months[s.start.month - 1]} ${s.start.year}) '
              '· completes ${s.dueHijri.format()} '
              '(${s.dueDate.day} ${_months[s.dueDate.month - 1]} '
              '${s.dueDate.year}).',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Schools differ on whether the year restarts if you dip below '
            'nisab part-way (Hanafi: nisab is needed at the start and at the '
            'end). This tracker only counts the year; the judgement is '
            'yours and your scholar’s.',
            style: AppText.bodyMuted.copyWith(fontSize: 11, height: 1.5),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.event_outlined, size: 16),
                label: Text(s == null ? 'Set the start day' : 'Change day'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldLight,
                ),
              ),
              if (s != null)
                TextButton(
                  onPressed: _clear,
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

/// Zakat al-Fitr — household head-count times the per-person amount the
/// user's mosque or charity announces. The app supplies no figure of its
/// own (see [ZakatAlFitr]).
class ZakatAlFitrCard extends ConsumerStatefulWidget {
  const ZakatAlFitrCard({super.key});

  @override
  ConsumerState<ZakatAlFitrCard> createState() => _ZakatAlFitrCardState();
}

class _ZakatAlFitrCardState extends ConsumerState<ZakatAlFitrCard> {
  static const String _peopleKey = 'ar.zakat.fitr.people';
  static const String _amountKey = 'ar.zakat.fitr.amount';

  final TextEditingController _amount = TextEditingController();
  int _people = 1;

  @override
  void initState() {
    super.initState();
    final SharedPreferences? p = _prefsOrNull(ref);
    _people = ZakatAlFitr.clampPeople(p?.getInt(_peopleKey) ?? 1);
    final String? saved = p?.getString(_amountKey);
    if (saved != null) _amount.text = saved;
    _amount.addListener(_onAmount);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _onAmount() {
    setState(() {});
    // Fire and forget: losing one keystroke's save is harmless.
    _prefsOrNull(ref)?.setString(_amountKey, _amount.text).ignore();
  }

  void _setPeople(int n) {
    final int v = ZakatAlFitr.clampPeople(n);
    setState(() => _people = v);
    _prefsOrNull(ref)?.setInt(_peopleKey, v).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final double per = ZakatCalculation.parseAmount(_amount.text);
    final double total = ZakatAlFitr.total(people: _people, perPerson: per);
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
            'the Eid prayer. Ar-Rayaan does not set the amount for you: enter '
            'the per-person figure your mosque, charity or scholar announces '
            'for this year (they convert the sa’ to a weight or value). '
            '${ZakatAlFitr.source}',
            style: AppText.bodyMuted.copyWith(fontSize: 11.5, height: 1.5),
          ),
          const SizedBox(height: 10),
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
              Expanded(
                child: TextField(
                  key: const Key('fitr-amount'),
                  controller: _amount,
                  style: AppText.body,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Per person',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            total > 0
                ? 'Total for $_people: ${ZakatCalculation.formatAmount(total)}'
                : 'Enter the per-person amount to see the household total.',
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w600,
              color: total > 0 ? AppColors.goldLight : AppColors.sand,
            ),
          ),
        ],
      ),
    );
  }
}
