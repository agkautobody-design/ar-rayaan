/// The in-app YouTube / Spotify player surface.
///
/// On the web it is an iframe whose address is always built from a parsed
/// [StreamLink] (fixed hosts, validated IDs). Elsewhere it is not available
/// and callers open the service's own app instead.
library;

export 'stream_embed_stub.dart'
    if (dart.library.js_interop) 'stream_embed_web.dart';
