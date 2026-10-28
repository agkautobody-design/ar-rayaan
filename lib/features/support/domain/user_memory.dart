import 'dart:convert';

import '../../sakina/domain/crisis_detector.dart';
import '../../hadi/grounding/support_signal.dart';

/// One thing the person asked Hadi to remember.
class MemoryItem {
  const MemoryItem({required this.id, required this.text, required this.on});

  final String id;
  final String text;

  /// The day it was saved, YYYY-MM-DD.
  final String on;

  MemoryItem withText(String t) => MemoryItem(id: id, text: t, on: on);

  Map<String, String> toJson() => <String, String>{'id': id, 'text': text, 'on': on};

  static MemoryItem? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    final Object? id = j['id'];
    final Object? text = j['text'];
    final Object? on = j['on'];
    if (id is! String || text is! String || on is! String) return null;
    return MemoryItem(id: id, text: text, on: on);
  }
}

/// What "What Hadi knows about me" holds: only what the person asked to be
/// remembered, only while the switch is on, viewable, editable, deletable and
/// exportable. Never a score, never an emotion, never anything from a crisis,
/// abuse or support exchange.
abstract final class UserMemory {
  static const int maxItems = 40;
  static const int maxLength = 200;

  /// The words that ask Hadi to remember: "remember that I ...".
  static final RegExp _asks = RegExp(r'^\s*(?:please\s+)?remember(?:\s+that)?\s+(.{3,})$', caseSensitive: false);

  static String? requestedText(String message) => _asks.firstMatch(message)?.group(1)?.trim();

  /// Word starts that mark text about health, substances, safety or harm.
  /// A word is blocked when it starts with one of these ("drinking",
  /// "depressed", "medication"). Plain stems on purpose: the rule is "when in
  /// doubt, do not keep it". The Settings text promises this, so this list and
  /// that text must say the same thing.
  static const List<String> _blockedStems = <String>[
    // Alcohol, drugs, medicines, gambling, pornography, smoking
    'alcohol', 'drunk', 'drank', 'drink', 'beer', 'wine', 'vodka', 'whisk',
    'booze', 'liquor', 'hangover', 'sharab', 'khamr', 'drug', 'weed',
    'cannabis', 'marijuana', 'cocaine', 'heroin', 'methamph', 'opioid', 'xanax',
    'valium', 'benzo', 'tablet', 'medic', 'prescri', 'dose', 'dosage',
    'overdos', 'inject', 'gambl', 'casino', 'betting', 'porn', 'masturbat',
    'smok', 'vap', 'nicotine', 'cigar', 'tobacco', 'shisha', 'addict',
    'relaps', 'sober', 'crav', 'detox', 'withdraw', 'rehab',
    // Health and mind
    'health', 'depress', 'anxi', 'panic', 'therap', 'counsel', 'psychiat',
    'psycholog', 'diagnos', 'cancer', 'diabet', 'asthma', 'epilep', 'seizure',
    'pregnan', 'miscarr', 'fertil', 'surgery', 'surgical', 'hospital',
    'doctor', 'illness', 'disease', 'disorder', 'condition', 'symptom',
    'infection', 'mental', 'ptsd', 'trauma', 'bipolar', 'adhd', 'autis',
    'anorex', 'bulimi', 'eating', 'insomnia', 'disab', 'chronic', 'allerg',
    'blood pressure', 'cholesterol', 'period', 'menstru',
    // Safety and harm
    'abus', 'beat', 'violen', 'assault', 'rape', 'molest', 'harass', 'stalk',
    'threat', 'unsafe', 'scared', 'afraid', 'fear', 'suicid', 'selfharm',
    'self-harm', 'kill', 'hurt', 'cutting',
  ];

  static const Set<String> _blockedWords = <String>{
    'ill', 'sick', 'pain', 'die', 'dying', 'dead', 'hit', 'hits', 'hitting',
    'cut', 'cuts', 'hiv', 'std', 'sti', 'pms', 'ocd', 'gp', 'pill', 'pills',
    'meth', 'harm', 'harmed', 'harming',
  };

  /// Whether [text] may be remembered. Nothing about abuse, self-harm,
  /// substances, gambling, health, minors or safety is ever kept, even if
  /// asked: the crisis detector, the support-topic reader and a plain list of
  /// word starts all have to agree that it is none of those. "I drink every
  /// night" is a substance disclosure and is refused, with no cue words
  /// needed.
  static bool mayRemember(String text) {
    if (CrisisDetector.detect(text) != null) return false;
    if (SupportSignal.classify(text) != null) return false;
    final String n = CrisisDetector.normalize(text);
    if (n.isEmpty) return true;
    final List<String> tokens = n.split(' ');
    for (final String t in tokens) {
      if (_blockedWords.contains(t)) return false;
      for (final String stem in _blockedStems) {
        if (!stem.contains(' ') && t.startsWith(stem)) return false;
      }
    }
    final String padded = ' $n ';
    for (final String stem in _blockedStems) {
      if (stem.contains(' ') && padded.contains(' $stem')) return false;
    }
    return true;
  }

  static List<MemoryItem> decode(String? raw) {
    if (raw == null || raw.isEmpty) return <MemoryItem>[];
    try {
      final Object? d = json.decode(raw);
      if (d is! List<dynamic>) return <MemoryItem>[];
      return <MemoryItem>[
        for (final Object? e in d) ?MemoryItem.fromJson(e),
      ];
    } catch (_) {
      return <MemoryItem>[];
    }
  }

  static String encode(List<MemoryItem> items) =>
      json.encode(<Map<String, String>>[for (final MemoryItem i in items) i.toJson()]);

  /// A plain text copy the person can save or send themselves.
  static String export(List<MemoryItem> items) {
    if (items.isEmpty) return 'Hadi remembers nothing about you.';
    final StringBuffer b = StringBuffer('What Hadi remembers about you (saved only because you asked):\n');
    for (final MemoryItem i in items) {
      b.writeln('- ${i.text} (${i.on})');
    }
    return b.toString().trimRight();
  }
}
