import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../academy/data/recitation_audio_repository.dart';
import '../../academy/domain/recitation_audio.dart';
import 'audio_file_store.dart';

/// The Android / iPhone store: one file per ayah in
/// `<app support>/recitation/<reciter>/`, the same folder (and file names)
/// the Qur'an reader caches into while playing, so anything downloaded here
/// is what the reader plays.
class IoAudioFileStore implements AudioFileStore {
  IoAudioFileStore({
    http.Client? client,
    Future<Directory> Function(ReciterPack pack)? dirFor,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client,
       _dirFor = dirFor ?? _defaultDir;

  final http.Client? _client;
  final Future<Directory> Function(ReciterPack pack) _dirFor;
  final Duration timeout;

  http.Client get _c => _client ?? (_shared ??= http.Client());
  static http.Client? _shared;

  /// Matches `audioCacheDirProvider`: Al-Husary keeps its original folder.
  static Future<Directory> _defaultDir(ReciterPack pack) async {
    final Directory base = await getApplicationSupportDirectory();
    final String name = pack.id == ReciterPack.alHusary.id ? 'husary' : pack.id;
    final Directory dir = Directory('${base.path}/recitation/$name');
    await dir.create(recursive: true);
    return dir;
  }

  @override
  bool get supported => true;

  @override
  Future<Set<String>> storedFiles(ReciterPack pack) async {
    try {
      final Directory dir = await _dirFor(pack);
      final Set<String> out = <String>{};
      await for (final FileSystemEntity e in dir.list()) {
        if (e is! File) continue;
        final String name = e.uri.pathSegments.last;
        if (!name.endsWith('.mp3')) continue;
        // A half-written file is never counted.
        if (await e.length() == 0) continue;
        out.add(name);
      }
      return out;
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<SaveOutcome> save(ReciterPack pack, AyahRef ref) async {
    File? part;
    try {
      final Directory dir = await _dirFor(pack);
      final File target = File('${dir.path}/${ref.fileName}');
      if (await target.exists() && await target.length() > 0) {
        return SaveOutcome.stored;
      }
      final http.Response res = await _c
          .get(Uri.parse(pack.ayahUrl(ref)))
          .timeout(timeout);
      final String type = res.headers['content-type'] ?? '';
      final bool looksLikeAudio =
          type.isEmpty || type.contains('audio') || type.contains('octet');
      if (res.statusCode != 200 ||
          !looksLikeAudio ||
          res.bodyBytes.isEmpty ||
          res.bodyBytes.length > RecitationAudioRepository.maxAyahBytes) {
        return SaveOutcome.failed;
      }
      // Write beside the target and rename, so a stopped app never leaves a
      // truncated file that would play as a cut-off ayah.
      part = File('${target.path}.part');
      await part.writeAsBytes(res.bodyBytes, flush: true);
      await part.rename(target.path);
      return SaveOutcome.stored;
    } on FileSystemException catch (e) {
      await _drop(part);
      // 28 is ENOSPC on Android, iOS and Linux: no space left on the device.
      return e.osError?.errorCode == 28
          ? SaveOutcome.storageFull
          : SaveOutcome.failed;
    } catch (_) {
      await _drop(part);
      return SaveOutcome.failed;
    }
  }

  Future<void> _drop(File? f) async {
    try {
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }

  @override
  Future<void> remove(ReciterPack pack, Iterable<AyahRef> refs) async {
    try {
      final Directory dir = await _dirFor(pack);
      for (final AyahRef r in refs) {
        final File f = File('${dir.path}/${r.fileName}');
        try {
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Future<String?> playable(ReciterPack pack, AyahRef ref) async {
    try {
      final Directory dir = await _dirFor(pack);
      final File f = File('${dir.path}/${ref.fileName}');
      return await f.exists() && await f.length() > 0 ? f.path : null;
    } catch (_) {
      return null;
    }
  }
}

AudioFileStore createPlatformAudioStore() => IoAudioFileStore();

/// Whether the phone is on Wi-Fi: true / false, or null when it cannot tell
/// (no connection at all). There is no connectivity plugin in this app, so
/// this reads the network interfaces: a connected Wi-Fi link is `wlan*` on
/// Android and `en0` on iPhone; anything else with an address is mobile data
/// or a cable. It is a best guess and the screen words it that way.
Future<bool?> platformOnWifi() async {
  try {
    final List<NetworkInterface> all = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
    );
    bool other = false;
    for (final NetworkInterface i in all) {
      if (i.addresses.isEmpty) continue;
      final String n = i.name.toLowerCase();
      if (n.startsWith('wlan') || n == 'en0') return true;
      other = true;
    }
    return other ? false : null;
  } catch (_) {
    return null;
  }
}

/// A browser cannot tell Wi-Fi from mobile data reliably.
const bool platformCanDetectWifi = true;
