import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';

/// Share Ar-Rayaan — the beta-invite QR.
///
/// The QR encodes the app's own public URL (appUrlProvider): the Founder's
/// domain via --dart-define=APP_URL, otherwise wherever the app is hosted.
/// Colors follow the locked system; the code is dark-on-light (night on
/// sand) so every scanner reads it.
class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String url = ref.watch(appUrlProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Share Ar-Rayaan'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'الرَّيَّان',
                          style: AppText.arabicLarge.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BETA · INVITE A TESTER',
                          style: AppText.eyebrow.copyWith(
                            color: AppColors.sand.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.gold, width: 2),
                          ),
                          child: QrImageView(
                            data: url,
                            version: QrVersions.auto,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            size: 240,
                            backgroundColor: AppColors.sand,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.night,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.night,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: url));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link copied')),
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  url,
                                  style: AppText.bodyMuted.copyWith(
                                    color: AppColors.gold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.copy_outlined,
                                size: 14,
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADD TO ANY HOME SCREEN',
                          style: AppText.eyebrow.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _PlatformRow(
                          icon: Icons.android,
                          text:
                              'Android · open the link in Chrome → ⋮ menu → Add to Home screen',
                        ),
                        const SizedBox(height: 8),
                        const _PlatformRow(
                          icon: Icons.phone_iphone,
                          text:
                              'iPhone · open in Safari → Share → Add to Home Screen',
                        ),
                        const SizedBox(height: 8),
                        const _PlatformRow(
                          icon: Icons.laptop_mac,
                          text:
                              'Desktop / Chromebook · open in Chrome → install icon in the address bar',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SCAN WITH ANY CAMERA · WORKS ON ANDROID, IOS & DESKTOP',
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

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppText.bodyMuted.copyWith(height: 1.5)),
        ),
      ],
    );
  }
}
