/// Saving a file from the page is only available in the web build; the phone
/// apps have no folder the person can reach without a share sheet.
bool get webFileSaveSupported => false;

bool saveTextFile(
  String filename,
  String content, {
  String mime = 'text/html',
}) => false;
