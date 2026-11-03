import 'package:flutter/material.dart' hide Text;

import '../../../app/core/scholar_review.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../reading/presentation/quran_snippet_views.dart';
import '../../support/presentation/privacy_shield.dart';
import '../domain/marriage_tools.dart';
import 'widgets/need_help_button.dart';

/// Between Two Hearts — the two-way marriage room of Sakina.
///
/// Five small practices a couple can walk together, or one spouse alone on
/// a hard day, then the safety card that names harm plainly and points to
/// help. Everything here works in both directions; the footer says so out
/// loud, because a tool only one spouse may use is not a tool — it is a
/// leash.
class MarriageScreen extends StatelessWidget {
  const MarriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<MarriageTool> tools = MarriageTools.all;
    final MarriageTool safety =
        tools.firstWhere((MarriageTool t) => t.id == 'when-not-safe');
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const ScreenHeader(title: 'Between Two Hearts 💞', close: true),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: QuickExitButton(),
            ),
            const ScholarReviewNote(
              reviewKey: 'sakina',
              padding: EdgeInsets.only(bottom: 8),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Marriage was meant to be a place of stillness. '
                          'Allah placed between the two of you “affection and '
                          'mercy” (Qur’an 30:21) — and when the stillness '
                          'thins, the way back is walked by two, not carried '
                          'by one.',
                          style: AppText.body.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'EVERY TOOL BELOW WORKS IN BOTH DIRECTIONS',
                          style: AppText.eyebrow.copyWith(
                            fontSize: 12,
                            color: AppColors.gold.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'THE DU’A OF REPAIR',
                          style: AppText.eyebrow.copyWith(
                            fontSize: 12,
                            color: AppColors.gold.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const QuranTranslitBlock(
                          arabic: MarriageTools.repairDuaArabic,
                          english: MarriageTools.repairDuaBody,
                          ayahKey: '25:74',
                          centered: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          MarriageTools.repairDuaSource,
                          style: AppText.caption.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final MarriageTool tool in tools)
                    if (tool.id != 'when-not-safe') _ToolCard(tool: tool),
                  _SafetyCard(tool: safety),
                  const SizedBox(height: 12),
                  const NeedHelpNowButton(),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('marriage-support-pathway'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () =>
                        context.open('${AppRoutes.support}/domestic-abuse'),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Open the safety pages'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TWO-WAY, ALWAYS · A TOOL ONLY ONE SPOUSE MAY USE IS '
                    'NOT A TOOL — IT IS A LEASH',
                    style: AppText.eyebrow.copyWith(
                      fontSize: 12,
                      color: AppColors.gold.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the four working tools, folded under a gold-chevron tile so the
/// room stays calm on first open.
class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});

  final MarriageTool tool;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: Key('marriage-tool-${tool.id}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            iconColor: AppColors.gold,
            collapsedIconColor: AppColors.gold.withValues(alpha: 0.5),
            title: Text(
              '${tool.emoji}  ${tool.title}',
              style: AppText.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              tool.subtitle,
              style: AppText.caption.copyWith(fontSize: 12),
            ),
            children: <Widget>[
              for (int i = 0; i < tool.steps.length; i++)
                _StepBlock(number: i + 1, step: tool.steps[i]),
            ],
          ),
        ),
      ),
    );
  }
}

/// The safety card is never folded away: someone who needs it must not
/// have to find it first.
class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.tool});

  final MarriageTool tool;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${tool.emoji}  ${tool.title}',
            style: AppText.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tool.subtitle,
            style: AppText.caption.copyWith(fontSize: 12),
          ),
          for (int i = 0; i < tool.steps.length; i++)
            _StepBlock(number: i + 1, step: tool.steps[i]),
        ],
      ),
    );
  }
}

/// One numbered step: gold-ringed number, heading, gentle body, source.
class _StepBlock extends StatelessWidget {
  const _StepBlock({required this.number, required this.step});

  final int number;
  final MarriageStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: AppText.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  step.heading,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.body,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.sand.withValues(alpha: 0.9),
                  ),
                ),
                if (step.source != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    step.source!,
                    style: AppText.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.gold.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
