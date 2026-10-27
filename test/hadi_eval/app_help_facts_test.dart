import 'dart:io';

import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hadi's app-help answers name real labels on real screens. This reads the
/// screen sources and fails when an answer points at a label that no longer
/// exists, so the help cannot drift away from the app.
String src(String path) => File(path).readAsStringSync();

Future<String> ask(String q) => const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

void main() {
  test('streaks answer names the switch and section that exist', () async {
    final a = await ask('How do streaks work?');
    expect(a, contains('Keep my streaks'));
    expect(src('lib/features/settings/presentation/settings_screen.dart'), contains("'Keep my streaks'"));
    expect(src('lib/features/settings/presentation/settings_screen.dart'), contains("'COMING BACK'"));
    expect(src('lib/features/streaks/presentation/streaks_screen.dart'), contains("'Keep my streaks'"));
    expect(a.toLowerCase(), isNot(contains('leaderboard rank')));
  });

  test('downloads answer names the Wi-Fi only switch', () async {
    final a = await ask('How do I download recitations?');
    expect(a, contains('Wi-Fi only'));
    expect(src('lib/features/downloads/presentation/downloads_screen.dart'), contains("'Wi-Fi only'"));
  });

  test('school-of-law answer names the Hadi menu item', () async {
    final a = await ask('How do I change my madhhab setting?');
    expect(a, contains('Your school of law'));
    expect(src('lib/features/hadi/presentation/hadi_screen.dart'), contains("'Your school of law'"));
  });

  test('language answer matches the Language & Voice screen', () async {
    final a = await ask('How do I change the app language?');
    expect(a, contains('Language & Voice'));
    final screen = src('lib/features/settings/presentation/language_settings.dart');
    expect(screen, contains('native speaker'));
    expect(screen, contains('not translated yet'));
    expect(a.toLowerCase(), contains('english only'));
  });
}
