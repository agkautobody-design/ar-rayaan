import 'package:ar_rayaan/features/doctor/application/physician_engine.dart';
import 'package:ar_rayaan/features/doctor/domain/physician.dart';
import 'package:ar_rayaan/features/doctor/domain/vitals.dart';
import 'package:flutter_test/flutter_test.dart';

HealthReport fakeReport() => HealthReport(
      runAt: DateTime(2026, 10, 5),
      results: <ProbeResult>[
        const ProbeResult(
            probeId: 'deck.integrity',
            feature: 'academy',
            status: ProbeStatus.failed,
            detail: '2 corrupt card(s) in stored deck'),
      ],
    );

void main() {
  group('bundleFor redaction', () {
    test('no key-shaped, email, phone, or secret-word content survives', () {
      final report = HealthReport(
        runAt: DateTime.now(),
        results: <ProbeResult>[
          const ProbeResult(
            probeId: 'x',
            feature: 'y',
            status: ProbeStatus.failed,
            detail: 'call sk-abcdef1234567890 or mail founder@rhwtech.com '
                'or dial 16475024369 token=abc123 api_key=zz bearer qqq',
          ),
        ],
      );
      final bundle = PhysicianEngine.bundleFor(
        report,
        heartbeat: <String>['hadi key gsk_live_1234567890abcdef'],
        flagStates: <String, bool>{'academy': true},
        appVersion: '1.0 founder@rhwtech.com',
      );
      final String all = bundle.toJson().toString();
      expect(all.contains('sk-abcdef'), isFalse);
      expect(all.contains('gsk_live'), isFalse);
      expect(all.contains('founder@rhwtech.com'), isFalse);
      expect(all.contains('16475024369'), isFalse);
      expect(all.contains('api_key=zz'), isFalse);
      expect(bundle.flagStates['academy'], isTrue);
      expect(bundle.probeResults.single['status'], 'failed');
    });
  });

  group('parseResponse security boundary', () {
    test('well-formed response with allowlisted action parses', () {
      final d = PhysicianEngine.parseResponse(
        '{"hypothesis":"Deck store corrupted by an interrupted write.","confidence":72,'
        '"actions":[{"id":"clear_cache","reason":"Clear stale transient state first.",'
        '"args":{"scope":"academy"}}]}',
      );
      expect(d.hypothesis, contains('Deck store'));
      expect(d.confidence, 72);
      expect(d.actions.single.id, 'clear_cache');
      expect(d.actions.single.args['scope'], 'academy');
    });

    test('unknown action ids are dropped, known ones kept', () {
      final d = PhysicianEngine.parseResponse(
        '{"hypothesis":"x","confidence":50,"actions":['
        '{"id":"delete_database","reason":"evil"},'
        '{"id":"toggle_flag","reason":"ok","args":{"key":"ar.flag.academy"}}]}',
      );
      expect(d.actions.length, 1);
      expect(d.actions.single.id, 'toggle_flag');
    });

    test('malformed JSON yields a zero-confidence, action-free diagnosis', () {
      final d = PhysicianEngine.parseResponse('not json at all');
      expect(d.confidence, 0);
      expect(d.isActionable, isFalse);
    });

    test('non-list actions and wrong types are tolerated safely', () {
      final d = PhysicianEngine.parseResponse(
          '{"hypothesis":123,"confidence":"high","actions":"clear_cache"}');
      expect(d.confidence, 0);
      expect(d.actions, isEmpty);
    });
  });

  group('diagnose ladder', () {
    test('first successful rung wins; later rungs untouched', () async {
      var secondCalled = false;
      final d = await PhysicianEngine.diagnose(
        PhysicianEngine.bundleFor(fakeReport(),
            heartbeat: <String>[],
            flagStates: <String, bool>{},
            appVersion: 't'),
        ladder: <LadderRung>[
          (s, u) async =>
              '{"hypothesis":"from rung one","confidence":80,"actions":[]}',
          (s, u) async {
            secondCalled = true;
            return null;
          },
        ],
      );
      expect(d!.hypothesis, 'from rung one');
      expect(secondCalled, isFalse);
    });

    test('failing rung fails over to the next', () async {
      final d = await PhysicianEngine.diagnose(
        PhysicianEngine.bundleFor(fakeReport(),
            heartbeat: <String>[],
            flagStates: <String, bool>{},
            appVersion: 't'),
        ladder: <LadderRung>[
          (s, u) async => null,
          (s, u) async => '{"hypothesis":"backup","confidence":40,"actions":[]}',
        ],
      );
      expect(d!.hypothesis, 'backup');
    });

    test('all rungs down returns null (console shows offline guidance)', () async {
      final d = await PhysicianEngine.diagnose(
        PhysicianEngine.bundleFor(fakeReport(),
            heartbeat: <String>[],
            flagStates: <String, bool>{},
            appVersion: 't'),
        ladder: <LadderRung>[(s, u) async => null, (s, u) async => throw StateError('x')],
      );
      expect(d, isNull);
    });
  });

  group('allowlist contract', () {
    test('kAllowedActionIds excludes destructive verbs by construction', () {
      for (final id in kAllowedActionIds) {
        expect(id.contains('delete'), isFalse);
        expect(id.contains('drop'), isFalse);
        expect(id.contains('wipe'), isFalse);
      }
      expect(kAllowedActionIds.length, 5);
    });
  });
}
