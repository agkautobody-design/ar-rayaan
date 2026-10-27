import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_core.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression battery for Hadi: the 192 audited turns plus the beginner,
/// family, money, app-help and out-of-scope questions added with the accuracy
/// fix. hadi_battery.json records, for every turn, which built-in core answer
/// handles it ("" when the question goes to the shelf) and whether Hadi must
/// decline (true), must answer (false) or either is fine (null: safety and
/// personal-ruling replies that the controller produces).
///
/// A change that turns a good answer into a refusal, or moves a question to a
/// different answer, fails here. When an answer is improved on purpose,
/// regenerate the fixture and read the diff.
void main() {
  final raw = json.decode(File('test/hadi_eval/hadi_battery.json').readAsStringSync()) as List<dynamic>;

  test('the battery is not empty', () {
    expect(raw.length, greaterThan(250));
  });

  for (int i = 0; i < raw.length; i++) {
    final item = raw[i] as Map<String, dynamic>;
    final turns = (item['turns'] as List<dynamic>).cast<String>();
    final expects = (item['expect'] as List<dynamic>).cast<Map<String, dynamic>>();
    test('battery $i: ${turns.join(' > ')}', () async {
      final history = <HadiMessage>[];
      for (int t = 0; t < turns.length; t++) {
        final q = turns[t];
        final want = expects[t];
        final core = HadiCore.match(q)?.id ?? '';
        expect(core, want['core'], reason: 'core answer for "$q"');
        final reply = await const OfflineHadiProvider().ask(q, List<HadiMessage>.of(history));
        expect(reply.trim(), isNotEmpty, reason: 'empty reply for "$q"');
        final refusal = want['refusal'];
        if (refusal is bool) {
          // The controller adds the route lead-in to a decline; mirror it.
          var shown = reply;
          if (OfflineHadiProvider.refusalRoutes(q, shown).isNotEmpty) {
            shown = '$shown\n\n${HadiRouting.refusalLeadIn}';
          }
          expect(HadiRouting.isRefusal(shown), refusal, reason: 'refusal state of "$q": $reply');
        }
        history
          ..add(HadiMessage(fromHadi: false, text: q))
          ..add(HadiMessage(fromHadi: true, text: reply));
      }
    });
  }
}
