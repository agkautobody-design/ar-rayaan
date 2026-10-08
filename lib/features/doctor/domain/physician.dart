/// The Physician - Doctor Tier 2: LLM-assisted diagnosis.
///
/// Pipeline: HealthReport -> redacted diagnostic BUNDLE -> free-AI
/// ladder (Groq first; Workers AI when its token ships) -> strict
/// JSON -> allowlist PARSER -> Diagnosis with one-tap PlanActions.
/// The AI proposes; the parser and the founder dispose. Anything the
/// parser doesn't recognize is dropped, logged, and never executed.
library;

/// One proposed repair step. [id] MUST be in [kAllowedActionIds] -
/// the parser enforces this; anything else never becomes an object.
class PlanAction {
  const PlanAction({
    required this.id,
    required this.reason,
    this.args = const <String, String>{},
  });

  final String id;
  final String reason;
  final Map<String, String> args;

  Map<String, String> get displayArgs =>
      args.map((String k, String v) => MapEntry<String, String>(k, v));
}

/// The Physician's verdict.
class Diagnosis {
  const Diagnosis({
    required this.hypothesis,
    required this.confidence,
    required this.actions,
    required this.rawModel,
  });

  final String hypothesis;
  final int confidence;
  final List<PlanAction> actions;
  final String rawModel;

  bool get isActionable => actions.isNotEmpty;
}

/// The only actions the Physician may ever propose. Executors live in
/// the console/command layer - the Physician never executes.
const List<String> kAllowedActionIds = <String>[
  'clear_cache',
  'toggle_flag',
  'reload_pack',
  'trim_storage',
  'reset_module_state',
];

/// The secrets-free package sent to the AI ladder. Built by
/// [PhysicianEngine.bundleFor]; the redaction test proves nothing
/// sensitive can ride along.
class DiagnosticBundle {
  const DiagnosticBundle({
    required this.probeResults,
    required this.heartbeat,
    required this.flagStates,
    required this.appVersion,
  });

  final List<Map<String, String>> probeResults;
  final List<String> heartbeat;
  final Map<String, bool> flagStates;
  final String appVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'probes': probeResults,
        'heartbeat': heartbeat,
        'flags': flagStates,
        'appVersion': appVersion,
      };
}

abstract final class PhysicianPrompt {
  static const String system = 'You are the diagnostic assistant inside '
      'the Islamic app Ar-Rayaan. You receive a redacted diagnostic '
      'bundle of probe results. Respond with ONLY a JSON object (no '
      'markdown fences) matching exactly: '
      '{"hypothesis": "<root cause, 1-2 sentences, plain words>", '
      '"confidence": <integer 0-100>, '
      '"actions": [{"id": "<one of: clear_cache, toggle_flag, '
      'reload_pack, trim_storage, reset_module_state>", '
      '"reason": "<one sentence>", "args": {"<key>": "<value>"}}]}. '
      'Rules: never invent action ids; if unsure, return an empty '
      'actions array and lower confidence. The founder approves every '
      'action - you only propose.';
}
