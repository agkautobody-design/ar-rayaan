/// Reloads the running app. Only the web build can do this from inside;
/// everywhere else it is a no-op (the caller hides the button there).
export 'restart_app_stub.dart'
    if (dart.library.js_interop) 'restart_app_web.dart';
