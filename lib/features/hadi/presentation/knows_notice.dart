import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../support/application/support_settings.dart';
import '../application/user_knows_provider.dart';

/// The one-time note above Hadi's first suggestions: he notices what you ask
/// about so the suggestions fit you, and you can turn that off right here.
/// It does not appear in Private mode, once it has been answered, or after
/// the person turned noticing off.
class KnowsNotice extends ConsumerWidget {
  const KnowsNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userKnowsProvider);
    final UserKnowsNotifier n = ref.read(userKnowsProvider.notifier);
    bool priv = false;
    try {
      priv = ref.watch(supportSettingsProvider).privateMode;
    } catch (_) {}
    if (priv || !n.on || n.noticeSeen) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        key: const Key('knows-notice'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              const Icon(Icons.favorite_border, size: 16, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Hadi gets to know you',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              'He notices what you like to ask about, so his suggestions fit '
              'you. It stays on this device, and in your own account if you '
              'sign in. He never keeps anything about health, safety or '
              'hard times. See or delete it any time in Settings.',
              style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  key: const Key('knows-notice-off'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => n.setOn(false),
                  child: const Text('Turn off'),
                ),
                TextButton(
                  key: const Key('knows-notice-ok'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => n.markNoticeSeen(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
