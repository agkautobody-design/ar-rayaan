/// The Physician engine: bundle builder, free-AI ladder, strict parser.
///
/// The ladder is provider-abstracted ([AiLadderRung]) so Groq today
/// and Workers AI tomorrow are swappable - and tests inject a fake.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/physician.dart';
import '../domain/vitals.dart';

/// One rung of the free-AI ladder. Return null to fail over.
typedef LadderRung = Future<String?> Function(String system, String user);

abstract final class PhysicianEngine {
  /// Groq free tier (rung 1): same key contract as Hadi.
  static const String _groqKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static List<LadderRung> get defaultLadder => <LadderRung>[
        if (_groqKey.isNotEmpty) _groqRung,
        // Workers AI rung slots in here when the founder's token ships.
      ];

  static Future<String?> _groqRung(String system, String user) async {
    final http.Response res = await http.post(
      Uri.parse(_groqUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $_groqKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'model': 'llama-3.1-8b-instant',
        'response_format': <String, String>{'type': 'json_object'},
        'messages': <Map<String, String>>[
          <String, String>{'role': 'system', 'content': system},
          <String, String>{'role': 'user', 'content': user},
        ],
      }),
    );
    if (res.statusCode != 200) return null;
    final Map<String, dynamic> decoded =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List<dynamic> choices = decoded['choices'] as List<dynamic>;
    if (choices.isEmpty) return null;
    final Map<String, dynamic> msg =
        choices.first['message'] as Map<String, dynamic>;
    return msg['content'] as String?;
  }

  /// Build the redacted bundle from a report + on-device context.
  /// REDACTION CONTRACT: probe details may contain arbitrary strings,
  /// so every field is pattern-scrubbed before it leaves the device.
  static DiagnosticBundle bundleFor(
    HealthReport report, {
    required List<String> heartbeat,
    required Map<String, bool> flagStates,
    required String appVersion,
  }) {
    return DiagnosticBundle(
      probeResults: <Map<String, String>>[
        for (final ProbeResult r in report.results)
          <String, String>{
            'probe': _scrub(r.probeId),
            'feature': _scrub(r.feature),
            'status': r.status.name,
            'detail': _scrub(r.detail),
          },
      ],
      heartbeat: heartbeat.map(_scrub).toList(),
      flagStates: flagStates,
      appVersion: _scrub(appVersion),
    );
  }

  /// Conservative scrubber: strips anything that looks like a key,
  /// token, email, or phone. Belt-and-suspenders on top of the
  /// architectural rule (secrets never enter the bundle's inputs).
  static String _scrub(String raw) {
    String s = raw;
    s = s.replaceAll(RegExp(r'sk-[A-Za-z0-9_-]{8,}'), '[redacted]');
    s = s.replaceAll(RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+'), '[redacted]');
    s = s.replaceAll(RegExp(r'\b\d{10,}\b'), '[redacted]');
    s = s.replaceAll(
        RegExp(r'\b(api[_-]?key|key|token|secret|bearer)\b[ :=]*\S{0,60}',
            caseSensitive: false),
        '[redacted]');
    return s;
  }

  /// Diagnose: bundle -> ladder (failover across rungs) -> parse.
  /// Returns null when every rung failed (console shows "offline").
  static Future<Diagnosis?> diagnose(
    DiagnosticBundle bundle, {
    List<LadderRung>? ladder,
  }) async {
    final String user = jsonEncode(bundle.toJson());
    final List<LadderRung> rungs = ladder ?? defaultLadder;
    String? raw;
    for (final LadderRung rung in rungs) {
      try {
        raw = await rung(PhysicianPrompt.system, user);
      } catch (_) {
        raw = null;
      }
      if (raw != null && raw.isNotEmpty) break;
    }
    if (raw == null || raw.isEmpty) return null;
    return parseResponse(raw);
  }

  /// The security boundary: only allowlisted action ids survive.
  /// Malformed JSON, wrong types, unknown ids - all dropped. What the
  /// model intended can never become what the app does.
  static Diagnosis parseResponse(String raw) {
    Map<String, dynamic> doc;
    try {
      doc = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return Diagnosis(
        hypothesis: 'The assistant returned an unreadable response.',
        confidence: 0,
        actions: const <PlanAction>[],
        rawModel: raw,
      );
    }
    final Object? rawHypothesis = doc['hypothesis'];
    final String hypothesis = rawHypothesis is String
        ? rawHypothesis.trim()
        : 'No hypothesis returned.';
    final Object? rawConfidence = doc['confidence'];
    final int confidence =
        rawConfidence is num ? rawConfidence.clamp(0, 100).toInt() : 0;
    final List<PlanAction> actions = <PlanAction>[];
    final Object? rawActions = doc['actions'];
    if (rawActions is List) {
      for (final Object? a in rawActions) {
        if (a is! Map) continue;
        final String? id = a['id'] as String?;
        if (id == null || !kAllowedActionIds.contains(id)) continue;
        final Map<String, String> args = <String, String>{};
        final Object? rawArgs = a['args'];
        if (rawArgs is Map) {
          rawArgs.forEach((Object? k, Object? v) {
            if (k != null && v != null) args[k.toString()] = v.toString();
          });
        }
        actions.add(PlanAction(
          id: id,
          reason: (a['reason'] as String?)?.trim() ?? 'No reason given.',
          args: args,
        ));
      }
    }
    return Diagnosis(
      hypothesis: hypothesis,
      confidence: confidence,
      actions: actions,
      rawModel: raw,
    );
  }
}
