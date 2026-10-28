import 'package:flutter/material.dart' hide Text;
import '../theme/widgets/tr_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown when a link could not be opened.
const String kLinkNotOpenedMessage =
    'Could not open that link. Check your connection, or allow pop-ups for '
    'this site, then try again.';

/// Opens [uri] outside the app and ALWAYS says so when it could not be
/// opened (no browser, no connection, pop-up blocked, an unsupported
/// scheme). A tap on a link must never end in silence. Returns true when the
/// system accepted the link.
///
/// The messenger is taken before the first await, so a screen that closes
/// while the browser opens does not throw.
Future<bool> openLinkWithFeedback(
  BuildContext context,
  Uri? uri, {
  LaunchMode mode = LaunchMode.externalApplication,
  String message = kLinkNotOpenedMessage,
}) async {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  bool opened = false;
  if (uri != null) {
    try {
      opened = await launchUrl(uri, mode: mode);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened && messenger != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
  return opened;
}
