import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_finder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round 8: the questions testers asked about the app itself that Hadi
/// answered with "I don't have a checked answer".
void main() {
  test('a streak question points at the Streaks screen', () {
    final String? a = HadiFinder.pointerReply('What is a streak in this app?');
    expect(a, isNotNull);
    expect(a, contains('[GO:/streaks]'));
  });

  test('an offline or download question points at Downloads', () {
    for (final String q in <String>[
      'Where do I download the Qur’an for offline reading?',
      'how can I read the quran offline',
      'download surah yasin',
    ]) {
      final String? a = HadiFinder.pointerReply(q);
      expect(a, isNotNull, reason: q);
      expect(a, contains('[GO:/downloads]'), reason: q);
    }
  });

  test('a ruling about downloading is not a pointer', () {
    for (final String q in <String>[
      'is it haram to download music',
      'why is hadi offline',
    ]) {
      final String? a = HadiFinder.pointerReply(q);
      expect(a == null || !a.contains('[GO:/downloads]'), isTrue, reason: q);
    }
  });

  test('both screens are whitelisted for Hadi buttons', () {
    expect(HadiTokens.isAllowed('/streaks'), isTrue);
    expect(HadiTokens.isAllowed('/downloads'), isTrue);
    expect(kHadiRouteNames['/streaks'], isNotNull);
    expect(kHadiRouteNames['/downloads'], isNotNull);
  });
}
