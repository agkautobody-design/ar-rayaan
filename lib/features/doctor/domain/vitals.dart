/// The Doctor — Tier 1: VITALS domain.
///
/// Every feature registers probes with the [VitalsRegistry]; a probe is
/// a real behavioral check (not "does the file exist") that returns a
/// [ProbeResult]. The Doctor runs the registry, auto-repairs what the
/// probes mark repairable, snapshots first, and writes every run to
/// the heartbeat log. Design: Detect → Adapt (Tier 1); Analyze →
/// Validate (Tier 2); Learn (Learning Module).
library;

enum ProbeSeverity { info, warning, critical }

enum ProbeStatus { pass, repaired, failed }

class ProbeResult {
  const ProbeResult({
    required this.probeId,
    required this.feature,
    required this.status,
    this.severity = ProbeSeverity.warning,
    this.detail = '',
    this.repairDescription = '',
  });

  final String probeId;
  final String feature;
  final ProbeStatus status;
  final ProbeSeverity severity;
  final String detail;

  /// Empty unless [status] is repaired.
  final String repairDescription;

  bool get isHealthy => status != ProbeStatus.failed;
}

/// A check plus its (optional) self-repair. Repairs must be idempotent
/// and safe; the Doctor snapshots user data before running any.
typedef Probe = Future<ProbeResult> Function();

typedef Repair = Future<String> Function();

class RegisteredProbe {
  const RegisteredProbe({
    required this.id,
    required this.feature,
    required this.run,
    this.repair,
    this.severity = ProbeSeverity.warning,
  });

  final String id;
  final String feature;
  final Probe run;

  /// If present and the probe fails, the Doctor attempts it BEFORE
  /// re-running the probe. Its return is the repair description.
  final Repair? repair;
  final ProbeSeverity severity;
}

class HealthReport {
  const HealthReport({required this.runAt, required this.results});

  final DateTime runAt;
  final List<ProbeResult> results;

  int get criticalFailures =>
      results.where((ProbeResult r) => !r.isHealthy && r.severity == ProbeSeverity.critical).length;
  int get totalFailures => results.where((ProbeResult r) => !r.isHealthy).length;
  int get repaired =>
      results.where((ProbeResult r) => r.status == ProbeStatus.repaired).length;

  bool get healthy => totalFailures == 0;
}

/// Golden-input runner: re-runs a feature's known-good cases on the
/// device against real data — the runtime version of the unit suite.
class GoldenCase {
  const GoldenCase({required this.name, required this.check});

  final String name;
  final bool Function() check;
}

abstract final class GoldenRunner {
  /// Returns failed case names; empty = golden.
  static List<String> run(List<GoldenCase> cases) => <String>[
        for (final GoldenCase c in cases)
          if (!c.check()) c.name,
      ];
}
