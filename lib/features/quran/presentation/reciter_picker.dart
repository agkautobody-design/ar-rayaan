import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../academy/application/recitation_player_provider.dart';
import '../../academy/domain/recitation_audio.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../../app/theme/widgets/named_sheet.dart';

/// Opens the reciter list. Changing reciter stops the current recitation
/// (a half-finished plan must never switch voices mid-ayah).
Future<void> showReciterPicker(BuildContext context, WidgetRef ref) {
  return showNamedSheet<void>(
    label: 'Choose a reciter',
    context: context,
    backgroundColor: AppColors.navy,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => const ReciterPickerSheet(),
  );
}

class ReciterPickerSheet extends ConsumerWidget {
  const ReciterPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReciterPack selected = ref.watch(selectedReciterProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: <Widget>[
            Text('Choose a reciter', style: AppText.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Real recorded recitation, never AI voices. The reciter is named '
              'whenever audio plays.',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (final ReciterPack pack in ReciterPack.all)
              Semantics(
                button: true,
                selected: pack.id == selected.id,
                label: '${pack.displayName}, ${pack.style}',
                child: FocusRing(borderRadius: 12, child: InkWell(
                  onTap: () async {
                    await ref.read(recitationPlayerProvider.notifier).stop();
                    await ref
                        .read(selectedReciterProvider.notifier)
                        .select(pack);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          pack.id == selected.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: AppColors.gold,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(pack.displayName, style: AppText.body),
                              Text(pack.style, style: AppText.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ),
            const SizedBox(height: 8),
            Text(
              'Audio is streamed from everyayah.com. That source does not offer a '
              'female reciter.',
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}
