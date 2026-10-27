/// The download manager: one queue for every pack on the Downloads screen.
///
/// Honest by construction:
///  * what is "stored" is always read back from the device (files on the
///    phone, Cache Storage in the browser), never remembered from a flag;
///  * a pack is "downloaded" only when every file in it is stored, "partial"
///    when some are;
///  * a failure stops the pack and says why; nothing retries silently
///    forever.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content_loader.dart';
import '../../../app/core/online_status.dart';
import '../../../app/core/providers.dart';
import '../../academy/application/recitation_player_provider.dart';
import '../../academy/domain/recitation_audio.dart';
import '../../quran/application/quran_offline.dart';
import '../data/audio_file_store.dart';
import '../data/audio_file_store_platform.dart';
import '../domain/download_catalog.dart';
import 'audio_store_provider.dart';

/// Where a pack stands, as the screen words it.
enum PackPhase {
  /// Nothing stored.
  notDownloaded,

  /// In the queue behind another pack.
  queued,

  /// Being downloaded right now.
  downloading,

  /// In the queue but stopped (paused, or waiting for Wi-Fi / a connection).
  paused,

  /// Some files stored, none running.
  partial,

  /// Stopped by an error; [DownloadsState.failed] says which.
  failed,

  /// Every file stored.
  downloaded,

  /// Text that is already inside the app (phone apps): nothing to download.
  included,
}

@immutable
class DownloadsState {
  const DownloadsState({
    required this.reciter,
    this.ready = false,
    this.stored = const <int>{},
    this.textStored = const <String>{},
    this.textProgress = const <String, double>{},
    this.queue = const <String>[],
    this.paused = false,
    this.wifiOnly = true,
    this.failed = const <String, String>{},
    this.banner,
  });

  final ReciterPack reciter;

  /// False until the first look at what is already on the device is done.
  final bool ready;

  /// Ayahs of [reciter] stored on the device, as `surah * 1000 + ayah`.
  final Set<int> stored;

  /// Ids of text packs whose files are all stored (browser only).
  final Set<String> textStored;

  /// How far a running text pack is, 0..1.
  final Map<String, double> textProgress;

  /// Pack ids waiting or running; the first one is the active one.
  final List<String> queue;
  final bool paused;
  final bool wifiOnly;

  /// Pack id -> why it stopped.
  final Map<String, String> failed;

  /// A line for the top of the screen (offline, waiting for Wi-Fi, ...).
  final String? banner;

  DownloadsState copyWith({
    ReciterPack? reciter,
    bool? ready,
    Set<int>? stored,
    Set<String>? textStored,
    Map<String, double>? textProgress,
    List<String>? queue,
    bool? paused,
    bool? wifiOnly,
    Map<String, String>? failed,
    String? banner,
    bool clearBanner = false,
  }) => DownloadsState(
    reciter: reciter ?? this.reciter,
    ready: ready ?? this.ready,
    stored: stored ?? this.stored,
    textStored: textStored ?? this.textStored,
    textProgress: textProgress ?? this.textProgress,
    queue: queue ?? this.queue,
    paused: paused ?? this.paused,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    failed: failed ?? this.failed,
    banner: clearBanner ? null : (banner ?? this.banner),
  );

  /// How many of [refs] are stored.
  int countStored(List<AyahRef> refs) {
    int n = 0;
    for (final AyahRef r in refs) {
      if (stored.contains(ayahKey(r))) n++;
    }
    return n;
  }

  bool get busy => queue.isNotEmpty && !paused;

  /// The phase of a recitation pack.
  PackPhase audioPhase(AudioPack p) {
    final int done = countStored(p.refs);
    if (done >= p.refs.length) return PackPhase.downloaded;
    final int at = queue.indexOf(p.id);
    if (at >= 0) {
      if (paused) return PackPhase.paused;
      return at == 0 ? PackPhase.downloading : PackPhase.queued;
    }
    if (failed.containsKey(p.id)) return PackPhase.failed;
    return done > 0 ? PackPhase.partial : PackPhase.notDownloaded;
  }

