import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' hide Text;
import '../../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/sakina_content.dart';

/// True when a tap on a `tel:` link can actually place a call: phones, and
/// the browsers on them. Desktop browsers and desktop apps cannot, and the
/// call result is not reliable there, so the number is shown and copied
/// instead.
bool canPlaceCalls() {
  final TargetPlatform p = defaultTargetPlatform;
  return p == TargetPlatform.android || p == TargetPlatform.iOS;
}

/// Copies a help line's number (or address) and says so.
Future<void> copyHelpContact(
  BuildContext context,
  HelpResource resource,
) async {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  final String text = resource.dial ?? resource.url ?? resource.contact;
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } catch (_) {
    // Clipboard blocked: say so, and point at the number on screen. A
    // "Copied" message over a failed copy would be a lie.
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          'Could not copy. The number is on this screen: ${resource.contact}',
        ),
      ),
    );
    return;
  }
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        'Copied ${resource.contact}. Paste it into your phone to call.',
      ),
    ),
  );
}

/// Taps a help line: dials on a phone, opens the site, and on a desktop
/// browser (where `tel:` does nothing) copies the number instead.
Future<void> activateHelpResource(
  BuildContext context,
  HelpResource resource,
) async {
  final String? dial = resource.dial;
  final String? url = resource.url;
  if (dial != null) {
    if (canPlaceCalls()) {
      bool opened = false;
      try {
        opened = await launchUrl(Uri(scheme: 'tel', path: dial));
      } catch (_) {
        opened = false;
      }
      if (opened) return;
    }
    if (!context.mounted) return;
    await copyHelpContact(context, resource);
    return;
  }
  if (url != null) {
    bool opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      await copyHelpContact(context, resource);
    }
  }
}

/// The address of a web page without the scheme and a trailing slash, for
/// showing under a help line that is a page.
String _shortAddress(String url) {
  String t = url.replaceFirst(RegExp(r'^https?://'), '');
  if (t.startsWith('www.')) t = t.substring(4);
  if (t.endsWith('/')) t = t.substring(0, t.length - 1);
  return t;
}

/// One help line: name, who it is for, what it is, and the number in plain
/// selectable-looking text — with a copy button that always works.
class HelpLineTile extends StatelessWidget {
  const HelpLineTile({super.key, required this.resource});

  final HelpResource resource;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => activateHelpResource(context, resource),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${resource.name} · ${resource.region}',
                        style: AppText.caption.copyWith(
                          color: AppColors.sand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (resource.detail.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          resource.detail,
                          style: AppText.caption.copyWith(
                            color: AppColors.sand.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        resource.contact,
                        style: AppText.caption.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // A row that is a web page (a directory such as the
                      // Government of Canada list) shows its address, so it
                      // is plain that tapping opens a page and not a call.
                      if (resource.dial == null && resource.url != null)
                        Row(
                          children: <Widget>[
                            const Icon(Icons.open_in_new,
                                size: 14, color: AppColors.sand),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _shortAddress(resource.url!),
                                key: const Key('help-line-address'),
                                style: AppText.caption.copyWith(
                                  color: AppColors.sand.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (!resource.verified)
                        Text(
                          'Not re-checked recently. If it does not connect, '
                          'try another line or your local emergency number.',
                          style: AppText.caption.copyWith(
                            color: AppColors.sand.withValues(alpha: 0.7),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Copy',
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          color: AppColors.gold,
          icon: const Icon(Icons.copy_outlined),
          onPressed: () => copyHelpContact(context, resource),
        ),
      ],
    );
  }
}
