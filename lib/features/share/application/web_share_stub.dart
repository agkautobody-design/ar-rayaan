/// The browser share sheet is only available in the web build.
bool get webShareSupported => false;

Future<bool> webShare(String text, {String? title}) async => false;
