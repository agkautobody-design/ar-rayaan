import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/quran/application/translation_providers.dart';
import 'package:ar_rayaan/features/quran/data/bundled_quran_repository.dart';
import 'package:ar_rayaan/features/quran/data/translation_pack_loader.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/domain/quran_texts.dart';
import 'package:ar_rayaan/features/quran/domain/translation_pack.dart';
import 'package:ar_rayaan/features/quran/presentation/ayah_actions_sheet.dart';
import 'package:ar_rayaan/features/quran/presentation/quran_translation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Translation packs: format, loader, fallback, credits and the guard that
/// nothing unlicensed is bundled. The fixture pack is synthetic ("Synthetic
/// test verse 1:1."): no real translation text is used in tests.
const String _fixturePath = 'test/data/translation/synthetic_pack.json';

class _FakeStore implements TranslationPackStore {
  final Map<String, String> files = <String, String>{};
  final Map<String, TranslationChoice> index = <String, TranslationChoice>{};

  @override
  Future<String?> read(String id) async => files[id];

  @override
  Future<void> write(TranslationPack pack, String raw) async {
    files[pack.id] = raw;
    index[pack.id] = TranslationChoice(
      id: pack.id,
      language: pack.language,
      title: pack.title,
      version: pack.version,
      bundled: false,
    );
  }

  @override
  Future<List<TranslationChoice>> installed() async =>
      index.values.toList();

  @override
  Future<void> remove(String id) async {
    files.remove(id);
    index.remove(id);
  }
}

Map<String, dynamic> _fixtureJson() =>
    jsonDecode(File(_fixturePath).readAsStringSync()) as Map<String, dynamic>;

String _withTexts(Map<String, dynamic> j, {bool fixSha = false}) {
  if (fixSha) {
    j['sha256'] = translationTextsSha256(<List<String>>[
      for (final dynamic r in j['surahs'] as List<dynamic>)
        (r as List<dynamic>).cast<String>(),
    ]);
  }
  return jsonEncode(j);
}

