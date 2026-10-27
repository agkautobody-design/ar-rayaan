/// Picks a surah by name or number for the Hifz planner (replaces tapping
/// plus/minus up to 113 times). Uses the bundled surah index.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../quran/domain/quran_index.dart';
import '../../quran/domain/quran_models.dart';
import '../../quran/domain/surah_search.dart';

/// The name of surah [number] ("Al-Kahf"), or '' when out of range.
String hifzSurahName(int number) =>
    number >= 1 && number <= kSurahIndex.length
        ? kSurahIndex[number - 1].transliteration
        : '';

/// A tappable field showing "18 · Al-Kahf" that opens the searchable list.
class HifzSurahPicker extends StatelessWidget {
  const HifzSurahPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  Future<void> _open(BuildContext context) async {
    final int? picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0A0F18),
      builder: (BuildContext ctx) => _SurahSheet(current: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final String label = '$value · ${hifzSurahName(value)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Surah', style: AppText.caption),
        const SizedBox(height: 4),
        Semantics(
          button: true,
          label: 'Surah: $label. Tap to choose another surah.',
          excludeSemantics: true,
          child: OutlinedButton(
            key: const Key('hifz-surah-picker'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: AppColors.gold,
              alignment: Alignment.centerLeft,
            ),
            onPressed: () => _open(context),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(color: AppColors.gold),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.gold),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SurahSheet extends StatefulWidget {
  const _SurahSheet({required this.current});

  final int current;

  @override
  State<_SurahSheet> createState() => _SurahSheetState();
}

class _SurahSheetState extends State<_SurahSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<SurahMeta> shown = filterSurahs(kSurahIndex, _query);
    final double height = MediaQuery.sizeOf(context).height * 0.75;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: height,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Semantics(label: 'Find a surah: name or number', child: TextField(
                key: const Key('hifz-surah-search'),
                autofocus: false,
                style: AppText.body,
                decoration: const InputDecoration(
                  hintText: 'Find a surah: name or number',
                  prefixIcon: Icon(Icons.search, color: AppColors.gold),
                ),
                onChanged: (String v) => setState(() => _query = v),
              )),
            ),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(
                        'No surah matches that. Try a name like Yasin or a '
                        'number from 1 to 114.',
                        textAlign: TextAlign.center,
                        style: AppText.bodyMuted,
                      ),
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (BuildContext ctx, int i) {
                        final SurahMeta m = shown[i];
                        return ListTile(
                          key: Key('hifz-surah-${m.number}'),
                          minTileHeight: 56,
                          selected: m.number == widget.current,
                          selectedColor: AppColors.gold,
                          leading: Text('${m.number}', style: AppText.caption),
                          title: Text(m.transliteration),
                          subtitle: Text(
                            '${m.englishMeaning} · ${m.ayahCount} ayat',
                          ),
                          trailing: Text(
                            m.arabicName,
                            style: AppText.arabicLarge.copyWith(fontSize: 18),
                          ),
                          onTap: () => Navigator.of(ctx).pop(m.number),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
