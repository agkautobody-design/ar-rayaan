import 'package:ar_rayaan/features/doctor/application/founder_auth.dart';
import 'package:ar_rayaan/features/doctor/application/founder_commands.dart';
import 'package:ar_rayaan/features/doctor/application/vitals_registry.dart';
import 'package:ar_rayaan/features/doctor/domain/vitals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DoctorVitals', () {
    setUp(() => VitalsRegistry.resetForTests());

    test('runs registered probes and aggregates a report', () async {
      VitalsRegistry.register(RegisteredProbe(
        id: 'ok', feature: 'test', run: () async =>
            const ProbeResult(probeId: 'ok', feature: 'test', status: ProbeStatus.pass),
      ));
      VitalsRegistry.register(RegisteredProbe(
        id: 'bad', feature: 'test',
        run: () async => const ProbeResult(
            probeId: 'bad', feature: 'test', status: ProbeStatus.failed,
            detail: 'broken'),
      ));
      final report = await DoctorVitals.runAll();
      expect(report.results.length, 2);
      expect(report.healthy, isFalse);
      expect(report.totalFailures, 1);
    });

    test('failed probe with repair is repaired once and re-probed', () async {
      var broken = true;
      VitalsRegistry.register(RegisteredProbe(
        id: 'fixable', feature: 'test',
        run: () async => ProbeResult(
          probeId: 'fixable', feature: 'test',
          status: broken ? ProbeStatus.failed : ProbeStatus.pass,
        ),
        repair: () async {
          broken = false;
          return 'repaired it';
        },
      ));
      final report = await DoctorVitals.runAll();
      expect(report.repaired, 1);
      expect(report.results.single.status, ProbeStatus.repaired);
      expect(report.results.single.repairDescription, 'repaired it');
    });

    test('repair that does not hold reports failed, no loop', () async {
      VitalsRegistry.register(RegisteredProbe(
        id: 'stubborn', feature: 'test',
        run: () async => const ProbeResult(
            probeId: 'stubborn', feature: 'test', status: ProbeStatus.failed),
        repair: () async => 'tried',
      ));
      final report = await DoctorVitals.runAll();
      expect(report.repaired, 0);
      expect(report.results.single.status, ProbeStatus.failed);
    });

    test('throwing probe is reported, never crashes the run', () async {
      VitalsRegistry.register(RegisteredProbe(
        id: 'boom', feature: 'test',
        run: () async => throw StateError('exploded'),
      ));
      final report = await DoctorVitals.runAll();
      expect(report.totalFailures, 1);
      expect(report.results.single.detail, contains('exploded'));
    });

    test('duplicate registrations are ignored', () {
      VitalsRegistry.register(RegisteredProbe(
          id: 'dup', feature: 't', run: () async => const ProbeResult(
              probeId: 'dup', feature: 't', status: ProbeStatus.pass)));
      VitalsRegistry.register(RegisteredProbe(
          id: 'dup', feature: 't', run: () async => const ProbeResult(
              probeId: 'dup', feature: 't', status: ProbeStatus.pass)));
      expect(VitalsRegistry.probes.length, 1);
    });
  });

  group('GoldenRunner', () {
    test('returns failed case names only', () {
      final failed = GoldenRunner.run(<GoldenCase>[
        const GoldenCase(name: 'a', check: _pass),
        const GoldenCase(name: 'b', check: _fail),
      ]);
      expect(failed, <String>['b']);
    });
  });

  group('FounderAuth', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test('not configured until setup; PIN verifies after', () async {
      expect(FounderAuth.isConfigured(prefs), isFalse);
      await FounderAuth.configure(
        prefs: prefs, pin: '1234',
        question1: 'Q1?', answer1: 'A1',
        question2: 'Q2?', answer2: 'A2',
      );
      expect(FounderAuth.isConfigured(prefs), isTrue);
      expect(FounderAuth.verify(prefs, '1234'), isTrue);
      expect(FounderAuth.verify(prefs, '9999'), isFalse);
    });

    test('PIN is never stored in plaintext', () {
      FounderAuth.configure(
        prefs: prefs, pin: '4321',
        question1: 'q', answer1: 'a', question2: 'q2', answer2: 'a2',
      );
      final raw = prefs.getKeys()
          .map((k) => '${prefs.get(k)}')
          .join('|');
      expect(raw.contains('4321'), isFalse);
    });

    test('weak PIN rejected', () {
      expect(
        () => FounderAuth.configure(
            prefs: prefs, pin: '12',
            question1: 'q', answer1: 'a', question2: 'q', answer2: 'a'),
        throwsArgumentError,
      );
    });

    test('recovery requires both answers (case-insensitive)', () async {
      await FounderAuth.configure(
        prefs: prefs, pin: '1234',
        question1: 'Q1?', answer1: 'Answer One',
        question2: 'Q2?', answer2: 'Answer Two',
      );
      expect(
        FounderAuth.verifyRecovery(prefs,
            answer1: 'answer one', answer2: 'answer two'),
        isTrue,
      );
      expect(
        FounderAuth.verifyRecovery(prefs,
            answer1: 'answer one', answer2: 'wrong'),
        isFalse,
      );
    });

    test('recovery questions are retrievable for the prompt', () async {
      await FounderAuth.configure(
        prefs: prefs, pin: '1234',
        question1: 'First masjid?', answer1: 'x',
        question2: 'Mother?', answer2: 'y',
      );
      expect(FounderAuth.recoveryQuestion1(prefs), 'First masjid?');
      expect(FounderAuth.recoveryQuestion2(prefs), 'Mother?');
    });
  });

  group('FounderCommandParser', () {
    test('health check variants map to run_vitals', () {
      for (final s in <String>['run health check', 'health', 'run vitals']) {
        expect(FounderCommandParser.parse(s).action, 'run_vitals');
      }
    });

    test('toggle academy maps to the flag with pre-approved reply', () {
      final c = FounderCommandParser.parse('toggle academy');
      expect(c.action, 'toggle_flag');
      expect(c.args['flag'], 'ar.flag.academy');
    });

    test('unknown flag and unknown commands are refused with guidance', () {
      expect(FounderCommandParser.parse('toggle everything').action, 'unknown');
      expect(FounderCommandParser.parse('delete all data').action, 'unknown');
      expect(FounderCommandParser.parse('help').action, 'help');
    });
  });
}

bool _pass() => true;
bool _fail() => false;
