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

  /// Whether [text] may be remembered. Nothing about abuse, self-harm,
  /// substances, gambling, minors or safety is ever kept, even if asked.
  static bool mayRemember(String text) =>
      CrisisDetector.detect(text) == null &&
      SupportSignal.classify(text) == null &&
      !RegExp(r'\b(abus|beat|hit me|hits me|rape|molest|touch(?:es|ed) me|hurt me|suicid|kill myself|overdos|relaps|addict)', caseSensitive: false)
          .hasMatch(text);

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
