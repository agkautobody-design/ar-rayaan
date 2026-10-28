import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/scholar_review_summary.dart';

/// Settings > Sources > "What still needs review".
///
/// The areas and counts come from the register
/// (`docs/SCHOLAR_REVIEW_REGISTER.md`, generated into
/// `scholar_review_summary.dart`). Every item is open until a named reviewer
/// signs off in `kScholarSignoffs`; none has yet.
class ReviewStatusScreen extends StatelessWidget {
  const ReviewStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final int signed = kScholarSignoffs.values
        .where((ScholarSignoff s) => s.isComplete)
        .length;
    return ScenicScaffold.pattern(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const ScreenHeader(title: 'What still needs review'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Semantics(
                          header: true,
                          child: Text(
                            '$kScholarReviewTotal items are waiting for a reviewer',
                            style: AppText.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nothing in Ar-Rayaan has been reviewed by a named scholar yet, '
                          'so each of these areas is marked "$kScholarReviewNeeded". '
                          'A mark changes only when a named reviewer signs off, with '
                          'their name and the date. Sign-offs recorded so far: $signed.',
                          style: AppText.body.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$kScholarReviewHighPriority of them are rulings, hadith grades, '
                          'school positions, safety or rights questions.',
                          style: AppText.bodyMuted.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 18, bottom: 8),
                    child: _Eyebrow('BY AREA'),
                  ),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        for (final ScholarReviewArea a in kScholarReviewAreas)
                          if (a.items > 0)
                            _CountRow(
                              label: a.title,
                              count: a.items,
                              detail: '${a.highPriority} high priority',
                            ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 18, bottom: 8),
                    child: _Eyebrow('WHO IS NEEDED'),
                  ),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        for (final ScholarReviewerCount r in kScholarReviewers)
                          if (r.items > 0)
                            _CountRow(
                              label: r.reviewer,
                              count: r.items,
                              detail: 'lead reviewer',
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The full list, with where each item is in the app and why it was '
                    'flagged, is kept in the project at docs/SCHOLAR_REVIEW_REGISTER.md.',
                    style: AppText.caption,
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

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text, style: AppText.eyebrow.copyWith(fontSize: 12)),
      );
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.label,
    required this.count,
    required this.detail,
  });

  final String label;
  final int count;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        container: true,
        label: '$label: $count items, $detail',
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(label, style: AppText.body.copyWith(height: 1.35)),
              ),
              const SizedBox(width: 12),
              Text(
                '$count',
                style: AppText.body.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
