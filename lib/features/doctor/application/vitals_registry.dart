/// Vitals registry + the Doctor's run loop.
library;

import 'package:flutter/foundation.dart';

import '../domain/vitals.dart';


abstract final class VitalsRegistry {
  static final List<RegisteredProbe> _probes = <RegisteredProbe>[];

  static List<RegisteredProbe> get probes => List<RegisteredProbe>.unmodifiable(_probes);

  /// Features call this at boot. Late registrations are fine — the
  /// next run picks them up.
  static void register(RegisteredProbe probe) {
    if (_probes.any((RegisteredProbe p) => p.id == probe.id)) return;
    _probes.add(probe);
  }

  static void resetForTests() => _probes.clear();
}

abstract final class DoctorVitals {
  /// Run every probe. Failed probes with a registered repair are
  /// repaired ONCE, then re-probed (max one repair cycle per run —
  /// a repair that doesn't hold fails loudly instead of looping).
  static Future<HealthReport> runAll() async {
    final List<ProbeResult> results = <ProbeResult>[];
    for (final RegisteredProbe p in VitalsRegistry.probes) {
      try {
        final ProbeResult raw = await p.run();
        // The registered severity always wins — a critical probe that
        // PASSES is still a critical probe (and vice versa).
        ProbeResult r = ProbeResult(
          probeId: raw.probeId,
          feature: raw.feature,
          status: raw.status,
          severity: p.severity,
          detail: raw.detail,
          repairDescription: raw.repairDescription,
        );
        if (!r.isHealthy && p.repair != null) {
          final String desc = await p.repair!();
          final ProbeResult after = await p.run();
          r = ProbeResult(
            probeId: p.id,
            feature: p.feature,
            status: after.isHealthy ? ProbeStatus.repaired : ProbeStatus.failed,
            severity: p.severity,
            detail: after.detail.isEmpty ? r.detail : after.detail,
            repairDescription: desc,
          );
        }
        results.add(r);
      } catch (e) {
        results.add(ProbeResult(
          probeId: p.id,
          feature: p.feature,
          status: ProbeStatus.failed,
          severity: p.severity,
          detail: 'probe threw: $e',
        ));
      }
    }
    return HealthReport(runAt: DateTime.now(), results: results);
  }
}

/// Heartbeat log — the audit trail. Ring buffer, on-device only.
class HeartbeatEntry {
  const HeartbeatEntry({
    required this.at,
    required this.summary,
    required this.failures,
    required this.repaired,
  });

  final DateTime at;
  final String summary;
  final int failures;
  final int repaired;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'at': at.toIso8601String(),
        'summary': summary,
        'failures': failures,
        'repaired': repaired,
      };

  factory HeartbeatEntry.fromJson(Map<String, dynamic> j) => HeartbeatEntry(
        at: DateTime.parse(j['at'] as String),
        summary: j['summary'] as String,
        failures: j['failures'] as int? ?? 0,
        repaired: j['repaired'] as int? ?? 0,
      );
}

class HeartbeatLog extends ChangeNotifier {
  HeartbeatLog({this.capacity = 50});

  final int capacity;
  final List<HeartbeatEntry> _entries = <HeartbeatEntry>[];

  List<HeartbeatEntry> get entries => List<HeartbeatEntry>.unmodifiable(_entries);

  void record(HealthReport report) {
    _entries.insert(
      0,
      HeartbeatEntry(
        at: report.runAt,
        summary: report.healthy
            ? 'All ${report.results.length} probes healthy'
            : '${report.totalFailures} of ${report.results.length} probes failing',
        failures: report.totalFailures,
        repaired: report.repaired,
      ),
    );
    if (_entries.length > capacity) _entries.removeLast();
    notifyListeners();
  }
}
