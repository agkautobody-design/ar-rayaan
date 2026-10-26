/// Copy and share actions with visible feedback, used wherever the app lets
/// a person take content out of it (a hadith, a story, a lesson, an answer).
///
/// Every action says what happened: a "Copied" snackbar, the browser's share
/// sheet, or an honest message when the browser blocks the clipboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../elder/application/elder_mode.dart';
import '../application/web_share.dart';

/// Shown after a successful copy.
const String kCopiedMessage = 'Copied. Paste it into any message.';

/// Shown when the browser or device refused the clipboard.
const String kCopyBlockedMessage =
    'Could not copy automatically. Select the text and copy it by hand.';

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

/// Opens the browser's share sheet when there is one, otherwise copies.
/// The share call is started before any await so the browser still counts it
/// as coming from the tap.
Future<void> shareWithFeedback(
  BuildContext context,
  String text, {
  String? title,
}) async {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  if (webShareSupported) {
    final bool shown = await webShare(text, title: title);
    if (shown) return;
  }
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } catch (_) {
    _say(messenger, kCopyBlockedMessage);
    return;
  }
  _say(messenger, kCopiedMessage);
}

/// A Copy button, plus a Share button where the browser has a share sheet.
/// Both are 48dp and carry tooltips.
class ShareCopyButtons extends StatelessWidget {
  const ShareCopyButtons({
    super.key,
    required this.text,
    this.title,
    this.subject = 'this',
    this.color = AppColors.gold,
  });

  /// The full text to copy or share (build it with `composeShareText`).
  final String text;
  final String? title;

  /// Short noun for tooltips, for example "hadith" or "story".
  final String subject;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          key: const Key('share-copy'),
          tooltip: 'Copy $subject',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(Icons.copy_outlined, color: color, size: 20),
          onPressed: () => copyWithFeedback(context, text),
        ),
        if (webShareSupported)
          IconButton(
            key: const Key('share-share'),
            tooltip: 'Share $subject',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.share_outlined, color: color, size: 20),
            onPressed: () => showSharePreview(
              context,
              text: text,
              title: title,
              subject: subject,
            ),
          ),
      ],
    );
  }
}

/// Shown on the preview, so the person knows what is and is not sent.
const String kSharePreviewNote =
    'This is exactly what will be sent. Nothing is posted for you, and none '
    'of your notes, prayer log or reading history is included.';

/// Shows [text] exactly as it will be shared, with Copy and Share buttons.
/// Nothing leaves the app until the person taps one of them. Where the
/// browser has a share sheet, Share opens it; everywhere else the same
/// button copies the text and says so.
Future<void> showSharePreview(
  BuildContext context, {
  required String text,
  String? title,
  String subject = 'this',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.navy,
    builder: (BuildContext sheet) =>
        SharePreviewSheet(text: text, title: title, subject: subject),
  );
}

class SharePreviewSheet extends ConsumerWidget {
  const SharePreviewSheet({
    super.key,
    required this.text,
    this.title,
    this.subject = 'this',
  });

  final String text;
  final String? title;
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool elder = ref.watch(elderModeProvider);
    final double minTap = elder ? 64 : 48;
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
                    final Future<void> done = shareWithFeedback(
                      context,
                      text,
                      title: title,
                    );
                    nav.pop();
                    await done;
                  },
                  icon: Icon(
                    webShareSupported ? Icons.share_outlined : Icons.copy,
                  ),
                  label: Text(
                    webShareSupported ? 'Share' : 'Copy to share',
                    style: TextStyle(fontSize: elder ? 20 : null),
                  ),
                ),
              ),
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

/// A 48dp "Preview and share" icon button, shown on every platform: where
/// there is no share sheet, the preview's button copies instead.
class ShareCardButton extends StatelessWidget {
  const ShareCardButton({
    super.key,
    required this.text,
    this.title,
    this.subject = 'this',
    this.color = AppColors.gold,
  });

  final String text;
  final String? title;
  final String subject;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('share-card'),
      tooltip: 'Preview and share $subject',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Icon(Icons.ios_share, color: color, size: 20),
      onPressed: () => showSharePreview(
        context,
        text: text,
        title: title,
        subject: subject,
      ),
    );
  }
}
