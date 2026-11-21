import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The After Prayer screen reads the bundled `after-prayer` set; this guards
/// that the set carries the remembrance the screen is meant to show.
void main() {
  test('after-prayer set holds the sourced remembrance, in order', () {
    final Map<String, dynamic> data = jsonDecode(
      File('assets/adhkar/adhkar.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final Map<String, dynamic> set = (data['sets'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((Map<String, dynamic> s) => s['id'] == 'after-prayer');
    final List<Map<String, dynamic>> items =
        (set['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(items.length, 9);
    expect(items.last['source'], contains('Abi Dawud 1522'));
    for (final Map<String, dynamic> i in items) {
      expect((i['source'] as String).trim(), isNotEmpty, reason: '${i['n']}');
      expect((i['ar'] as String).trim(), isNotEmpty, reason: '${i['n']}');
    }
  });
}
