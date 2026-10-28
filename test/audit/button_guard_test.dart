import 'dart:io';

import 'package:ar_rayaan/app/core/open_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// BUTTON AUDIT GUARD. Source-level checks that keep the controls honest:
/// no handler that is null or empty on a control a person can see, no
/// "Coming soon" stub, and no link or copy button that fails in silence.
/// (The runtime click-through is in test/audit/interaction_audit_test.dart.)
List<File> _dartFiles() => <File>[
      for (final FileSystemEntity f
          in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f,
    ];

/// The source with `//` comments removed (a `//` after a colon is a URL).
String _code(File f) =>
    f.readAsStringSync().replaceAll(RegExp(r'(?<!:)//[^\n]*'), '');

int _line(String src, int offset) =>
    '\n'.allMatches(src.substring(0, offset)).length + 1;

String _name(File f) => f.path.replaceAll('\\', '/');

void main() {
  test('no control has a null or empty handler', () {
    // `onPressed: null` is how a disabled control is written, but only inside
    // a condition (`cond ? handler : null`), which this pattern does not
    // match. A bare null or `() {}` is a button that looks live and is dead.
    final RegExp dead = RegExp(
      r'\bon(?:Pressed|Tap|LongPress|DoubleTap|Changed|Submitted|Selected)'
      r'\s*:\s*(?:null\s*[,)]|\(\s*\w*\s*\)\s*(?:async\s*)?\{\s*\}\s*[,)])',
    );
    final List<String> hits = <String>[];
    for (final File f in _dartFiles()) {
      final String src = _code(f);
      for (final RegExpMatch m in dead.allMatches(src)) {
        hits.add('${_name(f)}:${_line(src, m.start)}  ${m.group(0)}');
      }
    }
    expect(hits, isEmpty, reason: 'dead handlers:\n${hits.join('\n')}');
  });

  test('no "Coming soon" stub is shown to a person', () {
    // Allowed: the dormant "not built yet" row styling of the Menu and
    // Explore lists (no row uses it: every entry has a route, and the rows
    // read as disabled if one ever does), the Games community page (hidden
    // behind kGamesCommunityEnabled, redirected away while it is false) and
    // the Academy string table key that no screen reads.
    const Set<String> allowed = <String>{
      'lib/features/menu/presentation/menu_screen.dart',
      'lib/features/explore/presentation/explore_screen.dart',
      'lib/features/games/presentation/community_stub_screen.dart',
      'lib/features/academy/application/academy_strings.dart',
    };
    final RegExp soon = RegExp(
      r'''['"][^'"\n]*(?:coming soon|coming with)[^'"\n]*['"]''',
      caseSensitive: false,
    );
    final List<String> hits = <String>[];
    for (final File f in _dartFiles()) {
      if (allowed.contains(_name(f))) continue;
      final String src = _code(f);
      for (final RegExpMatch m in soon.allMatches(src)) {
        hits.add('${_name(f)}:${_line(src, m.start)}  ${m.group(0)}');
      }
    }
    expect(hits, isEmpty, reason: 'stub text:\n${hits.join('\n')}');
  });

  test('opening a link or copying text never fails in silence', () {
    // `launchUrl(...)` or `Clipboard.setData(...)` followed by an empty
    // catch is a button that does nothing and says nothing when it fails.
    final RegExp silent = RegExp(
      r'(?:launchUrl|Clipboard\.setData)\([^;]*;\s*\}\s*catch\s*\(\s*\w+\s*\)'
      r'\s*\{\s*\}',
    );
    final List<String> hits = <String>[];
    for (final File f in _dartFiles()) {
      final String src = _code(f);
      for (final RegExpMatch m in silent.allMatches(src)) {
        hits.add('${_name(f)}:${_line(src, m.start)}');
      }
    }
    expect(hits, isEmpty,
        reason: 'silent failures (use openLinkWithFeedback / '
            'copyWithFeedback):\n${hits.join('\n')}');
  });

  test('a raw launchUrl call is only made where the result is handled', () {
    // Everything else goes through openLinkWithFeedback, which tells the
    // person when the link could not be opened.
    const Set<String> handlesResult = <String>{
      'lib/app/core/open_link.dart',
      'lib/features/masjid/presentation/masjid_finder_screen.dart',
      'lib/features/sakina/presentation/widgets/help_line_tile.dart',
      'lib/features/academy/presentation/player_screen.dart',
      'lib/features/academy/presentation/stream_player_panel.dart',
    };
    final RegExp raw = RegExp(r'\blaunchUrl\(');
    final List<String> hits = <String>[];
    for (final File f in _dartFiles()) {
      if (handlesResult.contains(_name(f))) continue;
      final String src = _code(f);
      for (final RegExpMatch m in raw.allMatches(src)) {
        hits.add('${_name(f)}:${_line(src, m.start)}');
      }
    }
    expect(hits, isEmpty,
        reason: 'launchUrl without feedback:\n${hits.join('\n')}');
  });

  testWidgets('a link that cannot be opened says so', (WidgetTester t) async {
    // The system refuses to open the link (no browser, blocked pop-up): the
    // person must still be told.
    final TestDefaultBinaryMessenger messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall call) async => false,
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      ),
    );
    bool? result;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async {
                result = await openLinkWithFeedback(
                  context,
                  Uri.parse('https://example.org/'),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(result, isFalse);
    expect(find.text(kLinkNotOpenedMessage), findsOneWidget);
  });

  testWidgets('a missing link says so as well', (WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => openLinkWithFeedback(context, null),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text(kLinkNotOpenedMessage), findsOneWidget);
  });
}
