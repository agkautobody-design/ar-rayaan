import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_miss_service.dart';

void main() {
  test('off by default: nothing is queued', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences p = await SharedPreferences.getInstance();
    final HadiMissService s = HadiMissService(p);
    expect(s.enabled, isFalse);
    await s.record('what is the best pizza near the masjid');
    expect(s.queued, isEmpty);
  });

  test('when on and offline, a question waits in the queue once', () async {
    SharedPreferences.setMockInitialValues(
        <String, Object>{HadiMissService.enabledPref: true});
    final SharedPreferences p = await SharedPreferences.getInstance();
    final HadiMissService s = HadiMissService(p);
    await s.record('what is the best pizza near the masjid');
    await s.record('what is the best pizza near the masjid');
    expect(s.queued.length, 1);
  });

  test('private, long, link and number text is never kept', () {
    expect(HadiMissService.clean('I want to kill myself'), isNull);
    expect(HadiMissService.clean('see https://example.com now please'), isNull);
    expect(HadiMissService.clean('call me on 416 555 0123 please'), isNull);
    expect(HadiMissService.clean('hi'), isNull);
    expect(HadiMissService.clean('what is the night of baraat'), isNotNull);
  });

  test('firestore.rules: create-only, no user id, founders read', () {
    final String rules = File('firestore.rules').readAsStringSync();
    final int at = rules.indexOf('match /hadi_misses/');
    expect(at, greaterThan(0));
    final String block = rules.substring(at, rules.indexOf('// ── Community map', at));
    expect(block, contains('allow read: if isFounder()'));
    expect(block, contains('allow update, delete: if false'));
    expect(block, contains('hasOnly'));
    expect(block, contains('request.time'));
    expect(block, contains("id.matches('^[0-9a-f]{24}_' + request.auth.uid + '\$')"));
  });
}
