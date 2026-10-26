import 'package:ar_rayaan/app/core/asset_text_cache.dart';
import 'package:ar_rayaan/app/core/content_loader.dart';
import 'package:ar_rayaan/app/core/online_status.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/downloads/application/audio_store_provider.dart';
import 'package:ar_rayaan/features/downloads/application/download_manager.dart';
import 'package:ar_rayaan/features/downloads/data/audio_file_store.dart';
import 'package:ar_rayaan/features/downloads/domain/download_catalog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeStore implements AudioFileStore {
  final Set<String> files = <String>{};
  SaveOutcome outcome = SaveOutcome.stored;
  bool ok = true;

  @override
  bool get supported => ok;

  @override
  Future<Set<String>> storedFiles(ReciterPack pack) async =>
      Set<String>.of(files);

  @override
  Future<SaveOutcome> save(ReciterPack pack, AyahRef ref) async {
    await Future<void>.delayed(Duration.zero);
    if (outcome == SaveOutcome.stored) files.add(ref.fileName);
    return outcome;
  }

  @override
  Future<void> remove(ReciterPack pack, Iterable<AyahRef> refs) async {
    for (final AyahRef r in refs) {
      files.remove(r.fileName);
    }
  }

  @override
  Future<String?> playable(ReciterPack pack, AyahRef ref) async =>
      files.contains(ref.fileName) ? ref.fileName : null;
}

