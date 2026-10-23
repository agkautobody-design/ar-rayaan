import 'package:web/web.dart' as web;

bool? platformReportsOnline() {
  try {
    return web.window.navigator.onLine;
  } catch (_) {
    return null;
  }
}