void _expectRejected(String raw, String text) {
  expect(
    () => TranslationPack.parse(raw),
    throwsA(
      isA<TranslationPackException>().having(
        (TranslationPackException e) => e.message,
        'message',
        contains(text),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final String fixtureRaw = File(_fixturePath).readAsStringSync();

  group('format', () {
    test('the synthetic fixture is a valid pack of 6,236 ayahs', () {
      final TranslationPack p = TranslationPack.parse(fixtureRaw);
      expect(p.id, 'xx.synthetic');
      expect(p.surahs, hasLength(114));
      expect(
        p.surahs.fold<int>(0, (int n, List<String> r) => n + r.length),
        kQuranAyahTotal,
      );
      expect(p.textOf(2, 255), 'Synthetic test verse 2:255.');
    });

    test('a changed verse fails the checksum', () {
      final Map<String, dynamic> j = _fixtureJson();
      ((j['surahs'] as List<dynamic>)[0] as List<dynamic>)[0] = 'Changed.';
      _expectRejected(_withTexts(j), 'checksum');
    });

    test('empty, padded, missing and extra verses are rejected', () {
      Map<String, dynamic> j = _fixtureJson();
      ((j['surahs'] as List<dynamic>)[0] as List<dynamic>)[2] = '  ';
      _expectRejected(_withTexts(j, fixSha: true), '1:3 is empty');

      j = _fixtureJson();
      ((j['surahs'] as List<dynamic>)[0] as List<dynamic>)[2] = ' padded';
      _expectRejected(_withTexts(j, fixSha: true), 'spaces');

      j = _fixtureJson();
      ((j['surahs'] as List<dynamic>)[0] as List<dynamic>).removeLast();
      _expectRejected(_withTexts(j, fixSha: true), 'surah 1 has 6');

      j = _fixtureJson();
      (j['surahs'] as List<dynamic>).removeLast();
      _expectRejected(_withTexts(j, fixSha: true), '114');

      j = _fixtureJson();
      ((j['surahs'] as List<dynamic>)[0] as List<dynamic>)[0] = 'a\nb';
      _expectRejected(_withTexts(j, fixSha: true), 'line break');
    });

    test('bad schema, id, licence and url are rejected', () {
      Map<String, dynamic> j = _fixtureJson()..['schema'] = 2;
      _expectRejected(_withTexts(j), 'schema');
      j = _fixtureJson()..['id'] = 'Clear';
      _expectRejected(_withTexts(j), 'id');
      j = _fixtureJson()..['id'] = 'ur.other';
      _expectRejected(_withTexts(j), 'must start with');
      j = _fixtureJson()..['licenseId'] = 'pending';
      _expectRejected(_withTexts(j), 'placeholder');
      j = _fixtureJson()..['url'] = 'http://example.org';
      _expectRejected(_withTexts(j), 'https');
      _expectRejected('not json', 'JSON');
    });

    test('version order and licence placeholders', () {
      expect(compareVersions('1.2.10', '1.2.9'), 1);
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('0.9', '1.0'), -1);
      expect(isRealLicenceId('TBD'), isFalse);
      expect(isRealLicenceId(' '), isFalse);
      expect(isRealLicenceId('AFF-2026-001'), isTrue);
    });

    test('the Clear Quran is the default English translation id', () {
      expect(kDefaultTranslationByLanguage['en'], kClearQuranId);
      expect(kClearQuranId, 'en.clear-quran');
    });
  });

  group('loader', () {
    Map<String, String> assets({
      String status = 'granted',
      String? sha,
      String? raw,
    }) {
      final TranslationPack p = TranslationPack.parse(fixtureRaw);
      return <String, String>{
        kTranslationManifestAsset: jsonEncode(<String, dynamic>{
          'schema': 1,
          'packs': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': p.id,
              'language': p.language,
              'title': p.title,
              'file': 'xx.synthetic.json',
              'version': p.version,
              'sha256': sha ?? p.sha256,
              'licenseId': p.licenseId,
              'licenceStatus': status,
            },
          ],
        }),
        '${kTranslationPackDir}xx.synthetic.json': raw ?? fixtureRaw,
      };
    }

    TranslationPackLoader loaderFor(
      Map<String, String> files,
      TranslationPackStore store,
    ) => TranslationPackLoader(
      store: store,
      loadAsset: (String k) async {
        final String? v = files[k];
        if (v == null) throw StateError('no asset $k');
        return v;
      },
    );

    test('no manifest, nothing installed: no pack', () async {
      final TranslationPackLoader l = loaderFor(
        <String, String>{},
        _FakeStore(),
      );
      expect(await l.load(kClearQuranId), isNull);
      expect(await l.available(), isEmpty);
    });

    test('loads a bundled pack with a granted licence', () async {
      final TranslationPackLoader l = loaderFor(assets(), _FakeStore());
      expect((await l.load('xx.synthetic'))?.title, 'Synthetic Test Pack');
      expect((await l.available()).single.bundled, isTrue);
    });

    test('a bundled pack without granted licence is ignored', () async {
      final TranslationPackLoader l = loaderFor(
        assets(status: 'pending'),
        _FakeStore(),
      );
      expect(await l.load('xx.synthetic'), isNull);
      expect(await l.available(), isEmpty);
    });

    test('a manifest checksum that disagrees with the file is ignored', () async {
      final TranslationPackLoader l = loaderFor(
        assets(sha: 'ab' * 32),
        _FakeStore(),
      );
      expect(await l.load('xx.synthetic'), isNull);
    });

    test('a corrupt bundled file is ignored, never half-shown', () async {
      final TranslationPackLoader l = loaderFor(
        assets(raw: fixtureRaw.replaceFirst('Synthetic test verse 1:1.', 'X')),
        _FakeStore(),
      );
      expect(await l.load('xx.synthetic'), isNull);
    });

    test('install validates, stores and is then loadable', () async {
      final _FakeStore store = _FakeStore();
      final TranslationPackLoader l = loaderFor(<String, String>{}, store);
      await l.install(fixtureRaw);
      expect((await l.load('xx.synthetic'))?.id, 'xx.synthetic');
      expect((await l.available()).single.bundled, isFalse);
    });

    test('install refuses a bad pack and stores nothing', () async {
      final _FakeStore store = _FakeStore();
      final TranslationPackLoader l = loaderFor(<String, String>{}, store);
      await expectLater(
        l.install(fixtureRaw.replaceFirst('Synthetic test verse 1:1.', 'X')),
        throwsA(isA<TranslationPackException>()),
      );
      expect(store.files, isEmpty);
    });

    test('the newer downloaded version wins; a tie goes to the bundled', () async {
      final _FakeStore store = _FakeStore();
      final Map<String, dynamic> j = _fixtureJson()..['version'] = '1.1.0';
      await store.write(
        TranslationPack.parse(_withTexts(j)),
        _withTexts(j),
      );
      TranslationPackLoader l = loaderFor(assets(), store);
      expect((await l.load('xx.synthetic'))?.version, '1.1.0');
      j['version'] = '1.0.0';
      store.files['xx.synthetic'] = _withTexts(j);
      l = loaderFor(assets(), store);
      expect((await l.load('xx.synthetic'))?.version, '1.0.0');
    });
  });

  group('bundled packs (what actually ships)', () {
    test('every bundled pack is licensed, present, valid and matches', () {
      final Map<String, dynamic> m =
          jsonDecode(
                File('assets/quran/translations/manifest.json')
                    .readAsStringSync(),
              )
              as Map<String, dynamic>;
      final TranslationManifest man = TranslationManifest.parse(
        jsonEncode(m),
      );
      for (final TranslationPackEntry e in man.packs) {
        expect(e.licenceStatus, 'granted', reason: e.id);
        expect(isRealLicenceId(e.licenseId), isTrue, reason: e.id);
        final File f = File('assets/quran/translations/${e.file}');
        expect(f.existsSync(), isTrue, reason: e.file);
        final TranslationPack p = TranslationPack.parse(f.readAsStringSync());
        expect(p.id, e.id);
        expect(p.sha256, e.sha256);
        expect(p.licenseId, e.licenseId);
        expect(p.attribution.trim(), isNotEmpty);
      }
      // No stray pack file without a manifest line (nothing slips in).
      final Set<String> listed = man.packs.map((e) => e.file).toSet();
      for (final FileSystemEntity f
          in Directory('assets/quran/translations').listSync()) {
        final String name = f.path.split('/').last;
        if (name == 'manifest.json') continue;
        expect(listed, contains(name), reason: '$name is not in the manifest');
      }
    });
  });

  group('reader text and credits', () {
    test('the repository shows the pack text in place of the interim English',
        () async {
      final TranslationPack p = TranslationPack.parse(fixtureRaw);
      final BundledQuranRepository withPack = BundledQuranRepository(
        translation: () async => p,
      );
      final Surah s = await withPack.surah(1);
      expect(s.ayahs.first.english, 'Synthetic test verse 1:1.');
      expect(s.ayahs.first.arabic, isNotEmpty);
      expect(s.ayahs, hasLength(7));

      final Surah interim = await BundledQuranRepository().surah(1);
      expect(
        interim.ayahs.first.english,
        'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
      );
      final BundledQuranRepository broken = BundledQuranRepository(
        translation: () async => throw StateError('x'),
      );
      expect((await broken.surah(1)).ayahs.first.english, contains('Allah'));
    });

    test('missing Clear Quran pack: interim, labelled, calm note', () {
      final QuranTexts t = QuranTexts.fallback.forActive(
        const ActiveTranslation(wantedId: kClearQuranId, pack: null),
      );
      expect(t.translation.note, contains('The Clear Quran'));
      expect(t.translation.note, contains('being added'));
      expect(t.footerLine, contains('interim'));
      expect(t.shareCreditLine, contains('interim'));
    });

    test('a present pack supplies its own attribution everywhere', () {
      final TranslationPack p = TranslationPack.parse(fixtureRaw);
      final QuranTexts t = QuranTexts.fallback.forActive(
        ActiveTranslation(wantedId: p.id, pack: p),
      );
      expect(t.footerLine, contains('Synthetic Test Pack, test fixture only.'));
      expect(t.footerLine, isNot(contains('Saheeh')));
      expect(t.translation.note, contains('TEST-ONLY-0001'));
      expect(t.translation.url, 'https://example.org/test');
      expect(t.shareCreditLine, contains('test fixture only.'));
      expect(t.shareCreditLine, isNot(contains('only..')));
    });

    test('copied ayah text carries the credit it is given', () {
      const Ayah a = Ayah(number: 1, arabic: 'ar', english: 'en');
      expect(ayahShareText('Al-Fatihah', 1, a), contains('Saheeh'));
      expect(
        ayahShareText('Al-Fatihah', 1, a, credit: 'Credit line.'),
        endsWith('Credit line. Shared from Ar-Rayaan.'),
      );
    });
  });

  group('Settings > Qur’an translation', () {
    testWidgets('says the Clear Quran is being added and offers the choices',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(body: SingleChildScrollView(
              child: QuranTranslationCard(),
            )),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('being added'), findsWidgets);
      expect(find.textContaining('The Clear Quran'), findsWidgets);
      expect(find.text('Saheeh International (interim)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('translation-interim')));
      await tester.pump();
      expect(c.read(translationSelectionProvider), kInterimEnglishId);
      await tester.tap(find.byKey(const Key('translation-default')));
      await tester.pump();
      expect(c.read(translationSelectionProvider), isNull);
    });
  });
}
