import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/content/pack_shape.dart';
import 'package:flutter_test/flutter_test.dart';

String _pack(int n, {bool withTitle = true}) => json.encode(<dynamic>[
      for (var i = 0; i < n; i++)
        <String, dynamic>{
          'id': 'p$i',
          if (withTitle) 'title': 'Story $i',
          'chapters': <dynamic>[
            <String, dynamic>{'heading': 'h$i', 'body': 'b$i'},
          ],
        },
    ]);

void main() {
  group('PackShape', () {
    test('identical packs pass', () {
      expect(PackShape.problem(json.decode(_pack(3)), json.decode(_pack(5))),
          isNull);
    });

    test('an item that lost a key is refused', () {
      expect(
        PackShape.problem(
            json.decode(_pack(3)), json.decode(_pack(5, withTitle: false))),
        contains('missing "title"'),
      );
    });

    test('a key that changed type is refused', () {
      final shipped = json.decode(_pack(2));
      final drifted = json.decode(_pack(2)) as List<dynamic>;
      (drifted[1] as Map<String, dynamic>)['title'] = 42;
      expect(PackShape.problem(shipped, drifted), contains('changed type'));
    });

    test('a non-object item is refused', () {
      final shipped = json.decode(_pack(2));
      expect(PackShape.problem(shipped, <dynamic>['x', 'y']),
          contains('not an object'));
    });

    test('nested lists of objects are checked too', () {
      final shipped = json.decode(_pack(2));
      final drifted = json.decode(_pack(2)) as List<dynamic>;
      ((drifted[0] as Map<String, dynamic>)['chapters'] as List<dynamic>)
          .add(<String, dynamic>{'heading': 'no body'});
      expect(PackShape.problem(shipped, drifted), contains('missing "body"'));
    });

    test('a root object keeps every shipped section', () {
      final shipped = <String, dynamic>{
        'meta': <String, dynamic>{'a': 1},
        'nodes': <dynamic>[
          <String, dynamic>{'id': 'x'},
        ],
      };
      expect(PackShape.problem(shipped, <String, dynamic>{'meta': <String, dynamic>{}}),
          contains('missing section nodes'));
      expect(
          PackShape.problem(shipped, <String, dynamic>{
            'nodes': <dynamic>[
              <String, dynamic>{'id': 'y'},
            ],
          }),
          isNull);
    });

    test('optional keys and numbers of either kind are tolerated', () {
      final shipped = <dynamic>[
        <String, dynamic>{'id': 'a', 'n': 1, 'note': null},
        <String, dynamic>{'id': 'b', 'n': 2.5},
      ];
      final ok = <dynamic>[
        <String, dynamic>{'id': 'c', 'n': 3.5, 'extra': true},
      ];
      expect(PackShape.problem(shipped, ok), isNull);
    });

    test('every bundled versioned pack passes against itself', () {
      final v = json.decode(
              File('assets/content_version.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final String p in v.keys) {
        final doc = json.decode(File('assets/$p').readAsStringSync());
        expect(PackShape.problem(doc, doc), isNull, reason: p);
      }
    });
  });
}
