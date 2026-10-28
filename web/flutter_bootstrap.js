{{flutter_js}}
{{flutter_build_config}}

// Flutter's own service worker is deprecated and is only a stub that removes
// itself, so it is not registered. The app's offline shell is ar_sw.js,
// registered from index.html (network first; see the notes at its top).
_flutter.loader.load();