  /// The phase of a text pack. [bundled] is true on the phone apps.
  PackPhase textPhase(TextPackSpec s, {required bool bundled}) {
    if (bundled) return PackPhase.included;
    if (textStored.contains(s.id)) return PackPhase.downloaded;
    final int at = queue.indexOf(s.id);
    if (at >= 0) {
      if (paused) return PackPhase.paused;
      return at == 0 ? PackPhase.downloading : PackPhase.queued;
    }
    if (failed.containsKey(s.id)) return PackPhase.failed;
    return PackPhase.notDownloaded;
  }
}

/// Every asset path in the app, for expanding folder entries of text packs.
/// Tests override it.
final Provider<Future<List<String>> Function()> downloadAssetListProvider =
    Provider<Future<List<String>> Function()>(
      (Ref ref) =>
          () async =>
              (await AssetManifest.loadFromAssetBundle(rootBundle))
                  .listAssets(),
    );

/// Whether the device is on Wi-Fi (true/false) or unknown (null). Tests
/// override it.
final Provider<Future<bool?> Function()> downloadWifiProbeProvider =
    Provider<Future<bool?> Function()>((Ref ref) => platformOnWifi);

/// True where Wi-Fi can be told apart from mobile data (the phone apps).
final Provider<bool> downloadCanDetectWifiProvider = Provider<bool>(
  (Ref ref) => platformCanDetectWifi,
);

/// True on the phone apps, where the text libraries are inside the install.
/// Tests override it to exercise the browser path.
final Provider<bool> downloadTextBundledProvider = Provider<bool>(
  (Ref ref) => !ContentLoader.cache.persistent,
);

enum _End { finished, paused, halted, failed, cancelled }

class DownloadsController extends Notifier<DownloadsState> {
  static const String wifiKey = 'ar.downloads.wifiOnly';

  /// Files fetched at once. Kept low out of courtesy to the audio host.
  static const int parallel = 2;

  /// Stop a pack after this many files in a row fail.
  static const int maxConsecutiveFailures = 3;

  /// Bumped whenever the whole state is rebuilt (reciter change), so a
  /// running loop from before notices and stops.
  int _token = 0;
  bool _running = false;
  bool _again = false;
  Set<int> _stored = <int>{};

  @override
  DownloadsState build() {
    _token++;
    final int token = _token;
    final ReciterPack reciter = ref.watch(selectedReciterProvider);
    bool wifiOnly = true;
    try {
      wifiOnly = ref.read(sharedPreferencesProvider).getBool(wifiKey) ?? true;
    } catch (_) {}
    // Anything still running from before this build, or after the provider
    // is gone, sees a different token and stops touching state.
    ref.onDispose(() => _token++);
    _stored = <int>{};
    unawaited(_scan(reciter, token));
    return DownloadsState(reciter: reciter, wifiOnly: wifiOnly);
  }

  bool _stale(int token) => token != _token;

  AudioCatalog get _catalog => AudioCatalog.of(state.reciter);

  /// Looks at what is really on the device.
  Future<void> _scan(ReciterPack reciter, int token) async {
    final Set<int> audio = <int>{};
    try {
      final Set<String> files = await ref
          .read(audioFileStoreProvider)
          .storedFiles(reciter);
      for (final String f in files) {
        final AyahRef? r = refFromFileName(f);
        if (r != null) audio.add(ayahKey(r));
      }
    } catch (_) {}
    if (_stale(token)) return;
    final Set<String> text = <String>{};
    if (!ref.read(downloadTextBundledProvider)) {
      try {
        final List<String> assets = await ref.read(downloadAssetListProvider)();
        for (final TextPackSpec spec in kTextPackSpecs) {
          if (await _textStored(spec, assets)) text.add(spec.id);
        }
      } catch (_) {}
    }
    if (_stale(token)) return;
    _stored = audio;
    state = state.copyWith(
      ready: true,
      stored: Set<int>.of(audio),
      textStored: text,
    );
  }

  Future<bool> _textStored(TextPackSpec spec, List<String> assets) async {
    final List<String> keys = spec.resolve(assets);
    if (keys.isEmpty) return false;
    for (final String k in keys) {
      if (!await ContentLoader.isAvailableOffline(k)) return false;
    }
    return true;
  }

