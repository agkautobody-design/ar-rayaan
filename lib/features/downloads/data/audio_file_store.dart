/// Where downloaded recitation lives, behind one small interface.
///
/// The phone apps keep one `.mp3` per ayah in the app's own folder (the same
/// folder the reader already caches into, so a downloaded ayah simply plays
/// from disk). The browser keeps the same files in Cache Storage under a name
/// of its own. Tests use an in-memory fake.
library;

import '../../academy/domain/recitation_audio.dart';

/// How one ayah download ended.
enum SaveOutcome {
  /// Stored and read back.
  stored,

  /// Could not be fetched (no connection, server error, bad file).
  failed,

  /// The device has no room left.
  storageFull,
}

abstract class AudioFileStore {
  /// False when this browser or device cannot keep files at all (private
  /// window, plain http, blocked site data).
  bool get supported;

  /// File names (like `002255.mp3`) already stored for [pack].
  Future<Set<String>> storedFiles(ReciterPack pack);

  /// Fetches one ayah and keeps it. Never throws.
  Future<SaveOutcome> save(ReciterPack pack, AyahRef ref);

  /// Deletes the stored copies of [refs]. Missing ones are ignored.
  Future<void> remove(ReciterPack pack, Iterable<AyahRef> refs);

  /// What the player should open for a stored ayah (a file path on the phone,
  /// a temporary address in the browser), or null when it is not stored.
  Future<String?> playable(ReciterPack pack, AyahRef ref);
}
