import 'package:ar_rayaan/app/core/content_loader.dart';
import 'package:ar_rayaan/features/downloads/application/audio_store_provider.dart';
import 'package:ar_rayaan/features/downloads/application/download_manager.dart';
import 'package:ar_rayaan/features/downloads/presentation/downloads_screen.dart';
import 'package:ar_rayaan/features/downloads/presentation/pack_save_row.dart';
import 'package:ar_rayaan/features/downloads/presentation/surah_download_button.dart';
import 'package:ar_rayaan/features/share/presentation/handout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'downloads_manager_test.dart' show FakeStore, MemCache;

Future<void> pumpApp(
  WidgetTester t,
  Widget child,
  FakeStore store, {
  bool canWifi = false,
  bool bundled = true,
  double scale = 1,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final old = ContentLoader.cache;
  ContentLoader.cache = MemCache();
  addTearDown(() => ContentLoader.cache = old);
  t.view.physicalSize = const Size(400, 3000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        audioFileStoreProvider.overrideWithValue(store),
        downloadCanDetectWifiProvider.overrideWithValue(canWifi),
        downloadTextBundledProvider.overrideWithValue(bundled),
        downloadWifiProbeProvider.overrideWithValue(() async => true),
        downloadAssetListProvider.overrideWithValue(
          () async => <String>['assets/guides/guides.json'],
        ),
      ],
      child: MaterialApp(
        builder: (BuildContext c, Widget? w) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: w!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('phone: honest note, controls, nasheed reason, no overflow', (
    t,
  ) async {
    await pumpApp(
      t,
      const DownloadsScreen(web: false),
      FakeStore(),
      canWifi: true,
      scale: 2,
    );
    expect(find.text('Download everything'), findsWidgets);
    expect(find.text('Wi-Fi only'), findsOneWidget);
    expect(find.textContaining('already inside this app'), findsOneWidget);
    expect(find.byKey(const Key('downloads-nasheed-note')), findsOneWidget);
    expect(find.textContaining('Inside the app'), findsWidgets);
    expect(find.byKey(const Key('downloads-estimate')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('web: says a browser cannot tell Wi-Fi apart', (t) async {
    await pumpApp(
      t,
      const DownloadsScreen(web: true),
      FakeStore(),
      bundled: false,
    );
    expect(find.textContaining('cannot tell Wi-Fi'), findsOneWidget);
    expect(find.textContaining('still needs internet to open'), findsOneWidget);
    expect(find.text('Save for offline'), findsWidgets);
  });

  testWidgets('a surah downloads from its row and shows as on this device', (
    t,
  ) async {
    final FakeStore store = FakeStore();
    await pumpApp(t, const DownloadsScreen(web: false), store);
    await t.tap(find.text('By surah'));
    await t.pumpAndSettle();
    final Finder btn = find.byKey(
      const Key('pack-audio:husary-mp3quran:surah:1-download'),
    );
    await t.ensureVisible(btn);
    await t.tap(btn);
    for (int i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 20));
    }
    expect(store.files.length, 7);
    expect(
      find.byKey(const Key('pack-audio:husary-mp3quran:surah:1-delete')),
      findsOneWidget,
    );
  });

  testWidgets('reader button downloads this surah and then says so', (t) async {
    final FakeStore store = FakeStore();
    await pumpApp(t, const SurahDownloadButton(surah: 1), store);
    expect(find.text('Download recitation'), findsOneWidget);
    await t.tap(find.byKey(const Key('reader-download')));
    for (int i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Recitation downloaded'), findsOneWidget);
  });

  testWidgets('save row is silent on the phone, offers a save in the browser', (
    t,
  ) async {
    await pumpApp(
      t,
      const PackSaveRow(packIds: <String>['text-guides']),
      FakeStore(),
    );
    expect(find.byKey(const Key('pack-save-row-save')), findsNothing);
    await pumpApp(
      t,
      const PackSaveRow(packIds: <String>['text-guides']),
      FakeStore(),
      bundled: false,
    );
    await t.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('pack-save-row-save')), findsOneWidget);
    expect(find.textContaining('Not saved yet'), findsOneWidget);
  });

  test('handout file names are safe', () {
    expect(handoutFileName('The Cave: a night!'), 'the-cave-a-night.html');
    expect(handoutFileName('???'), 'handout.html');
  });
}
