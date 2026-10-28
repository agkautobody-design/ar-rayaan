/// Copy feedback, the share preview sheet and the one [ShareButton].
///
/// A share can only be made from a `ShareDoc` of public content (see
/// `share_service.dart`); this file has no way to send an arbitrary string.
/// Every action says what happened: a "Copied" snackbar, the system share
/// sheet, or an honest message when the clipboard is blocked.
library;

import 'dart:async' show unawaited;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/core/child_mode.dart';
import '../../elder/application/elder_mode.dart';
import '../application/share_service.dart';
import '../../../app/theme/widgets/named_sheet.dart';

/// Shown after a successful copy.
const String kCopiedMessage = kShareCopiedMessage;

/// Shown when the browser or device refused the clipboard.
const String kCopyBlockedMessage = kShareCopyBlockedMessage;

void _say(ScaffoldMessengerState? messenger, String message) {
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Puts [text] on the clipboard and always tells the person the result.
/// Returns true when the copy worked.
Future<bool> copyWithFeedback(
  BuildContext context,
  String text, {
  String message = kCopiedMessage,
}) async {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } catch (_) {
    _say(messenger, kCopyBlockedMessage);
    return false;
  }
  _say(messenger, message);
  return true;
}

/// Shown on the preview, so the person knows what is and is not sent.
const String kSharePreviewNote =
    'This is exactly what will be sent. Nothing is posted for you, and none '
    'of your notes, prayer log or reading history is included. We receive '
    'nothing about who you send it to.';

/// Shows the share for [doc] exactly as it will be sent, with Share and Copy
/// buttons. Nothing leaves the app until the person taps one of them.
Future<void> showSharePreview(
  BuildContext context, {
  required ShareDoc doc,
  String subject = 'this',
}) {
  return showNamedSheet<void>(
    label: 'Share preview',
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.navy,
    builder: (BuildContext sheet) =>
        SharePreviewSheet(doc: doc, subject: subject),
  );
}

class SharePreviewSheet extends ConsumerWidget {
  const SharePreviewSheet({super.key, required this.doc, this.subject = 'this'});

  final ShareDoc doc;
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool elder = ref.watch(elderModeProvider);
    final double minTap = elder ? 64 : 48;
    final String text = ShareService.build(doc, lang: uiLang(context));
    final bool sheet = ShareService.hasShareSheet;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('PREVIEW', style: AppText.eyebrow),
              const NativeReviewNote(),
              const SizedBox(height: 8),
              Container(
                key: const Key('share-preview-card'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                  color: AppColors.night,
                ),
                child: SelectableText(
                  text,
                  key: const Key('share-preview-text'),
                  style: AppText.body.copyWith(
                    fontSize: elder ? 20 : 15,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                kSharePreviewNote,
                key: const Key('share-preview-note'),
                style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: minTap),
                child: FilledButton.icon(
                  key: const Key('share-preview-share'),
                  onPressed: () async {
                    // Start the share first (the browser wants it straight
                    // from the tap), then close the preview.
                    final NavigatorState nav = Navigator.of(context);
                    final Future<void> done = ShareService.send(context, doc);
                    nav.pop();
                    await done;
                  },
                  icon: Icon(sheet ? Icons.ios_share : Icons.copy),
                  label: Text(
                    sheet ? 'Share' : 'Copy to share',
                    style: TextStyle(fontSize: elder ? 20 : null),
                  ),
                ),
              ),
              if (sheet) ...<Widget>[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minTap),
                  child: OutlinedButton.icon(
                    key: const Key('share-preview-copy'),
                    onPressed: () async {
                      final NavigatorState nav = Navigator.of(context);
                      final Future<bool> done = copyWithFeedback(context, text);
                      nav.pop();
                      await done;
                    },
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(
                      'Copy',
                      style: TextStyle(fontSize: elder ? 20 : null),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: minTap),
                child: TextButton(
                  key: const Key('share-preview-cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Not now',
                    style: TextStyle(fontSize: elder ? 20 : null),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one share button. A 48dp (64dp in Elder Mode) icon button with a
/// tooltip that names what is shared; it opens the preview, and nothing is
/// sent until the person confirms there. It is not shown in child mode.
class ShareButton extends ConsumerWidget {
  const ShareButton({
    super.key,
    required this.doc,
    this.subject = 'this',
    this.color = AppColors.gold,
  });

  final ShareDoc doc;

  /// Short noun for the tooltip, for example "hadith" or "story".
  final String subject;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool elder = ref.watch(elderModeProvider);
    final double side = elder ? 64 : 48;
    return ValueListenableBuilder<bool>(
      valueListenable: kChildMode,
      builder: (BuildContext context, bool childMode, Widget? _) {
        if (childMode) return const SizedBox.shrink();
        return IconButton(
          key: const Key('share-card'),
          tooltip: 'Share $subject',
          constraints: BoxConstraints(minWidth: side, minHeight: side),
          icon: Icon(Icons.ios_share, color: color, size: elder ? 26 : 20),
          onPressed: () => unawaited(
            showSharePreview(context, doc: doc, subject: subject),
          ),
        );
      },
    );
  }
}