  /// Re-reads what is on the device (after the screen opens).
  Future<void> refresh() => _scan(state.reciter, _token);

  Future<void> setWifiOnly(bool value) async {
    state = state.copyWith(wifiOnly: value);
    try {
      await ref.read(sharedPreferencesProvider).setBool(wifiKey, value);
    } catch (_) {}
  }

  // ---- queue ------------------------------------------------------------

  /// Queues one pack (by id) and starts working.
  void download(String packId) {
    if (state.queue.contains(packId)) {
      resume();
      return;
    }
    if (!_isKnown(packId) || _isComplete(packId)) return;
    final Map<String, String> failed = Map<String, String>.of(state.failed)
      ..remove(packId);
    state = state.copyWith(
      queue: <String>[...state.queue, packId],
      failed: failed,
      paused: false,
      clearBanner: true,
    );
    _kick();
  }

  /// Queues every pack that is not complete: text first (browser only), then
  /// the whole Qur'an recitation of the chosen reciter.
  void downloadEverything() {
    final List<String> ids = <String>[
      if (!ref.read(downloadTextBundledProvider))
        for (final TextPackSpec s in kTextPackSpecs)
          if (!state.textStored.contains(s.id)) s.id,
      if (!_isComplete(_catalog.all.id)) _catalog.all.id,
    ];
    final List<String> queue = <String>[...state.queue];
    for (final String id in ids) {
      if (!queue.contains(id)) queue.add(id);
    }
    if (queue.isEmpty) return;
    state = state.copyWith(
      queue: queue,
      failed: <String, String>{},
      paused: false,
      clearBanner: true,
    );
    _kick();
  }

  /// Queues every text pack that is not saved yet (no audio): one tap for
  /// "read it all offline". Does nothing when the text is part of the app or
  /// all of it is already saved.
  void downloadAllText() {
    if (ref.read(downloadTextBundledProvider)) return;
    final List<String> queue = <String>[...state.queue];
    for (final TextPackSpec s in kTextPackSpecs) {
      if (!state.textStored.contains(s.id) && !queue.contains(s.id)) {
        queue.add(s.id);
      }
    }
    if (queue.length == state.queue.length) return;
    state = state.copyWith(
      queue: queue,
      failed: <String, String>{},
      paused: false,
      clearBanner: true,
    );
    _kick();
  }

  /// Size of the text packs not saved yet, in bytes (estimate).
  int allTextEstimate() {
    if (ref.read(downloadTextBundledProvider)) return 0;
    int total = 0;
    for (final TextPackSpec s in kTextPackSpecs) {
      if (!state.textStored.contains(s.id)) total += s.estimatedBytes;
    }
    return total;
  }

  /// What "Download everything" would still fetch, in bytes (estimate).
  int everythingEstimate() {
    int total = 0;
    if (!ref.read(downloadTextBundledProvider)) {
      for (final TextPackSpec s in kTextPackSpecs) {
        if (!state.textStored.contains(s.id)) total += s.estimatedBytes;
      }
    }
    final AudioPack all = _catalog.all;
    final int have = state.countStored(all.refs);
    if (have < all.refs.length) {
      total += estimateAudioBytes(state.reciter, all.refs.length - have);
    }
    return total;
  }

  /// The estimate for one audio pack's missing files.
  int remainingEstimate(AudioPack p) {
    final int missing = p.refs.length - state.countStored(p.refs);
    return estimateAudioBytes(state.reciter, missing < 0 ? 0 : missing);
  }

  void pause() {
    if (state.queue.isEmpty) return;
    state = state.copyWith(paused: true);
  }

  void resume() {
    if (state.queue.isEmpty) return;
    state = state.copyWith(paused: false, clearBanner: true);
    _kick();
  }

  /// Takes a pack out of the queue. Files already stored are kept.
  void cancel(String packId) {
    final List<String> queue = state.queue
        .where((String q) => q != packId)
        .toList();
    state = state.copyWith(
      queue: queue,
      paused: queue.isEmpty ? false : state.paused,
    );
  }

