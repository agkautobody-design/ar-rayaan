/// Pure text builders for sharing and copying content that already exists
/// in the app. Nothing here writes new content: it only joins the text, the
/// source line and the app credit.
library;

/// Credit line appended to everything copied or shared out of the app.
const String kSharedFromLine = 'Shared from Ar-Rayaan';

/// Joins the non-empty parts with a blank line: title, Arabic, [body], the
/// source line (`— source`) and the credit line.
String composeShareText({
  String? title,
  String? arabic,
  required String body,
  String? source,
}) {
  final List<String> blocks = <String>[
    if (title != null && title.trim().isNotEmpty) title.trim(),
    if (arabic != null && arabic.trim().isNotEmpty) arabic.trim(),
    if (body.trim().isNotEmpty) body.trim(),
    if (source != null && source.trim().isNotEmpty) '— ${source.trim()}',
    kSharedFromLine,
  ];
  return blocks.join('\n\n');
}

/// The public address of the app, for invitations. Fixed on purpose: a
/// shared link never carries anything about the person who sent it.
const String kInviteUrl = 'https://ar-rayaan.onrender.com';

/// The invitation text: what the app has, and the link. Nothing personal.
String inviteShareText() => composeShareText(
  body:
      'Ar-Rayaan: Qur’an, adhkar, prayer times and Islamic learning in one '
      'place. You are welcome to try it:\n$kInviteUrl',
);

/// A milestone line, "I completed ...", with the app credit and the link.
/// [what] is a short phrase such as `reading Surah Al-Fatihah`. It must be
/// built from what the person did, never from their notes or prayer log.
String milestoneShareText(String what) => composeShareText(
  body: 'I completed $what on Ar-Rayaan.\n$kInviteUrl',
);

/// A "came back" line for a streak that may be shared (never prayers).
String comeBackShareText(String what, int days) => composeShareText(
  body: 'I came back to $what for $days days on Ar-Rayaan.\n$kInviteUrl',
);
