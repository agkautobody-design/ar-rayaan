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

  /// How we know the link to the parent(s): the basis of the lineage itself,
  /// which can be weaker than the person (a prophet named in the Qur'an may
  /// have a parent known only from tradition).
  final String? lineageNote;

  /// 'placed' (default) or 'unplaced': a person the sources name but do not
  /// place in this line. Unplaced people have no parents or children here;
  /// they are listed in their own section instead of being guessed into a
  /// family.
  final String placement;

  /// Non-lineage links ("guardian of Maryam", "cousin of Isa"), each with the
  /// id it points at and the plain label to print.
  final List<FamilyRelation> relations;

  bool get isUnplaced => placement == 'unplaced';

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
    this.lineageNote,
    this.placement = 'placed',
    this.relations = const <FamilyRelation>[],
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
        lineageNote: j['lineageNote'] as String?,
        placement: (j['placement'] as String?) ?? 'placed',
        relations: (j['relations'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) =>
                FamilyRelation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A link that is not parent/child/spouse: guardian, cousin, uncle...
class FamilyRelation {
  final String id;
  final String label;
  const FamilyRelation({required this.id, required this.label});

  factory FamilyRelation.fromJson(Map<String, dynamic> j) => FamilyRelation(
        id: j['id'] as String,
        label: j['label'] as String,
      );
}

class FamilyTreeData {
  final String title;
  final String note;
  final List<String> sources;
  final List<FamilyNode> nodes;
  final Map<String, FamilyNode> byId;

  /// Printed above the tree when present: where the lineage is uncertain.
  final String? lineageWarning;

  /// Printed above the section of people the sources do not place.
  final String? unplacedNote;

  FamilyTreeData({
    required this.title,
    required this.note,
    required this.sources,
    required this.nodes,
    this.lineageWarning,
    this.unplacedNote,
  }) : byId = {for (final n in nodes) n.id: n};
}

final familyTreeProvider = FutureProvider<FamilyTreeData>((ref) async {
  final raw = await ContentSync.load('family/tree.json');
  final j = json.decode(raw) as Map<String, dynamic>;
  return FamilyTreeData(
    title: j['meta']['title'] as String,
    note: j['meta']['note'] as String,
    sources: (j['meta']['sources'] as List<dynamic>).cast<String>(),
    lineageWarning: j['meta']['lineageWarning'] as String?,
    unplacedNote: j['meta']['unplacedNote'] as String?,
    nodes: (j['nodes'] as List<dynamic>)
        .map((e) => FamilyNode.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});