  /// Deletes the stored files of a pack.
  Future<void> delete(String packId) async {
    if (state.queue.contains(packId)) cancel(packId);
    final TextPackSpec? text = textPackById(packId);
    if (text != null) {
      try {
        final List<String> assets = await ref.read(downloadAssetListProvider)();
        for (final String k in text.resolve(assets)) {
          await ContentLoader.remove(k);
        }
      } catch (_) {}
      final Set<String> next = Set<String>.of(state.textStored)..remove(packId);
      state = state.copyWith(textStored: next);
      return;
    }
    final AudioPack? pack = _catalog.byId(packId);
    if (pack == null) return;
    await ref.read(audioFileStoreProvider).remove(state.reciter, pack.refs);
    for (final AyahRef r in pack.refs) {
      _stored.remove(ayahKey(r));
    }
    final Map<String, String> failed = Map<String, String>.of(state.failed)
      ..remove(packId);
    state = state.copyWith(stored: Set<int>.of(_stored), failed: failed);
  }

  bool _isKnown(String id) =>
      textPackById(id) != null || _catalog.byId(id) != null;

  bool _isComplete(String id) {
    final TextPackSpec? t = textPackById(id);
    if (t != null) {
      return ref.read(downloadTextBundledProvider) ||
          state.textStored.contains(id);
    }
    final AudioPack? a = _catalog.byId(id);
    return a != null && state.countStored(a.refs) >= a.refs.length;
  }

  // ---- worker -----------------------------------------------------------

  void _kick() {
    if (_running) {
      _again = true;
      return;
    }
    unawaited(_pump());
  }

  Future<void> _pump() async {
    _running = true;
    final int token = _token;
    try {
      while (!_stale(token) && state.queue.isNotEmpty && !state.paused) {
        final String id = state.queue.first;
        final _End end = await _runPack(id, token);
        if (_stale(token)) return;
        if (end == _End.paused || end == _End.halted) break;
        _dequeue(id);
      }
    } finally {
      _running = false;
      if (_again && !_stale(token)) {
        _again = false;
        unawaited(_pump());
      }
    }
  }

  void _dequeue(String id) {
    final List<String> queue = state.queue
        .where((String q) => q != id)
        .toList();
    state = state.copyWith(queue: queue);
  }

  void _fail(String packId, String message) {
    state = state.copyWith(
      failed: <String, String>{...state.failed, packId: message},
    );
  }

  /// Stops the whole queue and says why. The active pack stays first, so
  /// Resume carries on where it stopped.
  void _halt(String message) {
    state = state.copyWith(paused: true, banner: message);
  }

  /// A reason not to download right now, or null when it is fine.
  Future<String?> _gate() async {
    if (deviceReportsOnline == false) {
      return 'You are offline. Downloading continues when you tap Resume '
          'with a connection.';
    }
    if (state.wifiOnly && ref.read(downloadCanDetectWifiProvider)) {
      final bool? wifi = await ref.read(downloadWifiProbeProvider)();
      if (wifi == null) {
        return 'No connection found. Connect, then tap Resume.';
      }
      if (!wifi) {
        return 'Waiting for Wi-Fi. Turn off “Wi-Fi only” to use '
            'mobile data, or connect to Wi-Fi and tap Resume.';
      }
    }
    return null;
  }

  Future<_End> _runPack(String id, int token) async {
    final TextPackSpec? text = textPackById(id);
    if (text != null) return _runText(text, token);
    final AudioPack? pack = _catalog.byId(id);
    if (pack == null) return _End.cancelled;
    return _runAudio(pack, token);
  }

