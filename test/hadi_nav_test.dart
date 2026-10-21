import 'dart:io';

import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final String router = File('lib/app/router.dart').readAsStringSync();
  final Set<String> routerPaths = <String>{
    for (final RegExpMatch m
        in RegExp(r"'(/[a-z0-9\-/:_]*)'").allMatches(router))
      m.group(1)!,
  };

  group('[GO:] whitelist', () {
    test('every whitelisted path is a real route in router.dart', () {
      final List<String> missing = <String>[
        for (final String p in kHadiNavWhitelist)
          if (!routerPaths.contains(p)) p,
      ];
      expect(missing, isEmpty,
          reason: 'Hadi would send people to routes that do not exist');
    });

    test('every path the prompt, samples and offline shelf use is allowed',
        () {
      final RegExp go = RegExp(r'\[GO:(/[a-z0-9\-/]+)\]');
      for (final String file in <String>[
        'lib/features/hadi/application/hadi_provider.dart',
        'lib/features/hadi/application/hadi_samples.dart',
        'lib/features/hadi/data/offline_hadi_provider.dart',
      ]) {
        for (final RegExpMatch m in go.allMatches(File(file).readAsStringSync())) {
          final String p = m.group(1)!;
          if (p == '/the/path') continue; // placeholder in the prompt
          expect(kHadiNavWhitelist.contains(p), isTrue, reason: '$file: $p');
        }
      }
    });

    test('the routes the audit found missing are now allowed', () {
      for (final String p in <String>[
        '/search',
        '/profile',
        '/home/elder',
        '/games/trivia',
      ]) {
        expect(kHadiNavWhitelist.contains(p), isTrue, reason: p);
      }
    });
  });

  group('HadiTokens', () {
    test('routeOf takes only whitelisted routes', () {
      expect(HadiTokens.routeOf('Opening.\n[GO:/quran]'), '/quran');
      expect(HadiTokens.routeOf('x [GO:/not/a/route]'), isNull);
      expect(HadiTokens.routeOf('[GO:/evil] then [GO:/sakina]'), '/sakina');
      expect(HadiTokens.routeOf('no token here'), isNull);
    });

    test('routesOf keeps order, drops repeats and strangers, and caps at two',
        () {
      expect(
        HadiTokens.routesOf('a [GO:/sakina] b [GO:/sakina] c [GO:/feelings]'),
        <String>['/sakina', '/feelings'],
      );
      expect(HadiTokens.routesOf('[GO:/evil] [GO:/quran]'), <String>['/quran']);
      expect(
        HadiTokens.routesOf('[GO:/quran][GO:/prayer][GO:/zakat]'),
        <String>['/quran', '/prayer'],
      );
      expect(HadiTokens.routesOf('nothing here'), isEmpty);
    });

    test('every named button route is on the whitelist', () {
      for (final String route in kHadiRouteNames.keys) {
        expect(kHadiNavWhitelist.contains(route), isTrue, reason: route);
      }
      expect(HadiTokens.labelFor('/prayer'), 'Open Prayer Times');
      expect(HadiTokens.labelFor('/somewhere-new'), 'Open this screen');
    });

    test('strip removes every GO and DO token', () {
      const String raw =
          'Here you go.\n[GO:/stories]\n[DO:save-hadith]\n[DO:bookmark:abc]';
      final String clean = HadiTokens.strip(raw);
      expect(clean, 'Here you go.');
      expect(clean.contains('[GO:'), isFalse);
      expect(clean.contains('[DO:'), isFalse);
    });

    test('strip also removes malformed tokens', () {
      expect(HadiTokens.strip('ok [GO:] [DO:] done'), 'ok done');
    });
  });
}
