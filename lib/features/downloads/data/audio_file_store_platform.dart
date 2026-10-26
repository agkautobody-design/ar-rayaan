/// The store for the running platform: files on the phone, Cache Storage in
/// the browser.
export 'audio_file_store_io.dart'
    if (dart.library.js_interop) 'audio_file_store_web.dart'
    show createPlatformAudioStore, platformCanDetectWifi, platformOnWifi;
