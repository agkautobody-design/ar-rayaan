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
