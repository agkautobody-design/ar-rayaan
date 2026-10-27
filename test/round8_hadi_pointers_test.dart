import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_finder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round 8: the questions testers asked about the app itself that Hadi
/// answered with "I don't have a checked answer".
void main() {
  test('a streak question points at My log and never uses the word', () {
    final String? a = HadiFinder.pointerReply('What is a streak in this app?');
    expect(a, isNotNull);
    expect(a, contains('[GO:/my-log]'));
    expect(a!.toLowerCase(), isNot(contains('streak')));
  });

  test('an offline or download question points at Downloads', () {
    for (final String q in <String>[
      'Where do I download the Qur’an for offline reading?',
      'how can I read the quran offline',
      'download surah yasin',
      "Where do I download the Qur'an for offline reading in this app?",
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

  test('"download for offline in this app" is not a why-is-Hadi-offline question',
      () {
    expect(
      HadiFinder.asksWhyOffline(
          "Where do I download the Qur'an for offline reading in this app?"),
      isFalse,
    );
    expect(HadiFinder.asksWhyOffline('why is hadi offline'), isTrue);
  });

  test('both screens are whitelisted for Hadi buttons', () {
    expect(HadiTokens.isAllowed('/my-log'), isTrue);
    expect(HadiTokens.isAllowed('/downloads'), isTrue);
    expect(kHadiRouteNames['/my-log'], isNotNull);
    expect(kHadiRouteNames['/downloads'], isNotNull);
  });
}
