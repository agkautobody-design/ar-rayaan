import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../application/family_service.dart';

/// The parent-set age band for one child: 5-8, 9-12 or 13-17. It is not an
/// age or a birth date; it only chooses the words Wasia uses with that child.
/// Shown on the child's card (parent area only).
class AgeBandChooser extends ConsumerStatefulWidget {
  const AgeBandChooser({super.key, required this.childId, required this.childName});

  final String childId;
  final String childName;

  @override
  ConsumerState<AgeBandChooser> createState() => _AgeBandChooserState();
}

class _AgeBandChooserState extends ConsumerState<AgeBandChooser> {
  String _band = FamilyService.defaultAgeBand;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String b = await ref.read(familyServiceProvider).ageBand(widget.childId);
    if (mounted) setState(() => _band = b);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text('Wasia’s words for ${widget.childName}', style: AppText.eyebrow.copyWith(fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: <Widget>[
          for (final String b in FamilyService.ageBands)
            ChoiceChip(
              key: Key('age-band-${widget.childId}-$b'),
              label: Text(b),
              selected: _band == b,
              selectedColor: AppColors.gold.withValues(alpha: 0.3),
              onSelected: (_) async {
                setState(() => _band = b);
                await ref.read(familyServiceProvider).setAgeBand(widget.childId, b);
              },
            ),
        ]),
        Text(
          'An age band, not an age. It only picks the words Wasia uses. It stays on this device.',
          style: AppText.caption.copyWith(fontSize: 12),
        ),
      ]),
    );
  }
}
