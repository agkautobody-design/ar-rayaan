import 'dart:convert';

/// One piece of wording from a knowledge pack (docs/support/pack_format.md).
///
/// A snippet is data, never code: the text is the app's own plain wording,
/// reviewed (or marked "review needed") by a clinician and, for religious
/// material, a scholar. Facts live in `sources`; the text carries no citation.
class SupportSnippet {
  const SupportSnippet({
    required this.id,
    required this.pack,
    required this.kind,
    required this.text,
    this.stages = const <String>['any'],
    this.ageBands = const <String>['all'],
    this.audience = 'hadi',
    this.tone,
    this.move,
    this.variantGroup,
    this.minGapTurns,
    this.slots = const <String>[],
    this.tags = const <String>[],
    this.triggers = const <String>[],
    this.askPermission = false,
    this.neverParaphrase = false,
    this.needsScholarReview = false,
    this.needsClinicianReview = true,
    this.status = 'draft',
    this.sources = const <Map<String, dynamic>>[],
    this.crossRef = const <Map<String, dynamic>>[],
    this.risk = 'low',
    this.subtopic,
  });

  final String id;
  final String pack;
  final String kind;
  final Map<String, String> text;
  final List<String> stages;
  final List<String> ageBands;
  final String audience;
  final String? tone;
  final String? move;
  final String? variantGroup;
  final int? minGapTurns;
  final List<String> slots;
  final List<String> tags;
  final List<String> triggers;
  final bool askPermission;
  final bool neverParaphrase;
  final bool needsScholarReview;
  final bool needsClinicianReview;
  final String status;
  final List<Map<String, dynamic>> sources;
  final List<Map<String, dynamic>> crossRef;
  final String risk;
  final String? subtopic;

  bool get shippable => status == 'shippable';

  /// The text in [lang], or English when that language has none.
  String textIn(String lang) => text[lang] ?? text['en'] ?? '';

  bool hasLanguage(String lang) => text.containsKey(lang);

  /// The group whose recent use is tracked: the snippet's own group, or its
  /// pack and kind.
  String get group => variantGroup ?? '$pack.$kind';

  bool matchesAge(String band) =>
      ageBands.contains('all') || ageBands.contains(band);

  bool matchesStage(String stage) =>
      stages.contains('any') || stages.contains(stage);

  /// Fills `{slot}` placeholders from [values]. Returns null when a slot has
  /// no value: a raw `{...}` is never shown.
  String? fill(String lang, Map<String, String> values) {
    String t = textIn(lang);
    final RegExp slot = RegExp(r'\{([a-z_]+)\}');
    for (final RegExpMatch m in slot.allMatches(t).toList()) {
      final String? v = values[m.group(1)];
      if (v == null || v.isEmpty) return null;
      t = t.replaceAll('{${m.group(1)}}', v);
    }
    return t;
  }

  static SupportSnippet fromJson(
    Map<String, dynamic> j,
    String pack,
    String packAudience,
  ) {
    List<String> strings(Object? o) => <String>[
          for (final Object? e in (o as List<dynamic>? ?? const <dynamic>[]))
            e.toString(),
        ];
    List<Map<String, dynamic>> maps(Object? o) => <Map<String, dynamic>>[
          for (final Object? e in (o as List<dynamic>? ?? const <dynamic>[]))
            if (e is Map<String, dynamic>) e,
        ];
    final Map<String, dynamic> t =
        (j['text'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return SupportSnippet(
      id: j['id'] as String,
      pack: pack,
      kind: j['kind'] as String,
      text: <String, String>{
        for (final MapEntry<String, dynamic> e in t.entries)
          e.key: e.value.toString(),
      },
      stages: strings(j['stage']).isEmpty ? const <String>['any'] : strings(j['stage']),
      ageBands: strings(j['ageBand']).isEmpty ? const <String>['all'] : strings(j['ageBand']),
      audience: (j['audience'] as String?) ?? packAudience,
      tone: j['tone'] as String?,
      move: j['move'] as String?,
      variantGroup: j['variantGroup'] as String?,
      minGapTurns: j['minGapTurns'] as int?,
      slots: strings(j['slots']),
      tags: strings(j['tags']).map((String s) => s.toLowerCase()).toList(),
      triggers: strings(j['triggers']).map((String s) => s.toLowerCase()).toList(),
      askPermission: j['askPermission'] == true,
      neverParaphrase: j['neverParaphrase'] == true,
      needsScholarReview: j['needsScholarReview'] == true,
      needsClinicianReview: j['needsClinicianReview'] != false,
      status: (j['status'] as String?) ?? 'draft',
      sources: maps(j['sources']),
      crossRef: maps(j['crossRef']),
      risk: (j['risk'] as String?) ?? 'low',
      subtopic: j['subtopic'] as String?,
    );
  }
}

/// A whole pack file.
class SupportPack {
  const SupportPack({
    required this.name,
    required this.kind,
    required this.audience,
    required this.version,
    required this.reviewBy,
    required this.snippets,
    this.topic,
    this.defaultMinGapTurns = 6,
  });

  final String name;

  /// `support`, `conversation` or `knowledge`.
  final String kind;
  final String audience;
  final String version;
  final DateTime? reviewBy;
  final String? topic;
  final int defaultMinGapTurns;
  final List<SupportSnippet> snippets;

  bool expiredAt(DateTime now) => reviewBy != null && now.isAfter(reviewBy!);

  /// Parses one pack file. Returns null for a file that is not a pack this
  /// app understands (wrong schema, no name). Never throws.
  static SupportPack? parse(String raw) {
    try {
      final Object? doc = json.decode(raw);
      if (doc is! Map<String, dynamic> || doc['schema'] != 1) return null;
      final String? name = doc['pack'] as String?;
      final String? kind = doc['packKind'] as String?;
      if (name == null || kind == null) return null;
      final String audience = (doc['audience'] as String?) ?? 'hadi';
      final Map<String, dynamic>? rot = doc['rotation'] as Map<String, dynamic>?;
      final List<SupportSnippet> sn = <SupportSnippet>[];
      for (final Object? e in (doc['snippets'] as List<dynamic>? ?? <dynamic>[])) {
        if (e is! Map<String, dynamic>) continue;
        try {
          sn.add(SupportSnippet.fromJson(e, name, audience));
        } catch (_) {
          // One bad snippet never takes the pack down.
        }
      }
      return SupportPack(
        name: name,
        kind: kind,
        audience: audience,
        version: (doc['version'] as String?) ?? '0',
        reviewBy: DateTime.tryParse((doc['reviewBy'] as String?) ?? ''),
        topic: doc['topic'] as String?,
        defaultMinGapTurns: (rot?['defaultMinGapTurns'] as int?) ?? 6,
        snippets: sn,
      );
    } catch (_) {
      return null;
    }
  }
}
