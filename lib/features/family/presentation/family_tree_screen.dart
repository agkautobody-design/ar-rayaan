import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../data/family_tree_provider.dart';

class FamilyTreeScreen extends ConsumerStatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  static const _rootId = 'adam';
  final Set<String> _expanded = {
    'adam',
    'sheeth',
    'nuh-line',
    'nuh',
    'sam',
    'arfakhshadh',
    'ibrahim-line',
    'ibrahim',
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
        error: (e, _) => Center(
          child: Text('Could not load the tree.', style: AppText.bodyMuted),
        ),
        data: (data) {
          final rows = <Widget>[];
          _buildNode(data, _rootId, 0, rows);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Family Trees', close: true),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text('IBRAHIM'S TWO RIVERS', style: AppText.eyebrow),
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
                  ],
                ),
              ),
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
    final hasKids = node.children.any((c) => data.byId.containsKey(c));
    final isOpen = _expanded.contains(id);
    final hasStory = node.story != null;

    rows.add(
      Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openNode(context, data, node),
              child: Row(
                children: [
                  if (hasKids)
                    GestureDetector(
                      onTap: () => setState(() {
                        isOpen ? _expanded.remove(id) : _expanded.add(id);
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isOpen
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 18,
                          color: AppColors.gold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 30),
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
                          node.era,
                          style: AppText.bodyMuted.copyWith(fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (node.sourceLabel == 'Established'
                                ? AppColors.gold
                                : AppColors.sand)
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      node.sourceLabel,
                      style: TextStyle(
                        fontSize: 8.5,
                        letterSpacing: 0.3,
                        color: node.sourceLabel == 'Established'
                            ? AppColors.goldLight
                            : AppColors.sand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  void _openNode(BuildContext context, FamilyTreeData data, FamilyNode node) {
    final hasKids = node.children.any((c) => data.byId.containsKey(c));
    showModalBottomSheet(
      context: context,
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
                '${node.era} · ${node.sourceLabel}',
                style: AppText.bodyMuted.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 12),
              Text(
                node.description,
                style: AppText.body.copyWith(height: 1.6, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              Text('SOURCES', style: AppText.eyebrow),
              const SizedBox(height: 4),
              for (final s in node.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child:
                      Text(s, style: AppText.bodyMuted.copyWith(fontSize: 11)),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (node.story != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.go(AppRoutes.stories);
                      },
                      icon: const Icon(Icons.auto_stories_outlined, size: 16),
                      label: const Text('Story shelf'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF0A0F18),
                      ),
                    ),
                  if (hasKids) ...[
                    if (node.story != null) const SizedBox(width: 10),
                    TextButton(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
