import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/core/content/content_sync.dart';

class FamilyNode {
  final String id;
  final String name;
  final String era;
  final List<String> parents;
  final List<String> spouses;
  final List<String> children;
  final String river;
  final String sourceLabel;
  final String description;
  final List<String> sources;
  final String? story;

  const FamilyNode({
    required this.id,
    required this.name,
    required this.era,
    required this.parents,
    required this.spouses,
    required this.children,
    required this.river,
    required this.sourceLabel,
    required this.description,
    required this.sources,
    this.story,
  });

  factory FamilyNode.fromJson(Map<String, dynamic> j) => FamilyNode(
        id: j['id'] as String,
        name: j['name'] as String,
        era: j['era'] as String,
        parents: (j['parents'] as List<dynamic>? ?? const []).cast<String>(),
        spouses: (j['spouses'] as List<dynamic>? ?? const []).cast<String>(),
        children: (j['children'] as List<dynamic>? ?? const []).cast<String>(),
        river: j['river'] as String,
        sourceLabel: j['sourceLabel'] as String,
        description: j['description'] as String,
        sources: (j['sources'] as List<dynamic>).cast<String>(),
        story: j['story'] as String?,
      );
}

class FamilyTreeData {
  final String title;
  final String note;
  final List<String> sources;
  final List<FamilyNode> nodes;
  final Map<String, FamilyNode> byId;

  FamilyTreeData({
    required this.title,
    required this.note,
    required this.sources,
    required this.nodes,
  }) : byId = {for (final n in nodes) n.id: n};
}

final familyTreeProvider = FutureProvider<FamilyTreeData>((ref) async {
  final raw = await ContentSync.load('family/tree.json');
  final j = json.decode(raw) as Map<String, dynamic>;
  return FamilyTreeData(
    title: j['meta']['title'] as String,
    note: j['meta']['note'] as String,
    sources: (j['meta']['sources'] as List<dynamic>).cast<String>(),
    nodes: (j['nodes'] as List<dynamic>)
        .map((e) => FamilyNode.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});
