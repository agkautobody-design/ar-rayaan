import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get webFileSaveSupported => true;

/// Hands [content] to the browser as a file called [filename] (it lands in
/// the person's Downloads folder). Returns false when the browser refused.
/// Must be called straight from a tap.
bool saveTextFile(
  String filename,
  String content, {
  String mime = 'text/html',
}) {
  try {
    final web.Blob blob = web.Blob(
      <JSString>[content.toJS].toJS,
      web.BlobPropertyBag(type: '$mime;charset=utf-8'),
    );
    final String url = web.URL.createObjectURL(blob);
    final web.HTMLAnchorElement a =
        web.document.createElement('a') as web.HTMLAnchorElement;
    a.href = url;
    a.download = filename;
    a.style.display = 'none';
    web.document.body?.append(a);
    a.click();
    a.remove();
    // Released later so the browser has started the save first.
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 10),
        () => web.URL.revokeObjectURL(url),
      ),
    );
    return true;
  } catch (_) {
    return false;
  }
}
