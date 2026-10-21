import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/family/data/family_tree_provider.dart';
import 'package:ar_rayaan/features/family/presentation/family_tree_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Messengers' Tree: honest labels, parentage that follows the Qur'an,
/// text-only nodes for prophets the sources do not place, and no images.
void main() {
  late Map<String, dynamic> raw;
  late List<Map<String, dynamic>> nodes;
  late Map<String, Map<String, dynamic>> byId;

  setUpAll(() {
    raw = json.decode(File('assets/family/tree.json').readAsStringSync())
        as Map<String, dynamic>;
    nodes = (raw['nodes'] as List<dynamic>).cast<Map<String, dynamic>>();
    byId = <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> n in nodes) n['id'] as String: n,
    };
  });

  List<String> list(Map<String, dynamic> n, String key) =>
      (n[key] as List<dynamic>? ?? <dynamic>[]).cast<String>();

  FamilyTreeData data() => FamilyTreeData(
        title: (raw['meta'] as Map<String, dynamic>)['title'] as String,
        note: (raw['meta'] as Map<String, dynamic>)['note'] as String,
        sources:
            ((raw['meta'] as Map<String, dynamic>)['sources'] as List<dynamic>)
                .cast<String>(),
        lineageWarning:
            (raw['meta'] as Map<String, dynamic>)['lineageWarning'] as String?,
        unplacedNote:
            (raw['meta'] as Map<String, dynamic>)['unplacedNote'] as String?,
        nodes: <FamilyNode>[
          for (final Map<String, dynamic> n in nodes) FamilyNode.fromJson(n),
        ],
      );

  test('labels are one of the three classes', () {
    const Set<String> ok = <String>{
      'Established', 'Interpretive', 'Disputed in the sources',
    };
    for (final Map<String, dynamic> n in nodes) {
      expect(ok.contains(n['sourceLabel']), isTrue,
          reason: '${n['id']}: bad label ${n['sourceLabel']}');
    }
  });

  test('every link resolves and parent/child links agree both ways', () {
    for (final Map<String, dynamic> n in nodes) {
      final String id = n['id'] as String;
      for (final String key in <String>['parents', 'children', 'spouses']) {
        for (final String ref in list(n, key)) {
          expect(byId.containsKey(ref), isTrue, reason: '$id.$key -> $ref');
        }
      }
      for (final String c in list(n, 'children')) {
        expect(list(byId[c]!, 'parents').contains(id), isTrue,
            reason: '$id lists child $c, but $c does not list $id as a parent');
      }
      for (final String p in list(n, 'parents')) {
        expect(list(byId[p]!, 'children').contains(id), isTrue,
            reason: '$id lists parent $p, but $p does not list $id as a child');
      }
      for (final String sp in list(n, 'spouses')) {
        expect(list(byId[sp]!, 'spouses').contains(id), isTrue,
            reason: '$id and $sp must list each other as spouses');
      }
      for (final dynamic r in (n['relations'] as List<dynamic>? ?? <dynamic>[])) {
        final Map<String, dynamic> rel = r as Map<String, dynamic>;
        expect(byId.containsKey(rel['id']), isTrue,
            reason: '$id relation -> ${rel['id']}');
        expect((rel['label'] as String).trim(), isNotEmpty);
      }
    }
  });

  test('the two sons of Adam and Binyamin are not called established', () {
    expect(byId['habil']!['sourceLabel'], 'Interpretive');
    expect(byId['qabil']!['sourceLabel'], 'Interpretive');
    expect(byId['binyamin']!['sourceLabel'], 'Interpretive');
    for (final String id in <String>['habil', 'qabil', 'binyamin']) {
      expect((byId[id]!['lineageNote'] as String).contains('tradition'), isTrue,
          reason: '$id must say its name is from tradition');
    }
  });

  test('Maryam is the daughter of Imran; Zakariya is her guardian, not parent',
      () {
    final Map<String, dynamic> maryam = byId['maryam']!;
    expect(list(maryam, 'parents'), contains('imran-maryam'));
    expect(list(maryam, 'parents'), isNot(contains('zakariya')));
    expect(list(maryam, 'parents'), isNot(contains('zakariya-line')));
    expect(list(byId['zakariya']!, 'children'), <String>['yahya']);
    expect(list(byId['zakariya-line']!, 'children'), isNot(contains('maryam')));
    final List<dynamic> rel = byId['zakariya']!['relations'] as List<dynamic>;
    expect(
      rel.any((dynamic r) =>
          (r as Map<String, dynamic>)['id'] == 'maryam' &&
          (r['label'] as String).contains('Guardian')),
      isTrue,
    );
    // Maryam's father is not Musa's father: two separate nodes.
    expect(byId['imran']!['id'] == byId['imran-maryam']!['id'], isFalse);
    expect(list(byId['imran-maryam']!, 'children'), <String>['maryam']);
    expect(list(maryam, 'children'), <String>['isa']);
    expect(byId['imran-maryam']!['sourceLabel'], 'Established');
    expect(byId['imran']!['sourceLabel'], 'Interpretive');
    // The wife of Imran is unnamed in the Qur'an and the node says so.
    expect(list(byId['imran-maryam']!, 'spouses'), <String>['imran-wife']);
    expect((byId['imran-wife']!['description'] as String)
        .contains('does not give her own name'), isTrue);
  });

  test('every person reachable from Adam by children and spouses, or unplaced',
      () {
    final Set<String> seen = <String>{};
    final List<String> stack = <String>['adam'];
    while (stack.isNotEmpty) {
      final String id = stack.removeLast();
      if (!seen.add(id)) continue;
      final Map<String, dynamic>? n = byId[id];
      if (n == null) continue;
      stack
        ..addAll(list(n, 'children'))
        ..addAll(list(n, 'spouses'));
    }
    final List<String> lost = <String>[
      for (final Map<String, dynamic> n in nodes)
        if (!seen.contains(n['id']) && n['placement'] != 'unplaced')
          n['id'] as String,
    ];
    expect(lost, isEmpty, reason: 'unreachable and not marked unplaced: $lost');
    expect(seen.contains('isa'), isTrue);
    expect(seen.contains('maryam'), isTrue);
  });

  test('prophets the Qur’an does not place are text-only nodes', () {
    const List<String> unplaced = <String>[
      'hud', 'salih', 'shuayb', 'lut', 'idris', 'ayyub', 'yunus', 'ilyas',
      'alyasa', 'dhul-kifl',
    ];
    for (final String id in unplaced) {
      final Map<String, dynamic>? n = byId[id];
      expect(n, isNotNull, reason: '$id missing');
      expect(n!['placement'], 'unplaced', reason: id);
      expect(list(n, 'parents'), isEmpty, reason: '$id must not be guessed a parent');
      expect(list(n, 'children'), isEmpty, reason: id);
      expect(list(n, 'spouses'), isEmpty, reason: id);
      expect((n['sources'] as List<dynamic>).isNotEmpty, isTrue, reason: id);
      expect(n.containsKey('image'), isFalse);
      expect(n['story'], 'prophet-$id', reason: '$id should link its story');
    }
  });

  test('uncertain lineage is stated in the meta', () {
    final Map<String, dynamic> meta = raw['meta'] as Map<String, dynamic>;
    expect((meta['lineageWarning'] as String).contains('Adnan'), isTrue);
    expect((meta['unplacedNote'] as String).isNotEmpty, isTrue);
    final String note = meta['note'] as String;
    expect(note.contains('Disputed in the sources'), isTrue);
  });

  test('the Prophet’s household is in the tree, each part with its source', () {
    final Map<String, dynamic> m = byId['muhammad']!;
    expect(list(m, 'parents'), <String>['abdullah', 'amina']);
    expect(list(m, 'spouses'), containsAll(<String>['khadijah', 'prophet-wives']));
    expect(list(m, 'children'),
        containsAll(<String>['fatima', 'prophet-daughters', 'ibrahim-son']));
    for (final String id in <String>[
      'abdullah', 'amina', 'prophet-wives', 'prophet-daughters', 'ibrahim-son',
    ]) {
      final Map<String, dynamic> n = byId[id]!;
      expect((n['sources'] as List<dynamic>).isNotEmpty, isTrue, reason: id);
      expect((n['lineageNote'] as String? ?? n['description'] as String)
          .trim()
          .isNotEmpty, isTrue, reason: id);
    }
    // Facts the Qur'an or a checked hadith gives are Established; names and
    // links that are only from the historians are not.
    expect(byId['abdullah']!['sourceLabel'], 'Established');
    expect(byId['prophet-wives']!['sourceLabel'], 'Established');
    expect(byId['prophet-daughters']!['sourceLabel'], 'Established');
    expect(byId['ibrahim-son']!['sourceLabel'], 'Established');
    expect(byId['amina']!['sourceLabel'], 'Interpretive');
    expect((byId['amina']!['lineageNote'] as String).contains('tradition'), isTrue);
    expect(
      (byId['prophet-daughters']!['description'] as String)
          .contains('have not been re-checked'),
      isTrue,
      reason: 'the daughters’ names are from the historians and must say so',
    );
    // The mother of Ibrahim ibn Muhammad is not named in the report, so the
    // tree does not guess one.
    expect(list(byId['ibrahim-son']!, 'parents'), <String>['muhammad']);
  });

  test('Ali’s father is Abu Talib, and the node says what is not verified', () {
    expect(list(byId['ali']!, 'parents'), <String>['abu-talib']);
    expect(list(byId['abu-talib']!, 'children'), <String>['ali']);
    expect(list(byId['abdul-muttalib']!, 'children'), contains('abu-talib'));
    expect(byId['abu-talib']!['sourceLabel'], 'Interpretive');
    expect((byId['ali']!['lineageNote'] as String).contains('re-checked'), isTrue);
    final List<dynamic> rel = byId['abu-talib']!['relations'] as List<dynamic>;
    expect(
      rel.any((dynamic r) =>
          (r as Map<String, dynamic>)['id'] == 'muhammad' &&
          (r['label'] as String).contains('Uncle')),
      isTrue,
    );
  });

  test('everything above Adnan is marked uncertain and never Established', () {
    for (final String id in <String>['qaydar', 'adnan']) {
      final Map<String, dynamic> n = byId[id]!;
      expect(n['sourceLabel'], 'Interpretive', reason: id);
      expect((n['lineageNote'] as String).contains('Uncertain'), isTrue,
          reason: '$id must say the line above Adnan is uncertain');
    }
    expect((raw['meta'] as Map<String, dynamic>)['lineageWarning'] as String,
        contains('above Adnan'));
  });

  test('Isa and Yahya are linked as maternal cousins', () {
    for (final List<String> pair in <List<String>>[
      <String>['isa', 'yahya'],
      <String>['yahya', 'isa'],
    ]) {
      final List<dynamic> rel = byId[pair[0]]!['relations'] as List<dynamic>;
      expect(
        rel.any((dynamic r) =>
            (r as Map<String, dynamic>)['id'] == pair[1] &&
            (r['label'] as String).contains('cousin')),
        isTrue,
        reason: '${pair[0]} -> ${pair[1]}',
      );
    }
    // The cousin tie never replaces the parentage the Qur'an gives.
    expect(list(byId['isa']!, 'parents'), <String>['maryam']);
    expect(list(byId['yahya']!, 'parents'), <String>['zakariya']);
  });

  testWidgets('the whole tree builds on a 320 px phone with every branch open',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 12000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final FamilyTreeData d = data();
    final Set<String> all = <String>{
      for (final FamilyNode n in d.nodes) n.id,
    };
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          familyTreeProvider.overrideWith((ref) async => d),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: FamilyTreeScreen(initiallyExpanded: all),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // A RenderFlex overflow or any build error would surface here.
    expect(tester.takeException(), isNull);
    expect(find.text('Abu Talib'), findsOneWidget);
    expect(find.text('Ali ibn Abi Talib'), findsOneWidget);
    expect(find.text('Ibrahim ibn Muhammad ﷺ'), findsOneWidget);
    expect(find.text('His other daughters'), findsOneWidget);
    expect(find.text('Spouse · Amina'), findsOneWidget);
    expect(find.text('Maryam bint Imran'), findsOneWidget);
    expect(find.text('Isa'), findsOneWidget);
  });

  test('no node carries an image or a portrait', () {
    for (final Map<String, dynamic> n in nodes) {
      for (final String k in n.keys) {
        expect(
          <String>['image', 'portrait', 'icon', 'picture', 'img'].contains(k),
          isFalse,
          reason: '${n['id']} has "$k": no prophet imagery, ever',
        );
      }
    }
    final List<String> files = <String>[
      for (final FileSystemEntity f in Directory('assets/family').listSync())
        f.uri.pathSegments.last,
    ];
    expect(files, <String>['tree.json']);
  });

  testWidgets('Maryam, her spouse-side chip and Isa render in the tree',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 20000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          familyTreeProvider.overrideWith((ref) async => data()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const FamilyTreeScreen(
            initiallyExpanded: <String>{
              'ishaq',
              'yaqub',
              'maryam-line',
              'imran-maryam',
              'maryam',
              'zakariya-line',
              'zakariya',
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Maryam bint Imran'), findsOneWidget);
    expect(find.text('Isa'), findsOneWidget);
    expect(find.text('Imran, father of Maryam'), findsOneWidget);
    expect(find.text('Spouse · The wife of Imran'), findsOneWidget);
    expect(find.text('Yahya'), findsOneWidget);
    // The text-only prophets are listed in their own section.
    await tester.scrollUntilVisible(find.text('Dhul-Kifl'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('PROPHETS THE SOURCES DO NOT PLACE IN THIS LINE'),
        findsOneWidget);
    expect(find.text('Dhul-Kifl'), findsOneWidget);
  });
}
