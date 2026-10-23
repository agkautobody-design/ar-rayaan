/// Copy and share actions with visible feedback, used wherever the app lets
/// a person take content out of it (a hadith, a story, a lesson, an answer).
///
/// Every action says what happened: a "Copied" snackbar, the browser's share
/// sheet, or an honest message when the browser blocks the clipboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../../app/theme/app_colors.dart';
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
            onPressed: () => shareWithFeedback(context, text, title: title),
          ),
      ],
    );
  }
}
