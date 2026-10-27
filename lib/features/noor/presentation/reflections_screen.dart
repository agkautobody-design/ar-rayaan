import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/noor_providers.dart';

/// /noor/reflections — the reflections the person saved from NOOR, newest
/// first. Tap one to read it in full. They are kept on this device only.
class ReflectionsScreen extends ConsumerWidget {
  const ReflectionsScreen({super.key});

  Future<void> _view(BuildContext context, String text) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        semanticLabel: 'Your reflection',
        title: const Text('Your reflection'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> items = ref.watch(noorReflectionsProvider);
    return ScenicScaffold.pattern(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: <Widget>[
            const ScreenHeader(title: 'My Reflections'),
            if (items.isEmpty)
              GlassCard(
                child: Text(
                  'Nothing saved yet. Open Today’s NOOR and write a reflection '
                  'in a few words. They stay on this device.',
                  key: const Key('reflections-empty'),
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              )
            else
              for (int i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () => _view(context, items[i]),
                    child: Text(
                      items[i],
                      key: Key('reflection-$i'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        color: AppColors.sand,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
