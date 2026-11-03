import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/share_service.dart';
import '../application/share_text.dart';
import 'share_actions.dart';

/// SHARE AR-RAYAAN — one page that hands the app to the next person.
///
/// Two roads, both to the same fixed address ([kInviteUrl] through
/// [appUrlProvider]): a QR code for someone in the room, and the link
/// itself to send by message or email. Sending goes through the share
/// preview like every share in the app, so the person sees exactly what
/// leaves before anything does.
class ShareAppScreen extends ConsumerWidget {
  const ShareAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String url = ref.watch(appUrlProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Share Ar-Rayaan', close: true),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Text('THE QR CODE', style: AppText.eyebrow),
                  const SizedBox(height: 10),
                  Semantics(
                    image: true,
                    label: 'QR code that opens the app at $url',
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(data: url, size: 180),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Point any camera at the code — the app opens straight '
                    'away, free, with no account.',
                    style: AppText.bodyMuted.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  ]),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Text('THE LINK', style: AppText.eyebrow),
                  const SizedBox(height: 6),
                  Text(
                    url,
                    key: const Key('share-app-url'),
                    style: AppText.body.copyWith(
                      color: AppColors.goldLight,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kShareDownloadLine,
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  GoldButton(
                    key: const Key('share-app-send'),
                    label: 'Send the link',
                    trailing: const Icon(Icons.ios_share, size: 18),
                    onPressed: () => showSharePreview(
                      context,
                      doc: ShareDoc.invite(),
                      subject: 'this invitation',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: OutlinedButton.icon(
                      key: const Key('share-app-copy'),
                      onPressed: () => copyWithFeedback(context, url),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy the link'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The Send button opens your phone’s own share sheet — '
                    'pick a text message, an email, or any app you like.',
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
