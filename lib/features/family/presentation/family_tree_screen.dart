import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../stories/data/stories_repository.dart';
import '../../stories/domain/story.dart';
import '../data/family_tree_provider.dart';
import '../../../app/theme/widgets/focus_ring.dart';

class FamilyTreeScreen extends ConsumerStatefulWidget {
  const FamilyTreeScreen({super.key, this.initiallyExpanded = const <String>{}});

  /// Extra branches to open on first build (used by tests and deep links).
  final Set<String> initiallyExpanded;

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  static const _rootId = 'adam';
  late final Set<String> _expanded = <String>{
    'adam',
    'sheeth',
    'nuh-line',
    'nuh',
    'sam',
    'arfakhshadh',
    'ibrahim-line',
    'ibrahim',
    ...widget.initiallyExpanded,
  };

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(familyTreeProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: tree.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        // Never a bare line with no way out: the header's Close, the reason
        // (needs the internet unless the pack is saved), and Try again.
        error: (e, _) => SafeArea(
          child: Column(
            key: const Key('family-tree-error'),
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: ScreenHeader(title: 'Family Trees', close: true),
              ),
              Expanded(
                child: NeedsInternetView(
                  what: 'The family trees',
                  hint: 'To have them ready without a connection, save '
                      '\u201cFamily tree, feelings, games and Q&A\u201d in '
                      'Settings > Downloads while you are online.',
                  onRetry: () => ref.invalidate(familyTreeProvider),
                ),
              ),
            ],
          ),
        ),
        data: (data) {
          final rows = <Widget>[];
          _buildNode(data, _rootId, 0, rows);
          // Safety net: any node the walk (children + spouse links) cannot
          // reach is listed here instead of silently vanishing.
          final Set<String> reachable = reachableFrom(data, _rootId);
          final List<FamilyNode> orphans = <FamilyNode>[
            for (final FamilyNode n in data.nodes)
              if (!reachable.contains(n.id) && !n.isUnplaced) n,
          ];
          final List<FamilyNode> unplaced = <FamilyNode>[
            for (final FamilyNode n in data.nodes)
              if (n.isUnplaced) n,
          ];
          if (orphans.isNotEmpty) {
            rows.add(Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text('ALSO IN THIS TREE', style: AppText.eyebrow),
            ));
            for (final FamilyNode n in orphans) {
              _buildNode(data, n.id, 0, rows);
            }
          }
          if (unplaced.isNotEmpty) {
            rows.add(Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
              child: Text(
                'PROPHETS THE SOURCES DO NOT PLACE IN THIS LINE',
                style: AppText.eyebrow,
              ),
            ));
            if (data.unplacedNote != null) {
              rows.add(Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text(
                  data.unplacedNote!,
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ));
            }
            for (final FamilyNode n in unplaced) {
              _buildNode(data, n.id, 0, rows);
            }
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Family Trees', close: true),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text('IBRAHIM\u2019S TWO RIVERS', style: AppText.eyebrow),
              ),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: AppText.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      data.note,
                      style: AppText.bodyMuted.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'HOW TO READ THIS TREE',
                      style: AppText.eyebrow,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Each row is a parent \u2014 tap the arrow to walk into their children. '
                      'Adam and his sons open first; follow Sheeth\u2019s line down to Nuh, then '
                      'Ibrahim, where the two rivers split: one to the Prophet \u0635\u0644\u0649 \u0627\u0644\u0644\u0647 \u0639\u0644\u064a\u0647 \u0648\u0633\u0644\u0645, one to Musa, Dawud and Isa. '
                      'Folded rows are generations the tradition names with less certainty \u2014 honest gaps, not decoration.',
                      style: AppText.bodyMuted.copyWith(height: 1.55),
                    ),
                  ],
                ),
              ),
              if (data.lineageWarning != null) ...<Widget>[
                const SizedBox(height: 10),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('WHERE THE LINEAGE IS UNCERTAIN', style: AppText.eyebrow),
                      const SizedBox(height: 4),
                      Text(
                        data.lineageWarning!,
                        style: AppText.bodyMuted.copyWith(height: 1.55),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ...rows,
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOURCES', style: AppText.eyebrow),
                    const SizedBox(height: 6),
                    for (final s in data.sources)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(s, style: AppText.bodyMuted),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _buildNode(FamilyTreeData data, String id, int depth, List<Widget> rows) {
    final node = data.byId[id];
    if (node == null) return;
    final List<FamilyNode> spouses = <FamilyNode>[
      for (final String s in node.spouses)
        if (data.byId[s] != null) data.byId[s]!,
    ];
    final hasKids = node.children.any((c) => data.byId.containsKey(c));
    final isOpen = _expanded.contains(id);
    final hasStory = node.story != null;

    rows.add(
      Padding(
        // Indent stops growing at depth 6 so deep branches (Maryam sits
        // fourteen levels down) never run out of width on a phone.
        padding: EdgeInsets.only(left: (depth > 6 ? 6 : depth) * 16.0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.gold.withValues(
                  alpha: depth == 0 ? 0.0 : 0.22,
                ),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(left: depth == 0 ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openNode(context, data, node),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  // On a narrow row (deep branch on a phone) the label chip
                  // drops under the name instead of squeezing it to nothing.
                  final bool narrow = box.maxWidth < 240;
                  final Widget labelChip = Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _labelColor(node.sourceLabel)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      node.sourceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.3,
                        color: _labelColor(node.sourceLabel),
                      ),
                    ),
                  );
                  return Row(
                children: [
                  if (hasKids)
                    Semantics(
                      button: true,
                      expanded: isOpen,
                      label: '${isOpen ? 'Hide' : 'Show'} the children of ${node.name}',
                      excludeSemantics: true,
                      onTap: () => setState(() {
                        isOpen ? _expanded.remove(id) : _expanded.add(id);
                      }),
                      child: FocusableTap(
                      onTap: () => setState(() {
                        isOpen ? _expanded.remove(id) : _expanded.add(id);
                      }),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          isOpen
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 20,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                node.name,
                                style: AppText.body.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: hasStory
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: hasStory
                                      ? AppColors.goldLight
                                      : AppColors.sand,
                                ),
                              ),
                            ),
                            if (hasStory) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.auto_stories_outlined,
                                size: 12,
                                color: AppColors.gold.withValues(alpha: 0.8),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          node.era +
                              (hasKids
                                  ? ' \u00b7 ${_childCount(node.children.where((c) => data.byId.containsKey(c)).length)}'
                                  : ''),
                          style: AppText.bodyMuted.copyWith(fontSize: 12),
                        ),
                        if (narrow)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: labelChip,
                          ),
                      ],
                    ),
                  ),
                  if (!narrow) labelChip,
                ],
              );
                },
              ),
            ),
          ),
          if (spouses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  for (final FamilyNode sp in spouses)
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openNode(context, data, sp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Spouse \u00b7 ${sp.name}',
                          style: AppText.bodyMuted.copyWith(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );

    if (isOpen) {
      for (final childId in node.children) {
        if (data.byId.containsKey(childId)) {
          _buildNode(data, childId, depth + 1, rows);
        }
      }
    }
  }

  /// Opens the real story for [node] in the reader; falls back to the shelf.
  Future<void> _openStory(BuildContext context, FamilyNode node) async {
    final String? id = node.story;
    Story? found;
    if (id != null) {
      try {
        final List<Story> all = await ref.read(storiesProvider.future);
        for (final Story st in all) {
          if (st.id == id) {
            found = st;
            break;
          }
        }
      } catch (_) {
        found = null;
      }
    }
    if (!context.mounted) return;
    if (found != null) {
      context.open(AppRoutes.storyReader, extra: found);
    } else {
      context.open(AppRoutes.stories);
    }
  }

  void _openNode(BuildContext context, FamilyTreeData data, FamilyNode node) {
    final hasKids = node.children.any((c) => data.byId.containsKey(c));
    final List<FamilyRelation> relations = <FamilyRelation>[
      for (final FamilyRelation r in node.relations)
        if (data.byId.containsKey(r.id)) r,
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0F18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(node.name, style: AppText.titleMedium),
              const SizedBox(height: 2),
              Text(
                '${node.era} \u00b7 ${node.sourceLabel}',
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                node.description,
                style: AppText.body.copyWith(height: 1.6, fontSize: 13.5),
              ),
              if (node.lineageNote != null) ...<Widget>[
                const SizedBox(height: 12),
                Text('HOW WE KNOW THIS LINK', style: AppText.eyebrow),
                const SizedBox(height: 4),
                Text(
                  node.lineageNote!,
                  style: AppText.bodyMuted.copyWith(height: 1.55, fontSize: 13),
                ),
              ],
              if (relations.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text('ALSO RELATED', style: AppText.eyebrow),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final FamilyRelation r in relations)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          final FamilyNode? other = data.byId[r.id];
                          if (other == null) return;
                          Navigator.of(ctx).pop();
                          _openNode(context, data, other);
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${r.label} \u00b7 ${data.byId[r.id]!.name}',
                              style: AppText.bodyMuted.copyWith(fontSize: 12.5),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text('SOURCES', style: AppText.eyebrow),
              const SizedBox(height: 4),
              for (final s in node.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child:
                      Text(s, style: AppText.bodyMuted.copyWith(fontSize: 12)),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (node.story != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openStory(context, node);
                      },
                      icon: const Icon(Icons.auto_stories_outlined, size: 16),
                      label: const Text('Read the story'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF0A0F18),
                      ),
                    ),
                  if (hasKids)
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _expanded.contains(node.id)
                              ? _expanded.remove(node.id)
                              : _expanded.add(node.id);
                        });
                      },
                      child: Text(
                        _expanded.contains(node.id)
                            ? 'Collapse branch'
                            : 'Expand branch',
                        style: const TextStyle(color: AppColors.goldLight),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colour of a node's label chip: Established (gold), Interpretive (sand),
/// Disputed in the sources (amber).
Color _labelColor(String label) {
  switch (label) {
    case 'Established':
      return AppColors.goldLight;
    case 'Disputed in the sources':
      return const Color(0xFFE6A96B);
    default:
      return AppColors.sand;
  }
}

/// Every node reachable from [rootId] by walking children AND spouse
/// links (the tree draws spouses as chips on their partner's row).
Set<String> reachableFrom(FamilyTreeData data, String rootId) {
  final Set<String> seen = <String>{};
  final List<String> stack = <String>[rootId];
  while (stack.isNotEmpty) {
    final String id = stack.removeLast();
    if (!seen.add(id)) continue;
    final FamilyNode? n = data.byId[id];
    if (n == null) continue;
    stack
      ..addAll(n.children)
      ..addAll(n.spouses);
  }
  return seen;
}

/// "1 child" / "2 children".
String _childCount(int n) => n == 1 ? '1 child' : '$n children';