  Future<_End> _runText(TextPackSpec spec, int token) async {
    final String? blocked = await _gate();
    if (_stale(token)) return _End.cancelled;
    if (blocked != null) {
      _halt(blocked);
      return _End.halted;
    }
    List<String> keys;
    try {
      keys = spec.resolve(await ref.read(downloadAssetListProvider)());
    } catch (_) {
      keys = spec.resolve(const <String>[]);
    }
    if (_stale(token)) return _End.cancelled;
    state = state.copyWith(
      textProgress: <String, double>{...state.textProgress, spec.id: 0},
    );
    final QuranSaveResult result = await saveForOffline(
      keys,
      onProgress: (int done, int total) {
        if (_stale(token)) return;
        state = state.copyWith(
          textProgress: <String, double>{
            ...state.textProgress,
            spec.id: total == 0 ? 0 : done / total,
          },
        );
      },
    );
    if (_stale(token)) return _End.cancelled;
    final Map<String, double> progress = Map<String, double>.of(
      state.textProgress,
    )..remove(spec.id);
    state = state.copyWith(textProgress: progress);
    switch (result) {
      case QuranSaveResult.saved:
        state = state.copyWith(
          textStored: <String>{...state.textStored, spec.id},
        );
        return _End.finished;
      case QuranSaveResult.notKept:
        _fail(
          spec.id,
          'This browser loaded it but would not keep a copy (private '
          'windows and blocked site data do this).',
        );
        return _End.failed;
      case QuranSaveResult.failed:
        _fail(spec.id, 'Could not fetch it. Check your connection and retry.');
        return _End.failed;
    }
  }

  Future<_End> _runAudio(AudioPack pack, int token) async {
    final AudioFileStore store = ref.read(audioFileStoreProvider);
    if (!store.supported) {
      _fail(
        pack.id,
        'This browser cannot keep files (a private window, plain http or '
        'blocked site data). Recitation will keep streaming.',
      );
      return _End.failed;
    }
    final ReciterPack reciter = state.reciter;
    final List<AyahRef> pending = pack.refs
        .where((AyahRef r) => !_stored.contains(ayahKey(r)))
        .toList();
    int consecutive = 0;
    int sincePublish = 0;
    for (int i = 0; i < pending.length; i += parallel) {
      if (_stale(token)) return _End.cancelled;
      if (!state.queue.contains(pack.id)) {
        _publish();
        return _End.cancelled;
      }
      if (state.paused) {
        _publish();
        return _End.paused;
      }
      if (i % 40 == 0) {
        final String? blocked = await _gate();
        if (_stale(token)) return _End.cancelled;
        if (blocked != null) {
          _publish();
          _halt(blocked);
          return _End.halted;
        }
        if (state.paused) {
          _publish();
          return _End.paused;
        }
      }
      final int end = i + parallel < pending.length
          ? i + parallel
          : pending.length;
      final List<AyahRef> batch = pending.sublist(i, end);
      final List<SaveOutcome> outcomes = await Future.wait(
        batch.map((AyahRef r) => _saveWithRetry(store, reciter, r)),
      );
      if (_stale(token)) return _End.cancelled;
      bool full = false;
      for (int j = 0; j < batch.length; j++) {
        if (outcomes[j] == SaveOutcome.stored) {
          _stored.add(ayahKey(batch[j]));
          consecutive = 0;
        } else {
          consecutive++;
          if (outcomes[j] == SaveOutcome.storageFull) full = true;
        }
      }
      sincePublish += batch.length;
      if (sincePublish >= 8) {
        sincePublish = 0;
        _publish();
      }
      if (full) {
        _publish();
        _fail(
          pack.id,
          'This device is out of space. Free some room, then retry.',
        );
        _halt('Stopped: no space left on this device.');
        return _End.halted;
      }
      if (consecutive >= maxConsecutiveFailures) {
        _publish();
        _fail(
          pack.id,
          'Stopped after $consecutive files in a row could not be '
          'downloaded. Check your connection, then retry.',
        );
        return _End.failed;
      }
    }
    _publish();
    final bool complete = pack.refs.every(
      (AyahRef r) => _stored.contains(ayahKey(r)),
    );
    if (!complete) {
      _fail(
        pack.id,
        'Some files could not be downloaded. Retry to fetch the rest.',
      );
      return _End.failed;
    }
    return _End.finished;
  }

  Future<SaveOutcome> _saveWithRetry(
    AudioFileStore store,
    ReciterPack reciter,
    AyahRef ayah,
  ) async {
    SaveOutcome o = await store.save(reciter, ayah);
    if (o == SaveOutcome.failed) o = await store.save(reciter, ayah);
    return o;
  }

  void _publish() {
    state = state.copyWith(stored: Set<int>.of(_stored));
  }
}

final NotifierProvider<DownloadsController, DownloadsState> downloadsProvider =
    NotifierProvider<DownloadsController, DownloadsState>(
      DownloadsController.new,
    );