class MemCache implements AssetTextCache, RemovableAssetCache {
  final Map<String, String> m = <String, String>{};
  @override
  bool get persistent => true;
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String text) async => m[key] = text;
  @override
  Future<bool> has(String key) async => m.containsKey(key);
  @override
  Future<void> remove(String key) async => m.remove(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStore store;
  bool? wifi;
  ProviderContainer make({bool canWifi = false, bool bundled = true}) {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer c = ProviderContainer(
      overrides: [
        audioFileStoreProvider.overrideWithValue(store),
        downloadCanDetectWifiProvider.overrideWithValue(canWifi),
        downloadTextBundledProvider.overrideWithValue(bundled),
        downloadWifiProbeProvider.overrideWithValue(() async => wifi),
        downloadAssetListProvider.overrideWithValue(
          () async => <String>['assets/guides/guides.json'],
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle(ProviderContainer c) async {
    for (int i = 0; i < 4000; i++) {
      await Future<void>.delayed(Duration.zero);
      if (c.read(downloadsProvider).ready && !c.read(downloadsProvider).busy) {
        return;
      }
    }
  }

  setUp(() {
    store = FakeStore();
    wifi = true;
  });

  final AudioPack fatiha = AudioCatalog.of(ReciterPack.alHusary).surahs[0];
  final String fid = fatiha.id;

  test('scan reads what is really stored: partial, then downloaded', () async {
    store.files.addAll(<String>['001001.mp3', '001002.mp3']);
    final ProviderContainer c = make();
    c.read(downloadsProvider);
    await settle(c);
    expect(c.read(downloadsProvider).audioPhase(fatiha), PackPhase.partial);
    store.files.addAll(fatiha.refs.map((AyahRef r) => r.fileName));
    await c.read(downloadsProvider.notifier).refresh();
    expect(c.read(downloadsProvider).audioPhase(fatiha), PackPhase.downloaded);
  });

  test('download stores every ayah, then delete removes them', () async {
    final ProviderContainer c = make();
    c.read(downloadsProvider);
    await settle(c);
    c.read(downloadsProvider.notifier).download(fid);
    await settle(c);
    expect(c.read(downloadsProvider).audioPhase(fatiha), PackPhase.downloaded);
    expect(store.files.length, 7);
    await c.read(downloadsProvider.notifier).delete(fid);
    expect(store.files, isEmpty);
    expect(
      c.read(downloadsProvider).audioPhase(fatiha),
      PackPhase.notDownloaded,
    );
  });

  test('pause stops, resume finishes', () async {
    final ProviderContainer c = make();
    c.read(downloadsProvider);
    await settle(c);
    final DownloadsController n = c.read(downloadsProvider.notifier);
    n.download(AudioCatalog.of(ReciterPack.alHusary).surahs[1].id);
    n.pause();
    for (int i = 0; i < 50; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(store.files.length, lessThan(286));
    expect(c.read(downloadsProvider).paused, isTrue);
    final int atPause = store.files.length;
    for (int i = 0; i < 50; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(store.files.length, atPause);
    n.resume();
    await settle(c);
    expect(store.files.length, 286);
  });

  test('repeated failures stop the pack and say so', () async {
    store.outcome = SaveOutcome.failed;
    final ProviderContainer c = make();
    c.read(downloadsProvider);
    await settle(c);
    c.read(downloadsProvider.notifier).download(fid);
    await settle(c);
    final DownloadsState s = c.read(downloadsProvider);
    expect(s.audioPhase(fatiha), PackPhase.failed);
    expect(s.failed[fid], contains('in a row'));
    // Retry works once the connection is back.
    store.outcome = SaveOutcome.stored;
    c.read(downloadsProvider.notifier).download(fid);
    await settle(c);
    expect(c.read(downloadsProvider).audioPhase(fatiha), PackPhase.downloaded);
  });

  test('a full device halts with a clear message', () async {
    store.outcome = SaveOutcome.storageFull;
    final ProviderContainer c = make();
    c.read(downloadsProvider);
    await settle(c);
    c.read(downloadsProvider.notifier).download(fid);
    for (int i = 0; i < 100; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final DownloadsState s = c.read(downloadsProvider);
    expect(s.failed[fid], contains('out of space'));
    expect(s.banner, contains('no space'));
  });

  test('Wi-Fi only waits for Wi-Fi, then carries on', () async {
    wifi = false;
    final ProviderContainer c = make(canWifi: true);
    c.read(downloadsProvider);
    await settle(c);
    c.read(downloadsProvider.notifier).download(fid);
    for (int i = 0; i < 50; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(store.files, isEmpty);
    expect(c.read(downloadsProvider).banner, contains('Waiting for Wi-Fi'));
    wifi = true;
    c.read(downloadsProvider.notifier).resume();
    await settle(c);
    expect(store.files.length, 7);
    // Turning the switch off lets mobile data through.
    await c.read(downloadsProvider.notifier).setWifiOnly(false);
    expect(c.read(downloadsProvider).wifiOnly, isFalse);
  });

  test('offline is reported, not silently retried', () async {
    final bool? Function() before = deviceOnlineProbe;
    deviceOnlineProbe = () => false;
    addTearDown(() => deviceOnlineProbe = before);
    final ProviderContainer c = make();
    c.read(downloadsProvider);
    await settle(c);
    c.read(downloadsProvider.notifier).download(fid);
    for (int i = 0; i < 50; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(store.files, isEmpty);
    expect(c.read(downloadsProvider).banner, contains('offline'));
  });

  test('a browser that cannot keep files says so', () async {
    store.ok = false;
    final ProviderContainer c = make();
    c.read(downloadsProvider);
    await settle(c);
    c.read(downloadsProvider.notifier).download(fid);
    await settle(c);
    expect(c.read(downloadsProvider).failed[fid], contains('cannot keep'));
  });

  test('download everything fetches only what is missing', () async {
    for (final AyahRef r in allRefs().skip(3)) {
      store.files.add(r.fileName);
    }
    final ProviderContainer c = make();
    c.read(downloadsProvider);
    await settle(c);
    final DownloadsController n = c.read(downloadsProvider.notifier);
    expect(n.everythingEstimate(), greaterThan(0));
    expect(n.everythingEstimate(), lessThan(100000));
    n.downloadEverything();
    await settle(c);
    expect(store.files.length, 6236);
    expect(n.everythingEstimate(), 0);
  });

  test('text pack: saved in the browser, then deleted', () async {
    final ContentLoader_ saved = ContentLoader_();
    final MemCache cache = MemCache();
    ContentLoader.cache = cache;
    addTearDown(() => ContentLoader.cache = saved.old);
    final ProviderContainer c = make(bundled: false);
    c.read(downloadsProvider);
    await settle(c);
    final TextPackSpec guides = textPackById('text-guides')!;
    expect(
      c.read(downloadsProvider).textPhase(guides, bundled: false),
      PackPhase.notDownloaded,
    );
    c.read(downloadsProvider.notifier).download('text-guides');
    await settle(c);
    expect(
      c.read(downloadsProvider).textPhase(guides, bundled: false),
      PackPhase.downloaded,
    );
    expect(cache.m.keys, contains('assets/guides/guides.json'));
    await c.read(downloadsProvider.notifier).delete('text-guides');
    expect(cache.m, isEmpty);
    expect(
      c.read(downloadsProvider).textPhase(guides, bundled: false),
      PackPhase.notDownloaded,
    );
  });

  test('on the phone, text is simply included', () async {
    final ProviderContainer c = make();
    c.read(downloadsProvider);
    await settle(c);
    expect(
      c.read(downloadsProvider).textPhase(kTextPackSpecs.first, bundled: true),
      PackPhase.included,
    );
  });
}

/// Remembers the loader's cache so a test can put it back.
class ContentLoader_ {
  final AssetTextCache old = ContentLoader.cache;
}
